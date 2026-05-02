import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class UguuProvider extends BaseHttpProvider {
  @override
  String get providerId => 'uguu';

  @override
  String get providerName => 'uguu.se';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://uguu.se';

  @override
  String get uploadEndpoint => '/upload';

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
