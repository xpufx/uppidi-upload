const _sentinel = Object();

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
    Object? url = _sentinel,
    Object? errorMessage = _sentinel,
    Object? rawError = _sentinel,
    int? statusCode,
    Object? stackTrace = _sentinel,
    DateTime? completedAt,
    Object? deleteUrl = _sentinel,
    Object? expiry = _sentinel,
  }) {
    return UploadResult(
      success: success ?? this.success,
      url: identical(url, _sentinel) ? this.url : url as String?,
      errorMessage:
          identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      rawError:
          identical(rawError, _sentinel) ? this.rawError : rawError as String?,
      statusCode: statusCode ?? this.statusCode,
      stackTrace:
          identical(stackTrace, _sentinel) ? this.stackTrace : stackTrace as String?,
      completedAt: completedAt ?? this.completedAt,
      deleteUrl:
          identical(deleteUrl, _sentinel) ? this.deleteUrl : deleteUrl as String?,
      expiry: identical(expiry, _sentinel) ? this.expiry : expiry as String?,
    );
  }
}
