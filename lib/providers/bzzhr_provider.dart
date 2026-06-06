import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';

class BzzhrProvider extends BaseHttpProvider {
  @override
  String get providerId => 'bzzhr';

  @override
  String get providerName => 'Bzzhr.to';

  @override
  String get baseUrl => 'https://w.bzzhr.co';

  @override
  String get uploadEndpoint => '';

  @override
  String get fileFormFieldName => '';

  @override
  Map<String, String> get additionalFormFields => {};

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Object? config,
  }) async {
    try {
      final prepared = await prepareRequest(config);
      final dio = prepared.dio;

      final response = await dio.put(
        '/${request.fileName}',
        data: request.dataStream,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': request.sizeInBytes.toString(),
          },
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return parseResponse(response);
    } catch (e, stackTrace) {
      return uploadError(e, stackTrace);
    }
  }

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 201 && response.data is Map) {
      final data = response.data as Map;
      if (data['code'] == 201 && data['data'] is Map) {
        final fileData = data['data'] as Map;
        final id = fileData['id']?.toString();
        if (id != null) {
          return UploadResult(
            success: true,
            url: 'https://bzzhr.co/$id',
            statusCode: response.statusCode,
          );
        }
      }
    }

    final msg = response.data is Map
        ? (response.data as Map)['error']?.toString()
        : null;
    return UploadResult(
      success: false,
      errorMessage: msg ?? 'genericError',
      statusCode: response.statusCode,
    );
  }
}
