import 'package:dio/dio.dart';

import '../logging/log.dart';
import '../models/provider_metadata.dart';
import '../models/upload_request.dart';
import '../models/upload_result.dart';
import '../platform/insecure_adapter.dart';
import 'uploader.dart';

abstract class BaseHttpProvider implements BaseUploader {
  late final Log _log = Log(runtimeType.toString());

  String get baseUrl;
  String get uploadEndpoint;
  String get fileFormFieldName;

  Map<String, String> get additionalFormFields => const {};

  @override
  ProviderMetadata get metadata => const ProviderMetadata();

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    if (allowInsecureConn) {
      configureInsecureConn(dio);
    }

    return dio;
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    try {
      final allowInsecure = config['_allow_insecure_conn'] == 'true';
      final cleanConfig = Map<String, String>.from(config)..remove('_allow_insecure_conn');
      final dio = await createHttpClient(cleanConfig, allowInsecureConn: allowInsecure);

      final fields = Map<String, dynamic>.from(additionalFormFields);
      fields[fileFormFieldName] = _buildStreamFile(request);

      final response = await dio.post(
        uploadEndpoint,
        data: FormData.fromMap(fields),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return parseResponse(response);
    } catch (e, stackTrace) {
      _log.error('Upload failed: $e', error: e, stackTrace: stackTrace);
      return UploadResult(
        success: false,
        errorMessage: _mapException(e),
      );
    }
  }

  MultipartFile _buildStreamFile(FileUploadRequest request) {
    return MultipartFile.fromStream(
      () => request.dataStream,
      request.sizeInBytes,
      filename: request.fileName,
      contentType: request.mimeType != null
          ? DioMediaType.parse(request.mimeType!)
          : null,
    );
  }

  UploadResult parseResponse(Response response);

  String _mapException(Object e) {
    if (e is DioException) {
      return switch (e.type) {
        DioExceptionType.cancel => 'uploadCancelled',
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError =>
          'errorConnectionFailed',
        _ => 'genericError',
      };
    }
    return 'genericError';
  }
}
