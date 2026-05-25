/// Typed config for ZulipProvider uploads.
class ZulipConfig {
  final String serverUrl;
  final String email;
  final String apiKey;
  final bool isDm;
  final String channel;
  final String topic;
  final String recipient;
  final String? messageText;

  const ZulipConfig({
    required this.serverUrl,
    required this.email,
    required this.apiKey,
    this.isDm = false,
    this.channel = '',
    this.topic = '',
    this.recipient = '',
    this.messageText,
  });

  factory ZulipConfig.fromMap(Map<String, String> m) {
    final isDm = m['zulip_direct_message'] == 'true';
    // Handle display format "John Doe (11)" for backward compatibility
    final rawRecipient = (m['zulip_recipient'] ?? '').trim();
    final match = RegExp(r'\((\d+)\)$').firstMatch(rawRecipient);
    final recipientId = match?.group(1) ?? rawRecipient;
    return ZulipConfig(
      serverUrl: (m['zulip_url'] ?? '').trim(),
      email: (m['zulip_email'] ?? '').trim(),
      apiKey: (m['zulip_api_key'] ?? '').trim(),
      isDm: isDm,
      channel: isDm ? '' : (m['zulip_channel'] ?? '').trim(),
      topic: isDm ? '' : (m['zulip_topic'] ?? '').trim(),
      recipient: isDm ? recipientId : '',
      messageText: m['message_text'],
    );
  }
}
