import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/save_file.dart';

/// Saves the file locally instead of uploading to a remote service.
class LocalProvider implements BaseUploader {
  @override
  String get providerId => 'local';
  @override
  String get providerName => 'Local (Image Editor)';
  @override
  bool get supportsWeb => false;

  @override
  bool get supportsMessage => false;
  @override
  bool get isUrlShareOnly => false;
  @override
  List<String> get requiredConfigKeys => const [];
  @override
  List<String> get optionalConfigKeys => const [];
  @override
  List<String> get optionalTextConfigKeys => const [];
  @override
  Map<String, String> get configLabels => const {};
  @override
  String? get proxyUrl => null;
  @override
  String? get instanceDescription =>
      'Saves the edited image to your device\'s local storage. No upload to a remote server.';

  @override
  ProviderMetadata get metadata => const ProviderMetadata();

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) {
    throw UnsupportedError('Local provider does not use HTTP');
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Object? config,
  }) async {
    try {
      final raw = await request.dataStream.first;
      final bytes = Uint8List.fromList(raw);

      final savedPath = await saveFileCrossPlatform(
        bytes,
        request.fileName,
        dialogTitle: 'Save image',
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        mimeType: request.mimeType,
      );

      if (savedPath == null) {
        return UploadResult(
          success: false,
          errorMessage: 'userCancelled',
        );
      }

      return UploadResult(success: true, url: '/local/$savedPath');
    } catch (e) {
      return UploadResult(
        success: false,
        errorMessage: 'saveFailed',
        rawError: e.toString(),
      );
    }
  }
}
