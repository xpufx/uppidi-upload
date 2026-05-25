import 'package:dio/dio.dart';

import 'telegram_config.dart';
import '../core/interfaces/base_http_provider.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/models/provider_metadata.dart';
import '../core/models/upload_request.dart';
import '../core/models/upload_result.dart';
import '../core/platform/insecure_adapter.dart';

/// Telegram Bot API provider.
///
/// Uploads files to a configured Telegram chat via a bot.
/// Requires `bot_token` and `chat_id` to be configured in provider settings.
///
/// The bot token is obtained from [BotFather](https://t.me/BotFather).
/// The chat ID can be obtained by messaging the bot and checking
/// `https://api.telegram.org/bot<token>/getUpdates`.
class TelegramProvider extends BaseHttpProvider {
  late final Log _log = Log(runtimeType.toString());
  @override
  ProviderMetadata get metadata => const ProviderMetadata(
        maxFileSizeBytes: 50 * 1024 * 1024, // 50 MB
        expiryInfo: 'Persistent (until bot token is revoked)',
        supportsDirectLink: false,
        capabilities: {ProviderCapability.requiresAuth},
      );

  @override
  String get providerId => 'telegram';

  @override
  String get providerName => 'Telegram';

  /// baseUrl is overridden dynamically in [createHttpClient] to include the
  /// bot token, so this getter is never actually read by the parent's
  /// [createHttpClient] implementation.
  @override
  String get baseUrl => 'https://api.telegram.org';

  @override
  String get uploadEndpoint => '/sendDocument';

  @override
  String get fileFormFieldName => 'document';

  @override
  bool get supportsWeb => false;

  @override
  List<String> get requiredConfigKeys => ['bot_token', 'chat_id'];

  @override
  List<String> get optionalConfigKeys => ['send_as_photo'];

  @override
  List<String> get optionalTextConfigKeys => const [];

  @override
  String? get instanceDescription =>
      'Telegram Bot API — send files to any chat';

  @override
  Map<String, String> get configLabels => const {
        'bot_token': 'Bot Token',
        'chat_id': 'Chat ID',
        'send_as_photo': 'Send images as photos',
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
    final token = config['bot_token'] ?? '';
    final apiBase = token.isNotEmpty
        ? 'https://api.telegram.org/bot$token'
        : 'https://api.telegram.org';

    final dio = Dio(BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
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
  Map<String, dynamic> buildFormFields(Map<String, String> config) {
    return {
      'chat_id': config['chat_id'] ?? '',
    };
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Object? config,
  }) async {
    final cfg = config is TelegramConfig
        ? config
        : TelegramConfig.fromMap(config is Map<String, String> ? config : {});
    final isImage = request.mimeType?.startsWith('image/') ?? false;
    final sendAsPhoto = isImage && cfg.sendAsPhoto;

    final endpoint = sendAsPhoto ? '/sendPhoto' : '/sendDocument';
    final fieldName = sendAsPhoto ? 'photo' : 'document';

    try {
      final rawConfig =
          config is Map<String, String> ? config : <String, String>{};
      final allowInsecure = rawConfig['_allow_insecure_conn'] == 'true';
      final proxyUrl = rawConfig['_proxy_url'];
      final cleanConfig = Map<String, String>.from(rawConfig)
        ..remove('_allow_insecure_conn')
        ..remove('_proxy_url')
        ..remove('send_as_photo');
      final dio = await createHttpClient(cleanConfig,
          allowInsecureConn: allowInsecure, proxyUrl: proxyUrl);

      final fields = buildFormFields(cleanConfig);
      if (cfg.messageText != null && cfg.messageText!.isNotEmpty) {
        fields['caption'] = cfg.messageText;
      }
      _log.info(
          'Uploading ${request.fileName} → $endpoint as $fieldName (image=$isImage, sendAsPhoto=$sendAsPhoto)');

      final file = MultipartFile.fromStream(
        () => request.dataStream,
        request.sizeInBytes,
        filename: request.fileName,
        contentType: request.mimeType != null
            ? DioMediaType.parse(request.mimeType!)
            : null,
      );
      fields[fieldName] = file;

      final response = await dio.post(
        endpoint,
        data: FormData.fromMap(fields),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      return parseResponse(response);
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

  @override
  UploadResult parseResponse(Response response) {
    try {
      if (response.data is! Map) {
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Unexpected response type: ${response.data.runtimeType}',
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;

      if (data['ok'] != true) {
        final errorCode = data['error_code'];
        final description = (data['description'] as String?) ?? 'Unknown error';

        return UploadResult(
          success: false,
          errorMessage: _mapTelegramError(errorCode, description),
          rawError: 'Telegram API error $errorCode: $description',
          statusCode: errorCode is int ? errorCode : response.statusCode,
        );
      }

      // Extract message_id and chat_id from the result
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Missing "result" in Telegram response',
          statusCode: response.statusCode,
        );
      }

      final messageId = result['message_id'];
      final chat = result['chat'] as Map<String, dynamic>?;
      final chatId = chat?['id'];

      if (messageId == null || chatId == null) {
        return UploadResult(
          success: false,
          errorMessage: 'genericError',
          rawError: 'Missing message_id or chat_id in Telegram response',
          statusCode: response.statusCode,
        );
      }

      // Build a t.me link
      final link = _buildTelegramLink(chatId.toString(), messageId.toString());

      return UploadResult(
        success: true,
        url: link,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        errorMessage: 'genericError',
        rawError: 'Failed to parse Telegram response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  /// Maps a Telegram API error code and description to a user-friendly
  /// error message key (resolved via l10n), or a plain English string
  /// with runtime data.
  String _mapTelegramError(Object? errorCode, String description) {
    final descLower = description.toLowerCase();

    if (descLower.contains('chat not found')) {
      return 'telegramErrorChatNotFound';
    }
    if (descLower.contains('bot was blocked')) {
      return 'telegramErrorBotBlocked';
    }
    if (descLower.contains('not enough rights') ||
        descLower.contains('rights')) {
      return 'telegramErrorNoRights';
    }
    if (descLower.contains('file is too big') ||
        descLower.contains('too large')) {
      return 'errorFileTooLarge';
    }
    if (descLower.contains('invalid token') ||
        descLower.contains('unauthorized')) {
      return 'telegramErrorInvalidToken';
    }

    // Generic fallback with the description
    return 'Telegram: $description';
  }

  /// Builds a deep link from a chat ID and message ID.
  /// Uses `tg://openmessage` for all types because that's the only URL
  /// scheme guaranteed to open the Telegram app on Android for any chat.
  String _buildTelegramLink(String chatId, String messageId) {
    return 'tg://openmessage?chat_id=$chatId&message_id=$messageId';
  }
}
