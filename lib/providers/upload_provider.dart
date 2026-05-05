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

  UploadNotifier({
    List<BaseUploader>? providers,
  })  : _injectedProviders = providers;

  String? _lastFilePath;
  Uint8List? _lastFileBytes;
  DateTime _lastSpeedSample = DateTime.now();
  int _lastSampleBytes = 0;

  @override
  UploadState build() {
    final List<BaseUploader> enabled = _injectedProviders ?? ref.watch(enabledProvidersProvider);
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
    _lastFileBytes = file.bytes;

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
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'Failed to read selected file',
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
    FileUploadRequest? request;
    if (_lastFilePath != null) {
      final ioFile = File(_lastFilePath!);
      final size = await ioFile.length();
      request = FileUploadRequest(
        fileName: ioFile.uri.pathSegments.last,
        mimeType: state is UploadFileSelected ? (state as UploadFileSelected).mimeType : null,
        sizeInBytes: size,
        dataStream: ioFile.openRead(),
      );
    } else if (_lastFileBytes != null) {
      request = FileUploadRequest(
        fileName: state is UploadFileSelected ? (state as UploadFileSelected).fileName : 'file',
        mimeType: state is UploadFileSelected ? (state as UploadFileSelected).mimeType : null,
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
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'Failed to read selected file',
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
    if (state.providers.isEmpty) {
      final info = _extractFileInfo(state);
      state = UploadCompleted(
        lastResult: UploadResult(success: false),
        errorMessage: 'No upload providers configured',
        fileName: info.fileName ?? request.fileName,
        fileSizeBytes: info.fileSizeBytes > 0 ? info.fileSizeBytes : request.sizeInBytes,
        mimeType: info.mimeType ?? request.mimeType,
        fileBytes: info.fileBytes,
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
      return;
    }

    final provider = state.providers[state.selectedProviderIndex];
    _log.info('Using provider: ${provider.providerName} (${provider.providerId})');

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
    final currentFileSize = info.fileSizeBytes > 0 ? info.fileSizeBytes : request.sizeInBytes;
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
        errorMessage: '${provider.providerName} only accepts: ${label.isNotEmpty ? label : "this provider"}',
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

      final allowInsecure = await settingsService.isInsecureConnAllowed();
      if (allowInsecure) {
        config['_allow_insecure_conn'] = 'true';
      }

      final proxyUrl = await settingsService.getProxyUrl();
      if (proxyUrl != null && proxyUrl.isNotEmpty) {
        config['_proxy_url'] = proxyUrl;
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
        fileName: currentFileName,
        fileSizeBytes: currentFileSize,
        mimeType: currentMimeType,
        fileBytes: currentFileBytes,
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
      // Show actual exception type and first line of message instead of generic error
      final errorMsg = e is DioException ? _mapDioException(e) : '${e.runtimeType}: ${e.toString().split('\n').first}';
      final failResult = UploadResult(success: false, errorMessage: errorMsg);
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

  void clearSelection() {
    _lastFilePath = null;
    _lastFileBytes = null;
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
  if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}

/// Maps DioException to a user-friendly error message
String _mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.cancel => 'Upload cancelled',
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'Connection timed out',
    DioExceptionType.connectionError =>
      'Connection failed: ${e.message ?? "server unreachable"}',
    DioExceptionType.badResponse =>
      'Server error: ${e.response?.statusCode ?? "unknown"}',
    _ => 'Upload failed: ${e.message ?? e.type.name}',
  };
}

/// Helper to extract file info from current state for passing to UploadCompleted
({String? fileName, int fileSizeBytes, String? mimeType, Uint8List? fileBytes}) _extractFileInfo(UploadState current) {
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


