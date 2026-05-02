import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class CatboxProvider extends BaseHttpProvider {
  @override
  String get providerId => 'catbox';

  @override
  String get providerName => 'Catbox.moe';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => ['userhash'];

  @override
  Map<String, String> get configLabels => {
        'userhash': 'User Hash (optional, leave empty for anonymous)',
      };

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://catbox.moe';

  @override
  String get uploadEndpoint => '/user/api.php';

  @override
  String get fileFormFieldName => 'fileToUpload';

  @override
  Map<String, String> get additionalFormFields => {'reqtype': 'fileupload'};

  @override
  UploadResult parseResponse(Response response) {
    final responseStr = response.data.toString().trim();

    if (responseStr.startsWith('https://')) {
      return UploadResult(
        success: true,
        url: responseStr,
        statusCode: response.statusCode,
      );
    }

    return UploadResult(
      success: false,
      errorMessage: _mapCatboxError(responseStr),
      statusCode: response.statusCode,
    );
  }

  String _mapCatboxError(String response) {
    final lower = response.toLowerCase();
    if (lower.contains('file is too large') || lower.contains('too large')) {
      return 'errorFileTooLarge';
    }
    if (lower.contains('invalid') || lower.contains('auth')) {
      return 'errorSessionExpired';
    }
    return 'genericError';
  }
}
