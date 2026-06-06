import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class FriskProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 2 * 1024 * 1024 * 1024, // 2 GB
        expiryInfo: '~1 day (extendable on re-upload)',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'frisk';

  @override
  String get providerName => 'Frisk';

  @override
  String get baseUrl => 'https://frisk.page';

  @override
  String get uploadEndpoint => '/api/files/upload';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
      return unhandledError(response);
    }

    final json = parseJsonResponse(response);
    if (json == null) return unhandledError(response);

    final url = json['file_url'] as String?;
    if (url != null && url.isNotEmpty) {
      return UploadResult(
          success: true, url: url, statusCode: response.statusCode);
    }

    return unhandledError(response);
  }
}
