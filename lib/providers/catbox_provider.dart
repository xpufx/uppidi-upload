import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class CatboxProvider extends BaseHttpProvider {
  @override
  String get providerId => 'catbox';

  @override
  String get providerName => 'Catbox.moe';

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

    if (responseStr.startsWith('https://') ||
        responseStr.startsWith('http://')) {
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
    if (lower.contains('invalid uploader') || lower.contains('invalid')) {
      return 'errorInvalidUploader';
    }
    if (lower.contains('auth')) {
      return 'errorSessionExpired';
    }
    log.warn('Unhandled error (returning genericError)');
    return 'genericError';
  }
}
