import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class FreeImageHostProvider extends BaseHttpProvider {
  final String _name;
  final String _url;
  final String _apiKey;

  FreeImageHostProvider({
    String name = 'freeimage.host',
    String url = 'https://freeimage.host',
    String apiKey = '6d207e02198a847aa98d0a2a901485a5',
  })  : _name = name,
        _url = url,
        _apiKey = apiKey;

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
  String get uploadEndpoint => '/api/1/upload?key=$_apiKey&format=json';

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
      statusCode: response.statusCode,
    );
  }
}
