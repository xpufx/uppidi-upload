import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class UguuProvider extends BaseHttpProvider {
  final String _name;
  final String _url;
  final String _endpoint;
  final ProviderMetadata _metadata;

  UguuProvider({
    String name = 'uguu.se',
    String url = 'https://uguu.se',
    String endpoint = '/upload',
    ProviderMetadata? metadata,
  })  : _name = name,
        _url = url,
        _endpoint = endpoint,
        _metadata = metadata ??
            const ProviderMetadata(
              maxFileSizeBytes: 128 * 1024 * 1024,
              supportsDirectLink: true,
              expiryInfo: '3 hours',
            );

  @override
  ProviderMetadata get metadata => _metadata;

  @override
  String get providerId => 'uguu_${_name.replaceAll('.', '_')}';

  @override
  String get providerName => _name;

  @override
  String get baseUrl => _url;

  @override
  String get uploadEndpoint => _endpoint;

  @override
  String get fileFormFieldName => 'files[]';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      // Guard against unexpected types: 'files' might be missing or non-List.
      final filesRaw = data['files'];
      final files = (filesRaw is List) ? filesRaw : null;

      if (files != null && files.isNotEmpty) {
        // Guard against non-Map elements in the files array.
        final first = files[0];
        final fileData =
            (first is Map) ? Map<String, dynamic>.from(first) : null;
        final url = fileData?['url'] as String?;

        if (url != null && url.isNotEmpty) {
          return UploadResult(
            success: true,
            url: url,
            statusCode: response.statusCode,
          );
        }
      }
    }

    return unhandledError(response);
  }
}
