import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class HttpBinProvider extends BaseHttpProvider {
  @override
  String get providerId => 'httpbin';

  @override
  String get providerName => 'HttpBin.org (Test)';

  @override
  bool get supportsWeb => true;

  @override
  String get baseUrl => 'https://httpbin.org';

  @override
  String get uploadEndpoint => '/post';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map;
      final origin = data['origin'] ?? 'unknown';
      return UploadResult(
        success: true,
        url: 'https://httpbin.org/post (from $origin)',
        statusCode: response.statusCode,
      );
    }

    log.warn(
        'Unexpected response: status=${response.statusCode}, data=${response.data}');
    return UploadResult(
      success: false,
      errorMessage: 'Unexpected response: ${response.data}',
      statusCode: response.statusCode,
    );
  }
}
