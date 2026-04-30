import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';

class TmpFileLinkProvider implements BaseUploader {
  @override
  String get providerId => 'tmpfilelink';

  @override
  String get providerName => 'tmpfile.link';

  @override
  bool get supportsWeb => false;

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
      baseUrl: 'https://tmpfile.link',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

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

      debugPrint('[TmpFileLink] Uploading: ${request.fileName} (${request.sizeInBytes} bytes)');
      debugPrint('[TmpFileLink] Endpoint: https://tmpfile.link/api/upload');

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
        '/api/upload',
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      debugPrint('[TmpFileLink] Response status: ${response.statusCode}');
      debugPrint('[TmpFileLink] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final downloadLink = data['downloadLink'] as String?;

        if (downloadLink != null && downloadLink.isNotEmpty) {
          return UploadResult(
            success: true,
            url: downloadLink,
            statusCode: response.statusCode,
          );
        } else {
          return UploadResult(
            success: false,
            errorMessage: 'No download link in response',
            statusCode: response.statusCode,
          );
        }
      } else {
        return UploadResult(
          success: false,
          errorMessage: 'Unexpected response: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[TmpFileLink] Upload error: $e');
      debugPrint('[TmpFileLink] Stack trace: $stackTrace');
      return UploadResult(
        success: false,
        errorMessage: 'Error: $e',
      );
    }
  }
}