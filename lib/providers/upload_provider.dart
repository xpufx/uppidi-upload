import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/registry.dart';

class UploadState {
  final List<UploadResult> results;
  final double progress;
  final bool isUploading;
  final CancelToken? cancelToken;

  const UploadState({
    this.results = const [],
    this.progress = 0.0,
    this.isUploading = false,
    this.cancelToken,
  });
}

class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() {
    return const UploadState();
  }

  Future<void> pickAndUpload() async {
    final pickResult = await FilePicker.platform.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;
    if (file.path == null) return;

    final provider = ProviderRegistry.all.first;
    final fileStream = File(file.path!).openRead();
    final size = await File(file.path!).length();

    final request = FileUploadRequest(
      fileName: file.name,
      mimeType: file.extension != null ? 'application/${file.extension}' : null,
      sizeInBytes: size,
      dataStream: fileStream,
    );

    state = UploadState(
      isUploading: true,
      progress: 0.0,
      cancelToken: CancelToken(),
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
          );
        },
        cancelToken: state.cancelToken,
      );

      state = UploadState(
        isUploading: false,
        results: [result, ...state.results],
        cancelToken: null,
      );
    } catch (e) {
      state = UploadState(
        isUploading: false,
        cancelToken: null,
      );
    }
  }

  void cancelUpload() {
    state.cancelToken?.cancel('User cancelled');
    state = UploadState(
      isUploading: false,
      cancelToken: null,
    );
  }
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  () => UploadNotifier(),
);
