/// Capabilities a provider can support.
/// The UI reads these to dynamically show relevant controls.
enum ProviderCapability {
  /// Provider returns a delete URL/token after upload that lets the user
  /// remove the file before it expires naturally.
  deleteUrl,

  /// Provider allows the user to choose how long the file stays up.
  /// When set, the upload screen shows an expiry picker before uploading.
  configurableExpiry,

  /// Provider needs an API key, access token, or other credentials
  /// configured in settings before it can be used.
  requiresAuth,

  /// Provider can only relay URLs — no file upload. Shown in History for
  /// sharing via Matterbridge IRC gateways.
  urlOnly,
}

class ProviderMetadata {
  final int? maxFileSizeBytes;
  final String? expiryInfo;
  final Set<String>? allowedMimeTypes;
  final Set<String>? blockedMimeTypes;
  final bool supportsDirectLink;
  final bool requiresAccount;
  final Set<ProviderCapability> capabilities;

  /// Available expiry durations for providers with [configurableExpiry].
  /// Each string is the API value (e.g. `'24h'`).
  final List<String>? expiryOptions;

  const ProviderMetadata({
    this.maxFileSizeBytes,
    this.expiryInfo,
    this.allowedMimeTypes,
    this.blockedMimeTypes,
    this.supportsDirectLink = true,
    this.requiresAccount = false,
    this.capabilities = const {},
    this.expiryOptions,
  });

  bool allowsMimeType(String mimeType) {
    if (allowedMimeTypes != null && !allowedMimeTypes!.contains(mimeType)) {
      return false;
    }
    if (blockedMimeTypes != null && blockedMimeTypes!.contains(mimeType)) {
      return false;
    }
    return true;
  }

  bool acceptsFileSize(int sizeBytes) {
    if (maxFileSizeBytes == null) return true;
    return sizeBytes <= maxFileSizeBytes!;
  }

  String get mimeTypeLabel {
    if (allowedMimeTypes == null || allowedMimeTypes!.isEmpty) return '';
    final allImages = allowedMimeTypes!.every((t) => t.startsWith('image/'));
    if (allImages && allowedMimeTypes!.isNotEmpty) return 'Images only';
    return allowedMimeTypes!
        .map((m) => m.split('/').last.toUpperCase())
        .join(', ');
  }

  String get fileSizeLabel {
    if (maxFileSizeBytes == null) return '';
    final mb = maxFileSizeBytes! ~/ (1024 * 1024);
    if (mb >= 1024) return '${mb ~/ 1024}GB';
    return '${mb}MB';
  }
}
