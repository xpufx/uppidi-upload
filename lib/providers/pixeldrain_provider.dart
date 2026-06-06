import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/upload_result.dart';

class PixeldrainProvider extends BaseHttpProvider {
  @override
  String get providerId => 'pixeldrain';

  @override
  String get providerName => 'Pixeldrain';

  @override
  List<String> get requiredConfigKeys => ['api_key'];

  @override
  Map<String, String> get configLabels => const {
        'api_key': 'API Key',
      };

  @override
  String get baseUrl => 'https://pixeldrain.com';

  @override
  String get uploadEndpoint => '/api/file';

  @override
  String get fileFormFieldName => 'file';

  @override
  Map<String, String> get additionalFormFields => {};

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
    String? userAgent,
  }) async {
    final dio = await super.createHttpClient(config,
        allowInsecureConn: allowInsecureConn,
        proxyUrl: proxyUrl,
        userAgent: userAgent);
    final apiKey = config['api_key'];
    if (apiKey != null && apiKey.isNotEmpty) {
      final basic = base64Encode(utf8.encode(':$apiKey'));
      dio.options.headers['Authorization'] = 'Basic $basic';
    }
    return dio;
  }

  @override
  UploadResult parseResponse(Response response) {
    final data = response.data;
    if (data is Map && data['id'] != null) {
      return UploadResult(
        success: true,
        url: 'https://pixeldrain.com/u/${data['id']}',
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
