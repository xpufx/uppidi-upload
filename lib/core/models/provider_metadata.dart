class ProviderMetadata {
  final int? maxFileSizeBytes;
  final String? expiryInfo;
  final Set<String>? allowedMimeTypes;
  final Set<String>? blockedMimeTypes;
  final bool supportsDirectLink;
  final bool requiresAccount;

  const ProviderMetadata({
    this.maxFileSizeBytes,
    this.expiryInfo,
    this.allowedMimeTypes,
    this.blockedMimeTypes,
    this.supportsDirectLink = true,
    this.requiresAccount = false,
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

  String get fileSizeLabel {
    if (maxFileSizeBytes == null) return '';
    final mb = maxFileSizeBytes! ~/ (1024 * 1024);
    if (mb >= 1024) return '${mb ~/ 1024}GB';
    return '${mb}MB';
  }
}
