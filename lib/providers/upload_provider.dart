import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/registry.dart';

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
  UploadState build() {
    return const UploadState();
  }

  void setProvider(int index) {
    if (index >= 0 && index < ProviderRegistry.all.length) {
      state = UploadState(
        results: state.results,
        selectedProviderIndex: index,
      );
    }
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
    debugPrint('[UploadNotifier] Using provider: ${provider.providerName} (${provider.providerId})');

    final pickResult = await FilePicker.platform.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;
    if (file.path == null) return;

    final ioFile = File(file.path!);
    final fileStream = ioFile.openRead();
    final size = await ioFile.length();

    final ext = file.extension;
    final mimeType = ext != null ? _mimeTypeFromExtension(ext) : null;

    debugPrint('[UploadNotifier] File: ${file.name}, size: $size, mime: $mimeType');

    final request = FileUploadRequest(
      fileName: file.name,
      mimeType: mimeType,
      sizeInBytes: size,
      dataStream: fileStream,
    );

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

      debugPrint('[UploadNotifier] Result: success=${result.success}, url=${result.url}, error=${result.errorMessage}');

      state = UploadState(
        isUploading: false,
        results: [result, ...state.results],
        lastError: result.success ? null : result.errorMessage,
        selectedProviderIndex: state.selectedProviderIndex,
      );
    } catch (e) {
      debugPrint('[UploadNotifier] Exception: $e');
      state = UploadState(
        isUploading: false,
        results: state.results,
        lastError: 'Upload failed: $e',
        selectedProviderIndex: state.selectedProviderIndex,
      );
    }
  }

  String _mimeTypeFromExtension(String ext) {
    final cleanExt = ext.startsWith('.') ? ext.substring(1) : ext;
    return 'application/$cleanExt';
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
  () => UploadNotifier(),
);
