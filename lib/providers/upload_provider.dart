import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../core/config_provider.dart';
import '../core/format.dart';
import '../core/history_service.dart';
import '../core/interfaces/uploader.dart';
import '../core/mime_types.dart';
import '../core/models/upload_record.dart';
import '../core/logging/log.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/file_source.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';
import 'matterbridge_config.dart';
import 'matterbridge_provider.dart';
import 'telegram_config.dart';
import 'telegram_provider.dart';
import 'zulip_config.dart';
import 'zulip_provider.dart';

final _log = Log('UploadNotifier');

sealed class UploadState {
  final List<UploadResult> results;
  final int selectedProviderIndex;
  final List<BaseUploader> providers;
  final String? selectedExpiry;

  const UploadState({
    this.results = const [],
    this.selectedProviderIndex = 0,
    this.providers = const [],
    this.selectedExpiry,
  });
}

final class UploadIdle extends UploadState {
  const UploadIdle({
    super.results,
    super.selectedProviderIndex,
    super.providers,
    super.selectedExpiry,
  });
}

final class UploadFileLoading extends UploadState {
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;

  const UploadFileLoading({
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    super.results,
    super.selectedProviderIndex,
    super.providers,
    super.selectedExpiry,
  });
}

final class UploadFileSelected extends UploadState {
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final String messageText;

  const UploadFileSelected({
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    this.fileBytes,
    this.messageText = '',
    super.results,
    super.selectedProviderIndex,
    super.providers,
    super.selectedExpiry,
  });
}

final class UploadInProgress extends UploadState {
  final double progress;
  final CancelToken cancelToken;
  final int sentBytes;
  final int totalBytes;
  final String speedLabel;
  final Uint8List? fileBytes;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;

  const UploadInProgress({
    required this.progress,
    required this.cancelToken,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.speedLabel = '',
    this.fileBytes,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    super.results,
    super.selectedProviderIndex,
    super.providers,
    super.selectedExpiry,
  });
}

final class UploadCompleted extends UploadState {
  final UploadResult lastResult;
  final String? errorMessage;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final String messageText;

  bool get isSuccess => lastResult.success;

  const UploadCompleted({
    required this.lastResult,
    this.errorMessage,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    this.fileBytes,
    this.messageText = '',
    super.results,
    super.selectedProviderIndex,
    super.providers,
    super.selectedExpiry,
  });
}

class UploadNotifier extends Notifier<UploadState> {
  final List<BaseUploader>? _injectedProviders;

  UploadNotifier({List<BaseUploader>? providers})
      : _injectedProviders = providers;

  String _selectedExpiry = '24h'; // default for configurableExpiry providers
  Uint8List? _originalFileBytes;
  String? _originalFileName;
  String? _originalMimeType;

  Uint8List? _lastFileBytes;
  DateTime _lastSpeedSample = DateTime.now();
  int _lastSampleBytes = 0;

  /// Whether the file has been edited via the image editor.
  bool get isModified =>
      _originalFileBytes != null && _originalFileBytes != _lastFileBytes;

  void setExpiry(String expiry) {
    _selectedExpiry = expiry;
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      state = UploadFileSelected(
        fileName: prev.fileName,
        fileSizeBytes: prev.fileSizeBytes,
        mimeType: prev.mimeType,
        fileBytes: prev.fileBytes,
        selectedExpiry: expiry,
        messageText: prev.messageText,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  @override
  UploadState build() {
    final List<BaseUploader> enabled =
        _injectedProviders ?? ref.watch(enabledProvidersProvider);

    // Restore last used provider after frame
    Future.microtask(() async {
      try {
        if (state is! UploadIdle) return;
        final svc = ref.read(settingsServiceProvider);
        final lastId = await svc.get(SettingsService.lastUsedProviderKey);
        if (lastId != null) {
          final idx = enabled.indexWhere((p) => p.providerId == lastId);
          if (idx >= 0 && idx != 0) {
            state = UploadIdle(providers: enabled, selectedProviderIndex: idx);
          }
        }
      } catch (_) {
        // Notifier disposed before microtask completed
      }
    });

    return UploadIdle(providers: enabled, selectedExpiry: _selectedExpiry);
  }

  void setProvider(int index) {
    if (index < 0 || index >= state.providers.length) return;
    final prev = state;
    state = switch (prev) {
      UploadFileSelected() => UploadFileSelected(
          fileName: prev.fileName,
          fileSizeBytes: prev.fileSizeBytes,
          mimeType: prev.mimeType,
          fileBytes: prev.fileBytes,
          selectedExpiry: prev.selectedExpiry,
          messageText: prev.messageText,
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadFileLoading() => UploadFileLoading(
          fileName: prev.fileName,
          fileSizeBytes: prev.fileSizeBytes,
          mimeType: prev.mimeType,
          selectedExpiry: prev.selectedExpiry,
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadIdle() => UploadIdle(
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadInProgress() => prev,
      UploadCompleted() when prev.fileName != null => UploadFileSelected(
          fileName: prev.fileName!,
          fileSizeBytes: prev.fileSizeBytes,
          mimeType: prev.mimeType,
          fileBytes: prev.fileBytes,
          selectedExpiry: prev.selectedExpiry,
          messageText: prev.messageText,
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadCompleted() => UploadIdle(
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
    };
  }

  void setMessage(String text) {
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      state = UploadFileSelected(
        fileName: prev.fileName,
        fileSizeBytes: prev.fileSizeBytes,
        mimeType: prev.mimeType,
        fileBytes: prev.fileBytes,
        selectedExpiry: prev.selectedExpiry,
        messageText: text,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  Future<void> pickAndUpload() async {
    if (state is UploadInProgress) return;

    final pickResult = await FilePicker.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;

    state = UploadFileLoading(
      fileName: file.name,
      fileSizeBytes: file.size,
      mimeType: mimeTypeFromExtension(
        file.name.contains('.') ? file.name.split('.').last : '',
      ),
      selectedExpiry: _selectedExpiry,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );

    try {
      _lastFileBytes = await file.readAsBytes();
      var request = await createUploadRequest(file);
      _log.info(
          'File: ${file.name}, size: ${request.sizeInBytes}, mime: ${request.mimeType}');

      Uint8List? previewBytes = _lastFileBytes;
      if (previewBytes == null && file.path != null) {
        previewBytes = await File(file.path!).readAsBytes();
      }

      _originalFileBytes = previewBytes;
      _originalFileName = file.name;
      _originalMimeType = request.mimeType;
      _lastFileBytes = previewBytes;
      state = UploadFileSelected(
        fileName: file.name,
        fileSizeBytes: request.sizeInBytes,
        mimeType: request.mimeType,
        fileBytes: previewBytes,
        selectedExpiry: _selectedExpiry,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    } catch (e) {
      _log.warn('Failed to read file: $e', error: e);
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'failedToReadFile',
        fileName: info.fileName,
        fileSizeBytes: info.fileSizeBytes,
        mimeType: info.mimeType,
        fileBytes: info.fileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
  }

  Future<void> uploadSelected() async {
    final currentFile =
        state is UploadFileSelected ? state as UploadFileSelected : null;
    if (currentFile == null) return;

    Uint8List? uploadBytes = currentFile.fileBytes;
    String uploadName = currentFile.fileName;
    String? uploadMime = currentFile.mimeType;

    if (uploadBytes == null) return;

    final request = FileUploadRequest(
      fileName: uploadName,
      mimeType: uploadMime,
      sizeInBytes: uploadBytes.length,
      dataStream: Stream.value(uploadBytes),
    );

    await _executeUpload(request);
  }

  Future<void> uploadFromFile(String filePath, String? mimeType) async {
    if (state is UploadInProgress) return;

    try {
      final ioFile = File(filePath);
      final size = await ioFile.length();
      final fileName = ioFile.uri.pathSegments.last;
      final detectedMime = mimeType ??
          mimeTypeFromExtension(
              fileName.contains('.') ? fileName.split('.').last : '');

      state = UploadFileLoading(
        fileName: fileName,
        fileSizeBytes: size,
        mimeType: detectedMime,
        selectedExpiry: _selectedExpiry,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );

      final previewBytes = await ioFile.readAsBytes();
      _log.info('Shared file: $filePath ($mimeType)');

      _lastFileBytes = null;
      _originalFileBytes = previewBytes;
      _originalFileName = fileName;
      _originalMimeType = detectedMime;
      _lastFileBytes = previewBytes;
      state = UploadFileSelected(
        fileName: fileName,
        fileSizeBytes: size,
        mimeType: detectedMime,
        fileBytes: previewBytes,
        selectedExpiry: _selectedExpiry,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    } catch (e) {
      _log.warn('Failed to read shared file: $e', error: e);
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'failedToReadFile',
        fileName: info.fileName,
        fileSizeBytes: info.fileSizeBytes,
        mimeType: info.mimeType,
        fileBytes: info.fileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
  }

  Future<void> uploadFromBytes(Uint8List bytes, String fileName,
      {String? mimeType}) async {
    if (state is UploadInProgress) return;
    _log.info('Pasted/clipboard file: $fileName ($mimeType)');
    _lastFileBytes = bytes;
    _originalFileBytes = bytes;
    _originalFileName = fileName;
    _originalMimeType = mimeType;
    state = UploadFileSelected(
      fileName: fileName,
      fileSizeBytes: bytes.length,
      mimeType: mimeType,
      fileBytes: bytes,
      selectedExpiry: _selectedExpiry,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );
  }

  /// Returns a progress callback that updates the [UploadInProgress] state.
  UploadProgressCallback _uploadProgressCallback(CancelToken ct) {
    return (sent, total) {
      final current = state;
      if (current is UploadInProgress) {
        final now = DateTime.now();
        final elapsed = now.difference(_lastSpeedSample).inMilliseconds;
        if (elapsed >= 500) {
          final bytesDelta = sent - _lastSampleBytes;
          final secs = elapsed / 1000.0;
          final bytesPerSec = bytesDelta / secs;
          final speed = _formatSpeed(bytesPerSec);
          _lastSpeedSample = now;
          _lastSampleBytes = sent;
          state = current.copyWithProgress(
            sent / total,
            sent,
            total,
            speed,
          );
        } else {
          state = current.copyWithProgress(
            sent / total,
            sent,
            total,
            current.speedLabel,
          );
        }
      }
    };
  }

  Future<void> _executeUpload(FileUploadRequest request) async {
    // Save last used provider
    if (state.selectedProviderIndex < state.providers.length) {
      final svc = ref.read(settingsServiceProvider);
      await svc.set(SettingsService.lastUsedProviderKey,
          state.providers[state.selectedProviderIndex].providerId);
    }

    if (state.providers.isEmpty) {
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'noProvidersConfigured',
        fileName: info.fileName ?? request.fileName,
        fileSizeBytes:
            info.fileSizeBytes > 0 ? info.fileSizeBytes : request.sizeInBytes,
        mimeType: info.mimeType ?? request.mimeType,
        fileBytes: info.fileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }

    final provider = state.providers[state.selectedProviderIndex];
    _log.info(
      'Using provider: ${provider.providerName} (${provider.providerId})',
    );

    final info = _extractFileInfo(state);
    final cancelToken = CancelToken();
    // Save message text before state transitions to UploadInProgress
    var savedMessageText = '';
    final currentState = state;
    if (currentState is UploadFileSelected) {
      savedMessageText = currentState.messageText;
    }
    state = UploadInProgress(
      progress: 0.0,
      cancelToken: cancelToken,
      sentBytes: 0,
      totalBytes: request.sizeInBytes,
      fileName: info.fileName,
      fileSizeBytes: info.fileSizeBytes,
      mimeType: info.mimeType,
      fileBytes: info.fileBytes,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );

    _lastSpeedSample = DateTime.now();
    _lastSampleBytes = 0;

    final currentFileName = info.fileName ?? request.fileName;
    final currentFileSize =
        info.fileSizeBytes > 0 ? info.fileSizeBytes : request.sizeInBytes;
    final currentMimeType = info.mimeType ?? request.mimeType;
    final currentFileBytes = info.fileBytes;

    final meta = provider.metadata;
    if (!meta.acceptsFileSize(request.sizeInBytes)) {
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'errorFileTooLarge',
        fileName: currentFileName,
        fileSizeBytes: currentFileSize,
        mimeType: currentMimeType,
        fileBytes: currentFileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }
    if (request.mimeType != null && !meta.allowsMimeType(request.mimeType!)) {
      final label = meta.mimeTypeLabel;
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage:
            '${provider.providerName} only accepts: ${label.isNotEmpty ? label : "this provider"}',
        fileName: currentFileName,
        fileSizeBytes: currentFileSize,
        mimeType: currentMimeType,
        fileBytes: currentFileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }

    try {
      final settingsService = ref.read(settingsServiceProvider);
      final hiveConfig = await settingsService.loadProviderConfig(
        provider.providerId,
        provider.requiredConfigKeys,
      );

      // Load ALL stored config from secure storage via the shared provider.
      // Secure storage takes priority over Hive, matching the original
      // per-key loop behavior (optional/optionalText keys only exist in secure storage).
      final secureConfig =
          await ref.read(providerConfigProvider(provider.providerId).future);
      final config = <String, String>{...hiveConfig, ...secureConfig};

      // Merge required keys from secure storage as fallback for keys not
      // in Hive (legacy migration path for credentials stored pre-refactor).
      for (final key in provider.requiredConfigKeys) {
        if (!config.containsKey(key) || config[key]!.isEmpty) {
          final val = secureConfig[key];
          if (val != null && val.isNotEmpty) {
            config[key] = val;
          }
        }
      }

      // Override message with user-edited text from the upload screen.
      var msg = savedMessageText;
      if (msg.isNotEmpty) {
        final info = _extractFileInfo(state);
        msg = msg
            .replaceAll('{filename}', info.fileName ?? request.fileName)
            .replaceAll('{filesize}', formatSize(request.sizeInBytes))
            .replaceAll('{provider}', provider.providerName);
        config['message_text'] = msg;
      }

      final allowInsecure = await settingsService.isInsecureConnAllowed();
      if (allowInsecure) {
        config['_allow_insecure_conn'] = 'true';
      }

      final proxyUrl = await settingsService.getProxyUrl();
      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        config['_proxy_url'] = proxyUrl;
      }

      final userAgent = await settingsService.getUserAgent();
      if (userAgent != null && userAgent.isNotEmpty) {
        config['_user_agent'] = userAgent;
      }

      // Pass user-selected expiry (providers with configurableExpiry
      // capability will pick it up via buildFormFields).
      config['_expiry'] = _selectedExpiry;

      // Handle paired provider upload (e.g. Matterbridge IRC + Catbox)
      final pairedId = config['paired_provider'];
      if (pairedId != null && pairedId.isNotEmpty) {
        final paired = ProviderRegistry.all
            .where((p) => p.providerId == pairedId)
            .firstOrNull;
        if (paired != null) {
          final pairedResult = await paired.upload(request,
              onProgress: _uploadProgressCallback(cancelToken),
              cancelToken: cancelToken,
              config: config);
          if (!pairedResult.success || pairedResult.url == null) {
            state = UploadCompleted(
              lastResult: pairedResult,
              errorMessage: pairedResult.errorMessage ?? 'uploadFailed',
              fileName: currentFileName,
              fileSizeBytes: currentFileSize,
              mimeType: currentMimeType,
              fileBytes: currentFileBytes,
              results: state.results,
              selectedProviderIndex: state.selectedProviderIndex,
              providers: state.providers,
            );
            return;
          }
          config['_pre_uploaded_url'] = pairedResult.url!;
        }
      }

      final UploadResult result;
      if (provider is MatterbridgeProvider) {
        result = await provider.upload(
          request,
          onProgress: _uploadProgressCallback(cancelToken),
          cancelToken: cancelToken,
          config: MatterbridgeConfig.fromMap(config),
        );
      } else if (provider is TelegramProvider) {
        result = await provider.upload(
          request,
          onProgress: _uploadProgressCallback(cancelToken),
          cancelToken: cancelToken,
          config: TelegramConfig.fromMap(config),
        );
      } else if (provider is ZulipProvider) {
        result = await provider.upload(
          request,
          onProgress: _uploadProgressCallback(cancelToken),
          cancelToken: cancelToken,
          config: ZulipConfig.fromMap(config),
        );
      } else {
        result = await provider.upload(
          request,
          onProgress: _uploadProgressCallback(cancelToken),
          cancelToken: cancelToken,
          config: config,
        );
      }

      // Stamp expiry on the result so the UI and history can display it.
      // Configurable-expiry providers use the user's selection; others use
      // their fixed expiryInfo from metadata (e.g. Uguu '3 hours').
      final meta = provider.metadata;
      final expiryValue =
          meta.capabilities.contains(ProviderCapability.configurableExpiry)
              ? _selectedExpiry
              : meta.expiryInfo;
      final resultWithExpiry =
          expiryValue != null ? result.copyWith(expiry: expiryValue) : result;

      _log.info(
        'Result: success=${resultWithExpiry.success}, url=${resultWithExpiry.url}, '
        'error=${resultWithExpiry.errorMessage}',
      );

      _saveToHistory(resultWithExpiry, provider, request.fileName,
          currentFileBytes, currentMimeType);
      state = UploadCompleted(
        lastResult: resultWithExpiry,
        errorMessage:
            resultWithExpiry.success ? null : resultWithExpiry.errorMessage,
        fileName: currentFileName,
        fileSizeBytes: currentFileSize,
        mimeType: currentMimeType,
        fileBytes: currentFileBytes,
        messageText: savedMessageText,
        results: [resultWithExpiry, ...state.results],
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    } catch (e) {
      if (cancelToken.isCancelled) {
        state = UploadIdle(
          results: state.results,
          selectedProviderIndex: state.selectedProviderIndex,
          providers: state.providers,
        );
        return;
      }
      _log.warn('Upload exception: $e', error: e);
      // Show actual exception type and first line of message instead of generic error
      final errorMsg = e is DioException
          ? _mapDioException(e)
          : '${e.runtimeType}: ${e.toString().split('\n').first}';
      final failResult = UploadResult(success: false, errorMessage: errorMsg);
      _saveToHistory(failResult, provider, request.fileName, currentFileBytes,
          currentMimeType);
      state = UploadCompleted(
        lastResult: failResult,
        errorMessage: errorMsg,
        fileName: currentFileName,
        fileSizeBytes: currentFileSize,
        mimeType: currentMimeType,
        fileBytes: currentFileBytes,
        messageText: savedMessageText,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
    // Free byte buffers — no longer needed after upload and history save
    _lastFileBytes = null;
    _originalFileBytes = null;
  }

  Future<void> _saveToHistory(
    UploadResult result,
    BaseUploader provider,
    String fileName,
    Uint8List? fileBytes,
    String? mimeType,
  ) async {
    try {
      final history = ref.read(historyServiceProvider);
      final thumb = _generateThumbnail(fileBytes, mimeType);
      await history.add(
        UploadRecord(
          fileName: fileName,
          url: result.url,
          providerId: provider.providerId,
          providerName: provider.providerName,
          success: result.success,
          errorMessage: result.errorMessage,
          statusCode: result.statusCode,
          completedAt: result.completedAt,
          thumbnailBytes: thumb,
          expiry: result.expiry,
        ),
      );
      ref.invalidate(uploadHistoryProvider);
    } catch (e) {
      _log.warn('Failed to save history: $e');
    }
  }

  void cancelUpload() {
    final current = state;
    if (current is UploadInProgress) {
      current.cancelToken.cancel('User cancelled');
    }
    state = UploadIdle(
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );
  }

  /// Applies an edit operation: replaces file bytes with the edited version.
  void applyEdit(Uint8List editedBytes, {String? outputMimeType}) {
    final mime = outputMimeType ?? 'image/jpeg';
    _lastFileBytes = editedBytes;
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      final ext = _extensionForMime(mime);
      final editedName =
          '${prev.fileName.replaceAll(RegExp(r'\.\w+$'), '')}.$ext';
      state = UploadFileSelected(
        fileName: editedName,
        fileSizeBytes: editedBytes.length,
        mimeType: mime,
        fileBytes: editedBytes,
        selectedExpiry: prev.selectedExpiry,
        messageText: prev.messageText,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  static String _extensionForMime(String mime) {
    return switch (mime) {
      'image/png' => 'png',
      'image/bmp' => 'bmp',
      'image/tiff' || 'image/tif' => 'tiff',
      _ => 'jpg',
    };
  }

  /// Resets the image back to the original pre-edit bytes, filename, and
  /// mime type.
  void revertEdits() {
    if (_originalFileBytes == null) return;
    _lastFileBytes = _originalFileBytes;
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      state = UploadFileSelected(
        fileName: _originalFileName ?? prev.fileName,
        fileSizeBytes: _originalFileBytes!.length,
        mimeType: _originalMimeType ?? prev.mimeType,
        fileBytes: _originalFileBytes,
        selectedExpiry: prev.selectedExpiry,
        messageText: prev.messageText,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  void clearSelection() {
    _lastFileBytes = null;
    _originalFileBytes = null;
    _originalFileName = null;
    _originalMimeType = null;
    state = UploadIdle(
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );
  }
}

extension UploadInProgressX on UploadInProgress {
  UploadInProgress copyWithProgress(
    double progress,
    int sent,
    int total,
    String speedLabel,
  ) {
    return UploadInProgress(
      progress: progress,
      cancelToken: cancelToken,
      sentBytes: sent,
      totalBytes: total,
      speedLabel: speedLabel,
      fileBytes: fileBytes,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      results: results,
      selectedProviderIndex: selectedProviderIndex,
      providers: providers,
    );
  }
}

String _formatSpeed(double bytesPerSec) {
  if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
  if (bytesPerSec < 1024 * 1024) {
    return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  }
  return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}

/// Maps DioException to an error message string.
/// If the value is a simple camelCase key, the UI resolves it via l10n.
/// If it contains runtime data (status codes, server messages), it's a
/// ready-to-display English string that passes through as-is.
String _mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.cancel => 'uploadCancelled',
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'connectionTimedOut',
    DioExceptionType.connectionError =>
      'Connection failed: ${e.message ?? "server unreachable"}',
    DioExceptionType.badResponse =>
      'Server error: ${e.response?.statusCode ?? "unknown"}',
    _ => 'Upload failed: ${e.message ?? e.type.name}',
  };
}

/// Generates a small JPEG thumbnail (max 200px wide) for image bytes.
/// Returns null for non-images or if processing fails.
Uint8List? _generateThumbnail(Uint8List? fileBytes, String? mimeType) {
  if (fileBytes == null || mimeType == null || !mimeType.startsWith('image/')) {
    return null;
  }
  try {
    final src = img.decodeImage(fileBytes);
    if (src == null) return null;
    const maxW = 200;
    final w = src.width > maxW ? maxW : src.width;
    final ratio = w / src.width;
    final h = (src.height * ratio).round();
    final thumb = img.copyResize(src, width: w, height: h);
    return img.encodeJpg(thumb, quality: 70);
  } catch (_) {
    return null;
  }
}

/// Helper to extract file info from current state for passing to UploadCompleted
({String? fileName, int fileSizeBytes, String? mimeType, Uint8List? fileBytes})
    _extractFileInfo(UploadState current) {
  if (current is UploadFileSelected) {
    return (
      fileName: current.fileName,
      fileSizeBytes: current.fileSizeBytes,
      mimeType: current.mimeType,
      fileBytes: current.fileBytes,
    );
  }
  if (current is UploadFileLoading) {
    return (
      fileName: current.fileName,
      fileSizeBytes: current.fileSizeBytes,
      mimeType: current.mimeType,
      fileBytes: null,
    );
  }
  if (current is UploadCompleted) {
    return (
      fileName: current.fileName,
      fileSizeBytes: current.fileSizeBytes,
      mimeType: current.mimeType,
      fileBytes: current.fileBytes,
    );
  }
  return (fileName: null, fileSizeBytes: 0, mimeType: null, fileBytes: null);
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  UploadNotifier.new,
);
