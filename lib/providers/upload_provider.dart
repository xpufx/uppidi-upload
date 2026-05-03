import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/interfaces/uploader.dart';
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

final class UploadInProgress extends UploadState {
  final double progress;
  final CancelToken cancelToken;

  const UploadInProgress({
    required this.progress,
    required this.cancelToken,
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
  final FilePicker? _injectedPicker;
  final List<BaseUploader>? _injectedProviders;

  UploadNotifier({
    FilePicker? filePicker,
    List<BaseUploader>? providers,
  })  : _injectedPicker = filePicker,
        _injectedProviders = providers;

  FilePicker get _filePicker => _injectedPicker ?? FilePicker.platform;
  List<BaseUploader> get _providers => _injectedProviders ?? ProviderRegistry.all;

  @override
  UploadState build() => UploadIdle(providers: _providers);

  void setProvider(int index) {
    if (index < 0 || index >= _providers.length) return;
    final prev = state;
    state = switch (prev) {
      UploadIdle() => UploadIdle(
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

    final pickResult = await _filePicker.pickFiles();
    if (pickResult == null || pickResult.files.isEmpty) return;

    final file = pickResult.files.first;

    try {
      final request = await createUploadRequest(file);
      _log.info('File: ${file.name}, size: ${request.sizeInBytes}, mime: ${request.mimeType}');
      await _executeUpload(request);
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

  Future<void> uploadFromFile(String filePath, String? mimeType) async {
    if (state is UploadInProgress) return;

    try {
      final ioFile = File(filePath);
      final size = await ioFile.length();
      final request = FileUploadRequest(
        fileName: ioFile.uri.pathSegments.last,
        mimeType: mimeType,
        sizeInBytes: size,
        dataStream: ioFile.openRead(),
      );
      _log.info('Shared file: $filePath ($mimeType)');
      await _executeUpload(request);
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

    final cancelToken = CancelToken();
    state = UploadInProgress(
      progress: 0.0,
      cancelToken: cancelToken,
      results: state.results,
      selectedProviderIndex: state.selectedProviderIndex,
      providers: state.providers,
    );

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
            state = current.copyWithProgress(sent / total);
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
    } catch (e) {
      _log.warn('Upload exception: $e', error: e);
      state = UploadCompleted(
        lastResult: UploadResult(success: false, errorMessage: 'Upload failed: $e'),
        errorMessage: 'Upload failed: $e',
        results: state.results,
        selectedProviderIndex: state.selectedProviderIndex,
        providers: state.providers,
      );
    }
  }

  Future<bool> _checkConnectivity(BaseUploader provider) async {
    try {
      final dio = await provider.createHttpClient({});
      dio.options.connectTimeout = const Duration(seconds: 3);
      await dio.head('/');
      return true;
    } catch (e) {
      _log.warn('Connectivity check failed: $e');
      return false;
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
  UploadInProgress copyWithProgress(double progress) {
    return UploadInProgress(
      progress: progress,
      cancelToken: cancelToken,
      results: results,
      selectedProviderIndex: selectedProviderIndex,
      providers: providers,
    );
  }
}

final uploadProvider = NotifierProvider<UploadNotifier, UploadState>(
  UploadNotifier.new,
);
