import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

class FileDitchProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 100 * 1024 * 1024 * 1024, // 100 GB
        expiryInfo: 'Indefinite (inactive >30d may delete)',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'fileditch';

  @override
  String get providerName => 'FileDitch';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://new.fileditch.com';

  @override
  String get uploadEndpoint => '/upload.php';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
      return UploadResult(
          success: false,
          errorMessage: 'genericError',
          statusCode: response.statusCode);
    }

    try {
      final body = response.data;
      Map<String, dynamic> json;
      if (body is String) {
        json = jsonDecode(body) as Map<String, dynamic>;
      } else if (body is Map) {
        json = body.cast<String, dynamic>();
      } else {
        return UploadResult(
            success: false,
            errorMessage: 'genericError',
            statusCode: response.statusCode);
      }

      if (json['success'] == true && json['url'] != null) {
        return UploadResult(
            success: true,
            url: json['url'] as String,
            statusCode: response.statusCode);
      }

      final error = json['error'] as String? ?? 'genericError';
      return UploadResult(
          success: false, errorMessage: error, statusCode: response.statusCode);
    } catch (e) {
      return UploadResult(
          success: false,
          errorMessage: 'genericError',
          statusCode: response.statusCode);
    }
  }
}
