import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import 'bzzhr_config.dart';

class BzzhrProvider extends BaseHttpProvider {
  @override
  String get providerId => 'bzzhr';

  @override
  String get providerName => 'Bzzhr.to';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

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
      final cfg = config is BzzhrConfig ? config : const BzzhrConfig();
      final rawConfig = cfg.data;
      final allowInsecure = rawConfig['_allow_insecure_conn'] == 'true';
      final proxyUrl = rawConfig['_proxy_url'];
      final userAgent = rawConfig['_user_agent'];
      final cleanConfig = Map<String, String>.from(rawConfig)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url')
        ..remove('_user_agent');
      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure,
          proxyUrl: proxyUrl,
          userAgent: userAgent);

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
