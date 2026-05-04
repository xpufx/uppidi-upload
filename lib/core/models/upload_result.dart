class UploadResult {
  final bool success;
  final String? url;
  final String? errorMessage;
  final String? rawError;
  final int? statusCode;
  final String? stackTrace;
  final DateTime completedAt;

  UploadResult({
    required this.success,
    this.url,
    this.errorMessage,
    this.rawError,
    this.statusCode,
    this.stackTrace,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();
}
