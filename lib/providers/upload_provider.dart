import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/history_service.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_record.dart';
import '../core/logging/log.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/file_source.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';

final _log = Log('UploadNotifier');

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
  const UploadIdle({super.results, super.selectedProviderIndex, super.providers});
}

final class UploadFileSelected extends UploadState {
  final String fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;

  const UploadFileSelected({
    required this.fileName,
    required this.fileSizeBytes,
    this.mimeType,
    this.fileBytes,
    super.results,
    super.selectedProviderIndex,
    super.providers,
  });
}

final class UploadStarting extends UploadState {
  const UploadStarting({super.results, super.selectedProviderIndex, super.providers});
}

final class UploadInProgress extends UploadState {
  final double progress;
  final CancelToken cancelToken;
  final int sentBytes;
  final int totalBytes;
  final String speedLabel;

  const UploadInProgress({
    required this.progress,
    required this.cancelToken,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.speedLabel = '',
    super.results,
    super.selectedProviderIndex,
    super.providers,
  });
}

final class UploadCompleted extends UploadState {
  final UploadResult lastResult;
  final String? errorMessage;

  bool get isSuccess => lastResult.success;

  const UploadCompleted({
    required this.lastResult,
    this.errorMessage,
    super.results,
    super.selectedProviderIndex,
    super.providers,
  });
}

class UploadNotifier extends Notifier<UploadState> {
  final List<BaseUploader>? _injectedProviders;

  UploadNotifier({
    List<BaseUploader>? providers,
  })  : _injectedProviders = providers;

  List<BaseUploader> get _providers => _injectedProviders ?? ref.read(enabledProvidersProvider);

  FileUploadRequest? _pendingRequest;
  DateTime _lastSpeedSample = DateTime.now();
  int _lastSampleBytes = 0;

  @override
  UploadState build() => UploadIdle(providers: _providers);

  void setProvider(int index) {
    if (index < 0 || index >= _providers.length) return;
    final prev = state;
    state = switch (prev) {
      UploadFileSelected() => UploadFileSelected(
          fileName: prev.fileName,
          fileSizeBytes: prev.fileSizeBytes,
          mimeType: prev.mimeType,
          fileBytes: prev.fileBytes,
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadIdle() || UploadStarting() => UploadIdle(
          results: prev.results,
          selectedProviderIndex: index,
          providers: prev.providers,
        ),
      UploadInProgress() => prev,
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

    try {
      final request = await createUploadRequest(file);
      _log.info('File: ${file.name}, size: ${request.sizeInBytes}, mime: ${request.mimeType}');

      // Read preview bytes
      Uint8List? previewBytes;
      if (file.bytes != null) {
        previewBytes = file.bytes;
      } else if (file.path != null) {
        previewBytes = await File(file.path!).readAsBytes();
      }

      // Store request for later upload
      _pendingRequest = request;

      state = UploadFileSelected(
        fileName: file.name,
        fileSizeBytes: request.sizeInBytes,
        mimeType: request.mimeType,
        fileBytes: previewBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    } catch (e) {
      _log.warn('Failed to read file: $e', error: e);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'Failed to read selected file',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
  }

  Future<void> uploadSelected() async {
    final request = _pendingRequest;
    if (request == null) return;
    _pendingRequest = null;
    await _executeUpload(request);
  }

  Future<void> uploadFromFile(String filePath, String? mimeType) async {
    if (state is UploadInProgress) return;

    try {
      final ioFile = File(filePath);
      final size = await ioFile.length();
      final fileName = ioFile.uri.pathSegments.last;

      final previewBytes = await ioFile.readAsBytes();

      final request = FileUploadRequest(
        fileName: fileName,
        mimeType: mimeType,
        sizeInBytes: size,
        dataStream: ioFile.openRead(),
      );
      _log.info('Shared file: $filePath ($mimeType)');

      _pendingRequest = request;
      state = UploadFileSelected(
        fileName: fileName,
        fileSizeBytes: size,
        mimeType: mimeType,
        fileBytes: previewBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    } catch (e) {
      _log.warn('Failed to read shared file: $e', error: e);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'Failed to read selected file',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
  }

  Future<void> _executeUpload(FileUploadRequest request) async {
    if (_providers.isEmpty) {
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'No upload providers configured',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }

    final provider = _providers[state.selectedProviderIndex];
    _log.info('Using provider: ${provider.providerName} (${provider.providerId})');

    final cancelToken = CancelToken();
    state = UploadInProgress(
      progress: 0.0,
      cancelToken: cancelToken,
      sentBytes: 0,
      totalBytes: request.sizeInBytes,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );

    _lastSpeedSample = DateTime.now();
    _lastSampleBytes = 0;

    final meta = provider.metadata;
    if (!meta.acceptsFileSize(request.sizeInBytes)) {
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'errorFileTooLarge',
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
        errorMessage: '${provider.providerName} only accepts: ${label.isNotEmpty ? label : "this provider"}',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }

    final online = await _checkConnectivity(provider);
    if (!online) {
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'errorConnectionFailed',
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

      final allowInsecure = await settingsService.isInsecureConnAllowed();
      if (allowInsecure) {
        config['_allow_insecure_conn'] = 'true';
      }

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
              state = current.copyWithProgress(sent / total, sent, total, speed);
            } else {
              state = current.copyWithProgress(sent / total, sent, total, current.speedLabel);
            }
          }
        },
        cancelToken: cancelToken,
        config: config,
      );

      _log.info('Result: success=${result.success}, url=${result.url}, error=${result.errorMessage}');

      state = UploadCompleted(
        lastResult: result,
        errorMessage: result.success ? null : result.errorMessage,
        results: [result, ...state.results],
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      _saveToHistory(result, provider, request.fileName);
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
      final failResult = UploadResult(success: false, errorMessage: 'Upload failed: $e');
      state = UploadCompleted(
        lastResult: failResult,
        errorMessage: 'Upload failed: $e',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      _saveToHistory(failResult, provider, request.fileName);
    }
  }

  Future<void> _saveToHistory(UploadResult result, BaseUploader provider, String fileName) async {
    try {
      final history = ref.read(historyServiceProvider);
      await history.add(UploadRecord(
        fileName: fileName,
        url: result.url,
        providerId: provider.providerId,
        providerName: provider.providerName,
        success: result.success,
        errorMessage: result.errorMessage,
        statusCode: result.statusCode,
        completedAt: result.completedAt,
      ));
      ref.invalidate(uploadHistoryProvider);
    } catch (e) {
      _log.warn('Failed to save history: $e');
    }
  }

  Future<bool> _checkConnectivity(BaseUploader provider) async {
    try {
      final dio = await provider.createHttpClient({});
      dio.options.connectTimeout = const Duration(seconds: 5);
      try {
        await dio.head('/');
      } catch (_) {
        // Some servers reject HEAD; try GET with small range
        await dio.get('/', options: Options(
          extra: {'noLog': true},
          responseType: ResponseType.bytes,
          headers: {'Range': 'bytes=0-0'},
        ));
      }
      return true;
    } catch (e) {
      _log.warn('Connectivity check failed: $e');
      return true; // allow upload anyway — let the actual upload fail if truly down
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

}

extension UploadInProgressX on UploadInProgress {
  UploadInProgress copyWithProgress(double progress, int sent, int total, String speedLabel) {
    return UploadInProgress(
      progress: progress,
      cancelToken: cancelToken,
      sentBytes: sent,
      totalBytes: total,
      speedLabel: speedLabel,
      results: results,
      selectedProviderIndex: selectedProviderIndex,
      providers: providers,
    );
  }
}

String _formatSpeed(double bytesPerSec) {
  if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
  if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  UploadNotifier.new,
);


