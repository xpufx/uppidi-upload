import 'dart:io';

class UploadResult {
  final bool success;
  final String? url;
  final String? errorMessage;
  final int? statusCode;
  final DateTime completedAt;

  const UploadResult({
    required this.success,
    this.url,
    this.errorMessage,
    this.statusCode,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();
}
