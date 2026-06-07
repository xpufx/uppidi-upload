import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class LitterboxProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 1024 * 1024 * 1024,
        expiryInfo: '1h / 12h / 24h / 72h',
        supportsDirectLink: true,
        capabilities: {ProviderCapability.configurableExpiry},
        expiryOptions: ['1h', '12h', '24h', '72h'],
      );

  @override
  String get providerId => 'litterbox';

  @override
  String get providerName => 'Litterbox';

  @override
  String get baseUrl => 'https://litterbox.catbox.moe';

  @override
  String get uploadEndpoint => '/resources/internals/api.php';

  @override
  String get fileFormFieldName => 'fileToUpload';

  @override
  Map<String, String> get additionalFormFields => const {
        'reqtype': 'fileupload',
      };

  @override
  Map<String, dynamic> buildFormFields(Map<String, String> config) {
    return {
      'reqtype': 'fileupload',
      'time': config['_expiry'] ?? '24h',
    };
  }

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
      return unhandledError(response);
    }

    final body = response.data.toString().trim();

    if (body.startsWith('https://') || body.startsWith('http://')) {
      return UploadResult(
          success: true, url: body, statusCode: response.statusCode);
    }

    return unhandledError(response);
  }
}
