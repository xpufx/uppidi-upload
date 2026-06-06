import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class FileDitchProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 100 * 1024 * 1024 * 1024, // 100 GB
        expiryInfo: 'Indefinite (inactive >30d may delete)',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'fileditch';

  @override
  String get providerName => 'FileDitch';

  @override
  String get baseUrl => 'https://new.fileditch.com';

  @override
  String get uploadEndpoint => '/upload.php';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    final json = parseJsonResponse(response);
    if (json == null) return unhandledError(response);

    if (json['success'] == true && json['url'] != null) {
      return UploadResult(
          success: true,
          url: json['url'] as String,
          statusCode: response.statusCode);
    }

    final error = json['error'] as String? ?? 'genericError';
    return UploadResult(
        success: false, errorMessage: error, statusCode: response.statusCode);
  }
}
