import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class TmpFileLinkProvider extends BaseHttpProvider {
  @override
  String get providerId => 'tmpfilelink';

  @override
  String get providerName => 'tmpfile.link';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

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

      return UploadResult(
        success: false,
        errorMessage: 'genericError',
        statusCode: response.statusCode,
      );
    }

    return UploadResult(
      success: false,
      errorMessage: 'genericError',
      statusCode: response.statusCode,
    );
  }
}
