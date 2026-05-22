import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';
import '../core/logging/log.dart';

class FriskProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 2 * 1024 * 1024 * 1024, // 2 GB
        expiryInfo: '~1 day (extendable on re-upload)',
        supportsDirectLink: true,
      );

  @override
  String get providerId => 'frisk';

  @override
  String get providerName => 'Frisk';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  String? get proxyUrl => null;

  @override
  String get baseUrl => 'https://frisk.page';

  @override
  String get uploadEndpoint => '/api/files/upload';

  @override
  String get fileFormFieldName => 'file';

  @override
  UploadResult parseResponse(Response response) {
    if (response.statusCode != 200) {
      _log.warn('Unhandled error (returning genericError)');
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
        // Use Map.from to avoid .cast<>() which throws if any value is
        // non-String (e.g. nested objects, numbers).
        json = Map<String, dynamic>.from(body);
      } else {
        _log.warn('Unhandled error (returning genericError)');
        return UploadResult(
            success: false,
            errorMessage: 'genericError',
            statusCode: response.statusCode);
      }

      final url = json['file_url'] as String?;
      if (url != null && url.isNotEmpty) {
        return UploadResult(
            success: true, url: url, statusCode: response.statusCode);
      }

      _log.warn('Unhandled error (returning genericError)');
      return UploadResult(
          success: false,
          errorMessage: 'genericError',
          statusCode: response.statusCode);
    } catch (e) {
      _log.warn('Unhandled error (returning genericError)');
      return UploadResult(
          success: false,
          errorMessage: 'genericError',
          statusCode: response.statusCode);
    }
  }
}
