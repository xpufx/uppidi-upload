import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class TmpFileLinkProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 100 * 1024 * 1024,
        expiryInfo: '7 days',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'tmpfilelink';

  @override
  String get providerName => 'tmpfile.link';

  @override
  String get baseUrl => 'https://tmpfile.link';

  @override
  String get uploadEndpoint => '/api/upload';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final downloadLink = data['downloadLink'] as String?;

      if (downloadLink != null && downloadLink.isNotEmpty) {
        return UploadResult(
          success: true,
          url: downloadLink,
          statusCode: response.statusCode,
        );
      }

      log.warn('Unhandled error (returning genericError)');
      return UploadResult(
        success: false,
        errorMessage: 'genericError',
        statusCode: response.statusCode,
      );
    }

    log.warn('Unhandled error (returning genericError)');
    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }
}
