class UploadResult {
  final bool success;
  final String? url;
  final String? errorMessage;
  final String? rawError;
  final int? statusCode;
  final String? stackTrace;
  final DateTime completedAt;

  /// URL that can be used to delete the uploaded file before it expires.
  /// Only present when the provider returns a delete URL/token.
  final String? deleteUrl;

  /// The expiry duration selected by the user (e.g. '72h').
  /// Only populated when the provider has [configurableExpiry].
  final String? expiry;

  UploadResult({
    required this.success,
    this.url,
    this.errorMessage,
    this.rawError,
    this.statusCode,
    this.stackTrace,
    DateTime? completedAt,
    this.deleteUrl,
    this.expiry,
  }) : completedAt = completedAt ?? DateTime.now();

  UploadResult copyWith({
    bool? success,
    String? url,
    String? errorMessage,
    String? rawError,
    int? statusCode,
    String? stackTrace,
    DateTime? completedAt,
    String? deleteUrl,
    String? expiry,
  }) {
    return UploadResult(
      success: success ?? this.success,
      url: url ?? this.url,
      errorMessage: errorMessage ?? this.errorMessage,
      rawError: rawError ?? this.rawError,
      statusCode: statusCode ?? this.statusCode,
      stackTrace: stackTrace ?? this.stackTrace,
      completedAt: completedAt ?? this.completedAt,
      deleteUrl: deleteUrl ?? this.deleteUrl,
      expiry: expiry ?? this.expiry,
    );
  }
}
