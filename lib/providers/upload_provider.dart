import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/log.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/file_source.dart';
import '../core/registry.dart';

final _log = Log('UploadNotifier');

class UploadState {
  final List<UploadResult> results;
  final double progress;
  final bool isUploading;
  final CancelToken? cancelToken;
  final String? lastError;
  final int selectedProviderIndex;

  const UploadState({
    this.results = const [],
    this.progress = 0.0,
    this.isUploading = false,
    this.cancelToken,
    this.lastError,
    this.selectedProviderIndex = 0,
  });
}

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() => const UploadState();

  void setProvider(int index) {
    if (index < 0 || index >= ProviderRegistry.all.length) return;
    state = UploadState(
      results: state.results,
      selectedProviderIndex: index,
    );
  }

  Future<void> pickAndUpload() async {
    if (state.isUploading) return;

    if (ProviderRegistry.all.isEmpty) {
      state = UploadState(
        results: state.results,
        lastError: 'No upload providers configured',
        selectedProviderIndex: state.selectedProviderIndex,
      );
      return;
    }

    final provider = ProviderRegistry.all[state.selectedProviderIndex];
    _log.info('Using provider: ${provider.providerName} (${provider.providerId})');

    final pickResult = await FilePicker.platform.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;

    final FileUploadRequest request;
    try {
      request = await createUploadRequest(file);
      _log.info('File: ${file.name}, size: ${request.sizeInBytes}, mime: ${request.mimeType}');
    } catch (e) {
      _log.warn('Failed to read file: $e', error: e);
      state = UploadState(
        results: state.results,
        lastError: 'Failed to read selected file',
        selectedProviderIndex: state.selectedProviderIndex,
      );
      return;
    }

    final cancelToken = CancelToken();
    state = UploadState(
      isUploading: true,
      progress: 0.0,
      cancelToken: cancelToken,
      selectedProviderIndex: state.selectedProviderIndex,
    );

    try {
      final result = await provider.upload(
        request,
        onProgress: (sent, total) {
          state = UploadState(
            results: state.results,
            progress: sent / total,
            isUploading: state.isUploading,
            cancelToken: state.cancelToken,
            selectedProviderIndex: state.selectedProviderIndex,
          );
        },
        cancelToken: cancelToken,
      );

      _log.info('Result: success=${result.success}, url=${result.url}, error=${result.errorMessage}');

      state = UploadState(
        isUploading: false,
        results: [result, ...state.results],
        lastError: result.success ? null : result.errorMessage,
        selectedProviderIndex: state.selectedProviderIndex,
      );
    } catch (e) {
      _log.warn('Upload exception: $e', error: e);
      state = UploadState(
        isUploading: false,
        results: state.results,
        lastError: 'Upload failed: $e',
        selectedProviderIndex: state.selectedProviderIndex,
      );
    }
  }

  void cancelUpload() {
    state.cancelToken?.cancel('User cancelled');
    state = UploadState(
      isUploading: false,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
    );
  }
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  UploadNotifier.new,
);
