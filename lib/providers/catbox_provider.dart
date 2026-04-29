import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';

class CatboxProvider implements BaseUploader {
  @override
  String get providerId => 'catbox';

  @override
  String get providerName => 'Catbox.moe';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => ['userhash'];

  @override
  Map<String, String> get configLabels => {
        'userhash': 'User Hash (optional, leave empty for anonymous)',
        'proxy_url': 'Proxy URL (optional, for blocked regions)',
      };

  @override
  String? get proxyUrl => null;

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://catbox.moe',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    if (config.containsKey('proxy_url') && config['proxy_url']!.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) {
            return 'PROXY ${config['proxy_url']!}';
          };
          if (allowInsecureConn) {
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
          }
          return client;
        },
      );
    } else if (allowInsecureConn) {
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
      final config = <String, String>{}; // TODO: Load from storage
      final dio = await createHttpClient(config);

      final formData = FormData.fromMap({
        'reqtype': 'fileupload',
        'fileToUpload': MultipartFile.fromStream(
          () => request.dataStream,
          request.sizeInBytes,
          filename: request.fileName,
          contentType: request.mimeType != null
              ? DioMediaType.parse(request.mimeType!)
              : null,
        ),
      });

      final response = await dio.post(
        '/user/api.php',
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      final responseStr = response.data.toString().trim();

      if (responseStr.startsWith('https://')) {
        return UploadResult(
          success: true,
          url: responseStr,
          statusCode: response.statusCode,
        );
      } else {
        return UploadResult(
          success: false,
          errorMessage: _mapError(responseStr),
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      // TODO: Remove print in production - use proper logging
      print('Upload error: $e');
      print('Stack trace: $stackTrace');
      return UploadResult(
        success: false,
        errorMessage: 'Error: $e', // Show actual error in dev
      );
    }
  }

  String _mapError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('file is too large') || lower.contains('too large')) {
      return 'errorFileTooLarge';
    } else if (lower.contains('invalid') || lower.contains('auth')) {
      return 'errorSessionExpired';
    } else if (lower.contains('cancelled') || lower.contains('cancel')) {
      return 'uploadCancelled';
    }
    return 'genericError';
  }
}
