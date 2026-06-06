import 'dart:math';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';

class FilebinProvider extends BaseHttpProvider {
  @override
  String get providerId => 'filebin';

  @override
  String get providerName => 'Filebin.net';

  @override
  String get baseUrl => 'https://filebin.net';

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

      final bin = _randomBin();
      final url = '/$bin/${request.fileName}';

      final response = await dio.post(
        url,
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
      final binId = data['bin']?['id']?.toString();
      final fileName = data['file']?['filename']?.toString();
      if (binId != null && fileName != null) {
        return UploadResult(
          success: true,
          url: 'https://filebin.net/$binId/$fileName',
          statusCode: response.statusCode,
        );
      }
    }
    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }

  String _randomBin() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(15, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
