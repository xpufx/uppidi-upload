import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class FilesterProvider extends BaseHttpProvider {
  @override
  String get providerId => 'filester';

  @override
  String get providerName => 'Filester.me';

  @override
  String get baseUrl => 'https://u1.filester.me';

  @override
  String get uploadEndpoint => '/api/v1/upload';

  @override
  String get fileFormFieldName => 'file';

  @override
  Map<String, String> get additionalFormFields => {};

  @override
  UploadResult parseResponse(Response response) {
    final data = response.data;
    if (data is Map && data['success'] == true && data['slug'] != null) {
      return UploadResult(
        success: true,
        url: 'https://filester.me/d/${data['slug']}',
        statusCode: response.statusCode,
      );
    }

    final message = data is Map ? data['message']?.toString() : null;
    return UploadResult(
      success: false,
      errorMessage: message ?? 'genericError',
      statusCode: response.statusCode,
    );
  }
}
