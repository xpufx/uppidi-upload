import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';
import '../core/logging/log.dart';

class TempShProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 4 * 1024 * 1024 * 1024,
        expiryInfo: '3 days',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'tempsh';

  @override
  String get providerName => 'temp.sh';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://temp.sh';

  @override
  String get uploadEndpoint => '/upload';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
      _log.warn('Unhandled error (returning genericError)');
      return UploadResult(
          success: false,
          errorMessage: 'genericError',
          statusCode: response.statusCode);
    }

    final body = response.data.toString().trim();

    if (body.startsWith('https://') || body.startsWith('http://')) {
      return UploadResult(
          success: true, url: body, statusCode: response.statusCode);
    }

    _log.warn('Unhandled error (returning genericError)');
    return UploadResult(
        success: false,
        errorMessage: 'genericError',
        statusCode: response.statusCode);
  }
}
