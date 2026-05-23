import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as img;

import '../core/history_service.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_record.dart';
import '../core/logging/log.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/file_source.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';

const _secure = FlutterSecureStorage();

String _secureKey(String providerId, String key) =>
    'provider_config_${providerId}_$key';

final _log = Log('UploadNotifier');

/// Notifier for image quality selection (0=original, 1=half, 2=quarter).
/// Separate from upload state so changing quality doesn't rebuild the screen.
final qualityNotifier = ValueNotifier<int>(0);

sealed class UploadState {
  final List<UploadResult> results;
  final int selectedProviderIndex;
  final List<BaseUploader> providers;

  const UploadState({
    this.results = const [],
    this.selectedProviderIndex = 0,
    this.providers = const [],
  });
}

final class UploadIdle extends UploadState {
  const UploadIdle({
    super.results,
    super.selectedProviderIndex,
    super.providers,
  });
}

final class UploadFileSelected extends UploadState {
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final String? selectedExpiry;

  const UploadFileSelected({
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    this.fileBytes,
    this.selectedExpiry,
    super.results,
    super.selectedProviderIndex,
    super.providers,
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
  });
}

final class UploadCompleted extends UploadState {
  final UploadResult lastResult;
  final String? errorMessage;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;

  bool get isSuccess => lastResult.success;

  const UploadCompleted({
    required this.lastResult,
    this.errorMessage,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    this.fileBytes,
    super.results,
    super.selectedProviderIndex,
    super.providers,
  });
}

class UploadNotifier extends Notifier<UploadState> {
  final List<BaseUploader>? _injectedProviders;

  UploadNotifier({List<BaseUploader>? providers})
      : _injectedProviders = providers;

  String _selectedExpiry = '24h'; // default for configurableExpiry providers
  Uint8List? _originalFileBytes; // saved for crop reset

  String? _lastFilePath;
  Uint8List? _lastFileBytes;
  DateTime _lastSpeedSample = DateTime.now();
  int _lastSampleBytes = 0;

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
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  void setQuality(int q) {
    // Quality is stored separately — it only affects upload compression,
    // not the preview. No state change, so the screen doesn't rebuild.
    qualityNotifier.value = q;
  }

  @override
  UploadState build() {
    final List<BaseUploader> enabled =
        _injectedProviders ?? ref.watch(enabledProvidersProvider);

    // Restore last used provider after frame
    Future.microtask(() async {
      if (state is! UploadIdle) return;
      final svc = ref.read(settingsServiceProvider);
      final lastId = await svc.get(SettingsService.lastUsedProviderKey);
      if (lastId != null) {
        final idx = enabled.indexWhere((p) => p.providerId == lastId);
        if (idx >= 0 && idx != 0) {
          state = UploadIdle(providers: enabled, selectedProviderIndex: idx);
        }
      }
    });

    return UploadIdle(providers: enabled);
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
          selectedExpiry: _selectedExpiry,
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

  Future<void> pickAndUpload() async {
    if (state is UploadInProgress) return;

    final pickResult = await FilePicker.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;
    _lastFilePath = file.path;
    _lastFileBytes = await file.readAsBytes();

    try {
      var request = await createUploadRequest(file);
      _log.info(
        'File: ${file.name}, size: ${request.sizeInBytes}, mime: ${request.mimeType}',
      );

      // Read preview bytes
      Uint8List? previewBytes = _lastFileBytes;
      if (previewBytes == null && file.path != null) {
        previewBytes = await File(file.path!).readAsBytes();
      }

      // Store request for later upload
      _originalFileBytes = previewBytes;
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
    // Apply quality compression at upload time (not during preview)
    final quality = qualityNotifier.value;
    bool qualityApplied = false;
    if (quality > 0 && _lastFileBytes != null) {
      final mime = state is UploadFileSelected
          ? (state as UploadFileSelected).mimeType
          : null;
      if (mime?.startsWith('image/') == true) {
        try {
          final src = img.decodeImage(_lastFileBytes!);
          if (src != null) {
            final ratio = quality == 1 ? 0.5 : 0.25;
            final newW = (src.width * ratio).round();
            final newH = (src.height * ratio).round();
            final jpegQuality = quality == 1 ? 75 : 50;
            final resized = img.copyResize(src, width: newW, height: newH);
            final outBytes = img.encodeJpg(resized, quality: jpegQuality);
            _lastFileBytes = outBytes;
            qualityApplied = true;
          }
        } catch (e) {
          _log.warn('Quality compression failed: $e', error: e);
        }
      }
    }

    FileUploadRequest? request;
    // When quality was applied, use the compressed bytes even if a file path
    // exists — otherwise the request would read the original uncompressed file.
    if (_lastFilePath != null && !qualityApplied) {
      final ioFile = File(_lastFilePath!);
      final size = await ioFile.length();
      request = FileUploadRequest(
        fileName: ioFile.uri.pathSegments.last,
        mimeType: state is UploadFileSelected
            ? (state as UploadFileSelected).mimeType
            : null,
        sizeInBytes: size,
        dataStream: ioFile.openRead(),
      );
    } else if (_lastFileBytes != null) {
      request = FileUploadRequest(
        fileName: state is UploadFileSelected
            ? (state as UploadFileSelected).fileName
            : 'file',
        mimeType: state is UploadFileSelected
            ? (state as UploadFileSelected).mimeType
            : null,
        sizeInBytes: _lastFileBytes!.length,
        dataStream: Stream.value(_lastFileBytes!),
      );
    }
    if (request == null) return;

    await _executeUpload(request);
  }

  Future<void> uploadFromFile(String filePath, String? mimeType) async {
    if (state is UploadInProgress) return;

    try {
      final ioFile = File(filePath);
      final size = await ioFile.length();
      final fileName = ioFile.uri.pathSegments.last;

      final previewBytes = await ioFile.readAsBytes();
      _log.info('Shared file: $filePath ($mimeType)');

      _lastFilePath = filePath;
      _lastFileBytes = null;
      _originalFileBytes = previewBytes;
      _lastFileBytes = previewBytes;
      state = UploadFileSelected(
        fileName: fileName,
        fileSizeBytes: size,
        mimeType: mimeType,
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
      final config = await settingsService.loadProviderConfig(
        provider.providerId,
        provider.requiredConfigKeys,
      );
      // Provider credentials moved to FlutterSecureStorage.
      // Merge them into the config so the upload has access to tokens.
      for (final key in provider.requiredConfigKeys) {
        if (!config.containsKey(key) || config[key]!.isEmpty) {
          final secure = await _secure.read(
            key: _secureKey(provider.providerId, key),
          );
          if (secure != null && secure.isNotEmpty) {
            config[key] = secure;
          }
        }
      }

      // Load optional boolean config keys (e.g. send_as_photo) from
      // secure storage and pass them through to the provider.
      for (final key in provider.optionalConfigKeys) {
        final secure = await _secure.read(
          key: _secureKey(provider.providerId, key),
        );
        if (secure != null && secure.isNotEmpty) {
          config[key] = secure;
        }
      }

      final allowInsecure = await settingsService.isInsecureConnAllowed();
      if (allowInsecure) {
        config['_allow_insecure_conn'] = 'true';
      }

      final proxyUrl = await settingsService.getProxyUrl();
      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        config['_proxy_url'] = proxyUrl;
      }

      // Pass user-selected expiry (providers with configurableExpiry
      // capability will pick it up via buildFormFields).
      config['_expiry'] = _selectedExpiry;

      final result = await provider.upload(
        request,
        onProgress: (sent, total) {
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
        },
        cancelToken: cancelToken,
        config: config,
      );

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
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
    // Free byte buffers — no longer needed after upload and history save
    _lastFileBytes = null;
    _originalFileBytes = null;
    _lastFileBytes = null;
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

  /// Applies a crop operation: replaces file bytes with the cropped version.
  /// [croppedBytes] should be JPEG-encoded bytes ready for upload/preview.
  void applyCrop(Uint8List croppedBytes) {
    _lastFileBytes = croppedBytes;
    _lastFileBytes = croppedBytes;
    _lastFilePath = null; // cropped data is no longer a file path
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      final croppedName =
          '${prev.fileName.replaceAll(RegExp(r'\.\w+$'), '')}.jpg';
      state = UploadFileSelected(
        fileName: croppedName,
        fileSizeBytes: croppedBytes.length,
        mimeType: 'image/jpeg',
        fileBytes: croppedBytes,
        selectedExpiry: prev.selectedExpiry,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  /// Resets the image back to the original pre-crop bytes.
  void resetCrop() {
    if (_originalFileBytes == null) return;
    _lastFileBytes = _originalFileBytes;
    _lastFileBytes = _originalFileBytes;
    _lastFilePath = null;
    if (state is UploadFileSelected) {
      final prev = state as UploadFileSelected;
      state = UploadFileSelected(
        fileName: prev.fileName.replaceAll('.jpg', '_original'),
        fileSizeBytes: _originalFileBytes!.length,
        mimeType: prev.mimeType,
        fileBytes: _originalFileBytes,
        selectedExpiry: prev.selectedExpiry,
        results: prev.results,
        selectedProviderIndex: prev.selectedProviderIndex,
        providers: prev.providers,
      );
    }
  }

  void clearSelection() {
    _lastFilePath = null;
    _lastFileBytes = null;
    _originalFileBytes = null;
    _lastFileBytes = null;
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
