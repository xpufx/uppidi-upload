import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/insecure_adapter.dart';

/// Zulip server upload provider.
///
/// Uploads files to a Zulip server via the `POST /api/v1/user_uploads`
/// endpoint.  Requires the server URL, email, and API key to be configured.
///
/// Configuration is per-instance so a user can have multiple Zulip orgs.
class ZulipProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());

  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 25 * 1024 * 1024, // 25 MB typical default
        expiryInfo: 'Persistent (until deleted)',
        supportsDirectLink: true,
        capabilities: {ProviderCapability.requiresAuth},
      );

  @override
  String get providerId => 'zulip';

  @override
  String get providerName => 'Zulip';

  @override
  String get baseUrl => ''; // set dynamically in createHttpClient

  @override
  String get uploadEndpoint => '/api/v1/user_uploads';

  @override
  String get fileFormFieldName => 'filename';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys =>
      ['zulip_url', 'zulip_email', 'zulip_api_key'];

  @override
  List<String> get optionalConfigKeys => ['zulip_direct_message'];

  @override
  List<String> get optionalTextConfigKeys =>
      ['zulip_channel', 'zulip_topic', 'zulip_recipient', 'message_template'];

  @override
  String? get instanceDescription =>
      'Zulip — upload files to your Zulip server';

  @override
  Map<String, String> get configLabels => const {
        'zulip_url': 'Server URL',
        'zulip_email': 'Email',
        'zulip_api_key': 'API Key',
        'zulip_channel': 'Channel',
        'zulip_topic': 'Topic',
        'zulip_recipient': 'Recipient',
        'zulip_direct_message': 'Direct message',
        'message_template': 'Message template',
      };

  @override
  String? get proxyUrl => null;

  @override
  Map<String, String> get additionalFormFields => const {};

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async {
    final serverUrl = config['zulip_url']?.trim() ?? '';
    final email = config['zulip_email']?.trim() ?? '';
    final apiKey = config['zulip_api_key']?.trim() ?? '';

    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final basicAuth = 'Basic ${base64Encode(utf8.encode('$email:$apiKey'))}';

    final dio = Dio(BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Authorization': basicAuth,
      },
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
    _lastServerUrl =
        (config['zulip_url']?.trim() ?? '').replaceAll(RegExp(r'/$'), '');
    final isDm = config['zulip_direct_message'] == 'true';
    final channel = isDm ? '' : (config['zulip_channel'] ?? '').trim();
    final topic = isDm ? '' : (config['zulip_topic'] ?? '').trim();
    final recipient = isDm ? (config['zulip_recipient'] ?? '').trim() : '';
    // Handle display format "John Doe (11)" stored by older versions
    final recipientMatch = RegExp(r'\((\d+)\)$').firstMatch(recipient);
    final recipientId = recipientMatch?.group(1) ?? recipient;

    try {
      final allowInsecure = config['_allow_insecure_conn'] == 'true';
      final proxyUrl = config['_proxy_url'];
      final cleanConfig = Map<String, String>.from(config)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url')
        ..remove('send_as_photo');
      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure, proxyUrl: proxyUrl);

      final fields = buildFormFields(cleanConfig);
      fields[fileFormFieldName] = MultipartFile.fromStream(
        () => request.dataStream,
        request.sizeInBytes,
        filename: request.fileName,
        contentType: request.mimeType != null
            ? DioMediaType.parse(request.mimeType!)
            : null,
      );

      final response = await dio.post(
        uploadEndpoint,
        data: FormData.fromMap(fields),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      final result = parseResponse(response);
      if (!result.success) return result;

      // Resolve message content from config
      var messageContent = config['message_text'] ?? '';
      _log.info('Zulip message_content="$messageContent" url="${result.url}"');
      if (result.url != null) {
        if (messageContent.isEmpty) {
          messageContent = result.url!;
        } else {
          messageContent = messageContent
              .replaceAll('{url}', result.url!)
              .replaceAll('{filename}', request.fileName)
              .replaceAll('{provider}', providerName);
          // Always append the URL so the file is reachable from the chat
          messageContent = '$messageContent\n${result.url}';
        }
      }

      // Post the file URL to the configured channel or send as DM
      if (channel.isNotEmpty) {
        try {
          final msgData = <String, dynamic>{
            'type': 'stream',
            'to': channel,
            'content': messageContent,
          };
          if (topic.isNotEmpty) msgData['topic'] = topic;

          final msgResponse = await dio.post(
            '/api/v1/messages',
            data: FormData.fromMap(msgData),
          );
          if (msgResponse.statusCode == 200) {
            final body = msgResponse.data is Map
                ? (msgResponse.data as Map)['msg'] as String?
                : null;
            _log.info('Posted to channel: $channel (${body ?? "ok"})');
          } else {
            _log.warn('Failed to post to channel: ${msgResponse.statusCode}');
          }
        } catch (e) {
          _log.warn('Failed to post to channel: $e');
        }
      } else if (recipientId.isNotEmpty) {
        try {
          final msgData = <String, dynamic>{
            'type': 'direct',
            'to': '[$recipientId]',
            'content': messageContent,
          };
          final msgResponse = await dio.post(
            '/api/v1/messages',
            data: FormData.fromMap(msgData),
          );
          if (msgResponse.statusCode == 200) {
            _log.info('Sent DM to user $recipientId');
          } else {
            _log.warn('Failed to send DM: ${msgResponse.statusCode}');
          }
        } catch (e) {
          _log.warn('Failed to send DM: $e');
        }
      }

      // Upload succeeded regardless of message post outcome
      return result;
    } catch (e, stackTrace) {
      _log.error('Upload failed: $e', error: e, stackTrace: stackTrace);
      final statusCode = e is DioException ? e.response?.statusCode : null;
      return UploadResult(
        success: false,
        errorMessage: mapException(e),
        rawError: e.toString(),
        statusCode: statusCode,
        stackTrace: stackTrace.toString(),
      );
    }
  }

  String? _lastServerUrl;

  @override
  UploadResult parseResponse(Response response) {
    try {
      if (response.data is! Map) {
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Unexpected response: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      if (data['result'] != 'success') {
        final msg = data['msg'] as String? ?? 'Unknown error';
        return UploadResult(
          success: false,
          errorMessage: msg,
          rawError: msg,
          statusCode: response.statusCode,
        );
      }

      // The API returns a relative path like /user_uploads/.../file
      var path = (data['url'] as String?) ?? (data['uri'] as String?) ?? '';
      if (path.isEmpty) {
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Missing url/uri in response',
          statusCode: response.statusCode,
        );
      }

      // Build the full URL
      final fullUrl = '$_lastServerUrl$path';

      return UploadResult(
        success: true,
        url: fullUrl,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        errorMessage: 'genericError',
        rawError: 'Failed to parse Zulip response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}
