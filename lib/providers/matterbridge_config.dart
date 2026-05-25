/// Typed config for MatterbridgeProvider uploads.
/// Fields are resolved from the raw config map at the _executeUpload dispatch
/// layer, eliminating `config['arbitrary_key']` bugs in the upload method.
class MatterbridgeConfig {
  final String serverUrl;
  final String token;
  final String gateway;
  final String? preUploadedUrl;
  final String? messageText;
  final String? pairedProvider;

  const MatterbridgeConfig({
    required this.serverUrl,
    required this.token,
    required this.gateway,
    this.preUploadedUrl,
    this.messageText,
    this.pairedProvider,
  });

  factory MatterbridgeConfig.fromMap(Map<String, String> m) =>
      MatterbridgeConfig(
        serverUrl: (m['mb_url'] ?? '').trim(),
        token: (m['mb_token'] ?? '').trim(),
        gateway: (m['mb_gateway'] ?? '').trim(),
        preUploadedUrl: m['_pre_uploaded_url'],
        messageText: m['message_text'],
        pairedProvider: m['paired_provider'],
      );
}
