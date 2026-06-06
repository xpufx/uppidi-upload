import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_result.dart';

/// Uguu-compatible upload provider for user-configured instances.
///
/// Works with any server that implements the Uguu API (POST multipart file
/// to `/upload.php`, file field `files[]`, returns JSON with `"file"` key).
/// Users add their own server URL via the instance config dialog.
class CustomUguuProvider extends BaseHttpProvider {
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 128 * 1024 * 1024,
        expiryInfo: 'Varies by server',
        supportsDirectLink: true,
        capabilities: {ProviderCapability.requiresAuth},
      );

  @override
  String get providerId => 'custom_uguu';

  @override
  String get providerName => 'Uguu-like';

  @override
  String get baseUrl => ''; // set from config

  @override
  String get uploadEndpoint => '/upload.php';

  @override
  String get fileFormFieldName => 'files[]';

  @override
  List<String> get requiredConfigKeys => ['server_url'];

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get instanceDescription =>
      'Uguu-compatible — upload to your own server';

  @override
  Map<String, String> get configLabels => const {
        'server_url': 'Server URL',
      };

  @override
  Map<String, String> get additionalFormFields => const {};

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
    String? userAgent,
  }) async {
    var serverUrl = (config['server_url'] ?? '').trim();
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }
    final dio = await super.createHttpClient(
      config,
      allowInsecureConn: allowInsecureConn,
      proxyUrl: proxyUrl,
      userAgent: userAgent,
    );
    dio.options.baseUrl = serverUrl;
    return dio;
  }

  @override
  Map<String, dynamic> buildFormFields(Map<String, String> config) {
    return {};
  }

  @override
  UploadResult parseResponse(Response response) {
    try {
      if (response.data is! Map) {
        log.warn('Unhandled error (returning genericError)');
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Unexpected response: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }
      final data = response.data as Map<String, dynamic>;
      final fileUrl = (data['file'] as String?) ?? (data['url'] as String?);
      if (fileUrl == null || fileUrl.isEmpty) {
        log.warn('Unhandled error (returning genericError)');
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Missing file/url in response',
          statusCode: response.statusCode,
        );
      }
      return UploadResult(
        success: true,
        url: fileUrl,
        statusCode: response.statusCode,
      );
    } catch (e) {
      log.warn('Unhandled error (returning genericError)');
      return UploadResult(
        success: false,
        errorMessage: 'genericError',
        rawError: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
