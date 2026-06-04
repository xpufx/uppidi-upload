import 'package:dio/dio.dart';

import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';

class MockBaseUploader implements BaseUploader {
  @override
  String providerId = 'mock';
  @override
  String providerName = 'Mock Provider';
  @override
  bool supportsWeb = true;
  @override
  bool supportsMessage = false;
  @override
  bool isUrlShareOnly = false;
  @override
  List<String> requiredConfigKeys = const [];
  @override
  List<String> get optionalConfigKeys => const [];
  @override
  List<String> get optionalTextConfigKeys => const [];
  @override
  Map<String, String> get configLabels => const {};
  @override
  String? proxyUrl;
  @override
  String? get instanceDescription => null;
  @override
  ProviderMetadata metadata = ProviderMetadata();

  Dio Function()? createHttpClientOverride;
  Future<UploadResult> Function(
    FileUploadRequest, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config,
  })? uploadCallback;
  Duration? uploadDelay;
  bool uploadCalled = false;

  void resetUploadCalled() => uploadCalled = false;

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async {
    return createHttpClientOverride?.call() ?? Dio();
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    uploadCalled = true;
    if (uploadCallback != null) {
      return uploadCallback!(request,
          onProgress: onProgress, cancelToken: cancelToken, config: config);
    }
    if (uploadDelay != null) {
      await Future.delayed(uploadDelay!);
    }
    return UploadResult(
      success: true,
      url: 'https://mock.url/${request.fileName}',
      completedAt: DateTime.now(),
    );
  }
}
