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
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

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
      final files = data['files'] as List<dynamic>?;

      if (files != null && files.isNotEmpty) {
        final fileData = files[0] as Map<String, dynamic>?;
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

    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }
}
