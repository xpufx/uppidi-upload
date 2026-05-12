import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class LitterboxProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 1024 * 1024 * 1024,
        expiryInfo: '1h / 24h / 72h',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'litterbox';

  @override
  String get providerName => 'Litterbox';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://litterbox.catbox.moe';

  @override
  String get uploadEndpoint => '/resources/internals/api.php';

  @override
  String get fileFormFieldName => 'fileToUpload';

  @override
  Map<String, String> get additionalFormFields => const {
        'reqtype': 'fileupload',
        'time': '24h',
      };

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
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

    return UploadResult(
        success: false,
        errorMessage: 'genericError',
        statusCode: response.statusCode);
  }
}
