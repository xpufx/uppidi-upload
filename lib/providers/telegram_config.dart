/// Typed config for TelegramProvider uploads.
class TelegramConfig {
  final String botToken;
  final String chatId;
  final bool sendAsPhoto;
  final String? messageText;

  const TelegramConfig({
    required this.botToken,
    required this.chatId,
    this.sendAsPhoto = false,
    this.messageText,
  });

  factory TelegramConfig.fromMap(Map<String, String> m) => TelegramConfig(
        botToken: m['bot_token'] ?? '',
        chatId: m['chat_id'] ?? '',
        sendAsPhoto: m['send_as_photo'] == 'true',
        messageText: m['message_text'],
      );
}
