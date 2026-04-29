import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';

class HttpBinProvider implements BaseUploader {
  @override
  String get providerId => 'httpbin';

  @override
  String get providerName => 'HttpBin.org (Test)';

  @override
  bool get supportsWeb => true;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://httpbin.org',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    if (allowInsecureConn) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    return dio;
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final dio = await createHttpClient({});

      final formData = FormData.fromMap({
        'file': MultipartFile.fromStream(
          () => request.dataStream,
          request.sizeInBytes,
          filename: request.fileName,
          contentType: request.mimeType != null
              ? DioMediaType.parse(request.mimeType!)
              : null,
        ),
      });

      final response = await dio.post(
        '/post',
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      // httpbin.org returns JSON with the posted data
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final origin = data['origin'] ?? 'unknown';
        return UploadResult(
          success: true,
          url: 'https://httpbin.org/post (from $origin)',
          statusCode: response.statusCode,
        );
      } else {
        return UploadResult(
          success: false,
          errorMessage: 'Unexpected response: ${response.data}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('HttpBin upload error: $e');
      print('Stack trace: $stackTrace');
      return UploadResult(
        success: false,
        errorMessage: 'Error: $e',
      );
    }
  }
}
