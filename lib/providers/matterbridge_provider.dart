import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/insecure_adapter.dart';

/// Matterbridge API provider.
///
/// Relays file URLs (and optionally raw bytes) to bridged gateways via the
/// Matterbridge API. Each gateway (IRC channel, Discord server, etc.) is a
/// separate `ProviderInstance` with its own protocol capability.
class MatterbridgeProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());

  @override
  String get providerId => 'matterbridge';

  @override
  String get providerName => 'Matterbridge';

  /// Dynamic — set per-request by the gateway instance.
  @override
  String get baseUrl => '';

  /// Not used — upload is a POST to /api/message, not a file endpoint.
  @override
  String get uploadEndpoint => '/api/message';

  @override
  String get fileFormFieldName => 'file';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => ['mb_url', 'mb_token'];

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  List<String> get optionalTextConfigKeys => ['mb_gateway', 'paired_provider'];

  @override
  String? get instanceDescription =>
      'Matterbridge — relay files to bridged gateways';

  @override
  Map<String, String> get configLabels => const {
        'mb_url': 'Server URL',
        'mb_token': 'API Token',
        'mb_gateway': 'Gateway',
        'paired_provider': 'Upload via',
      };

  @override
  String? get proxyUrl => null;

  @override
  Map<String, String> get additionalFormFields => const {};

  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 50 * 1024 * 1024,
        supportsDirectLink: false,
        capabilities: {ProviderCapability.requiresAuth},
      );

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async {
    final url = (config['mb_url']?.trim() ?? '').replaceAll(RegExp(r'/$'), '');
    final token = config['mb_token']?.trim() ?? '';

    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Authorization': 'Bearer $token'},
      validateStatus: (_) => true,
    ));

    if (allowInsecureConn) {
      configureInsecureConn(dio);
    }
    if (proxyUrl != null && proxyUrl.isNotEmpty) {
      configureProxy(dio, proxyUrl);
    }
    return dio;
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    try {
      final gateway = (config['mb_gateway'] ?? '').trim();
      final preUrl = config['_pre_uploaded_url'] ?? '';
      final allowInsecure = config['_allow_insecure_conn'] == 'true';
      final proxyUrl = config['_proxy_url'];
      final cleanConfig = Map<String, String>.from(config)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url')
        ..remove('_pre_uploaded_url')
        ..remove('_expiry');

      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure, proxyUrl: proxyUrl);

      final message = config['message_text'] ?? '';
      final body = <String, dynamic>{
        'text': message.isNotEmpty
            ? message
            : preUrl.isNotEmpty
                ? 'Uppidi Uploaded: $preUrl'
                : request.fileName,
        'gateway': gateway,
      };

      if (preUrl.isEmpty) {
        final bytes = await request.dataStream.first;
        body['Extra'] = {
          'file': [
            {
              'Name': request.fileName,
              'Data': base64Encode(bytes),
              'Comment': 'from Uppidi',
            },
          ],
        };
      }

      _log.info(
          'Matterbridge: gateway=$gateway url=${preUrl.isNotEmpty ? "paired" : "direct"}');

      final response = await dio.post(
        '/api/message',
        data: body,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      _log.info('Matterbridge response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return UploadResult(
          success: true,
          url: preUrl,
          statusCode: response.statusCode,
          completedAt: DateTime.now(),
        );
      }

      return UploadResult(
        success: false,
        errorMessage: 'uploadFailed',
        rawError: 'Matterbridge error: ${response.statusCode}',
        statusCode: response.statusCode,
        completedAt: DateTime.now(),
      );
    } catch (e, st) {
      _log.error('Matterbridge upload failed: $e', error: e, stackTrace: st);
      return UploadResult(
        success: false,
        errorMessage: mapException(e),
        rawError: e.toString(),
        completedAt: DateTime.now(),
      );
    }
  }

  @override
  UploadResult parseResponse(Response response) {
    // Not used — upload handles its own response.
    return UploadResult(success: true, completedAt: DateTime.now());
  }
}
