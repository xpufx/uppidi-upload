import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class FreeImageHostProvider extends BaseHttpProvider {
  final String _name;
  final String _url;
  final String _apiKey;

  FreeImageHostProvider({
    String name = 'freeimage.host',
    String url = 'https://freeimage.host',
  })  : _name = name,
        _url = url,
        _apiKey = '';

  @override
  ProviderMetadata get metadata => const ProviderMetadata(
    maxFileSizeBytes: 64 * 1024 * 1024,
    allowedMimeTypes: {'image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/bmp'},
    supportsDirectLink: true,
  );

  @override
  String get providerId => 'freeimage_${_name.replaceAll('.', '_')}';

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
  String get uploadEndpoint => _apiKey.isNotEmpty
      ? '/api/1/upload?key=$_apiKey&format=json'
      : '/api/1/upload?format=json';

  @override
  String get fileFormFieldName => 'source';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final image = data['image'] as Map<String, dynamic>?;

      if (image != null) {
        final url = (image['display_url'] ??
                image['url'] ??
                '') as String;

        if (url.isNotEmpty) {
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
      rawError: response.data.toString().substring(0, 5000),
      statusCode: response.statusCode,
    );
  }
}
