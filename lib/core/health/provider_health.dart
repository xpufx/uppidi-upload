// Pure-Dart provider health manifest logic shared by the app and the
// scheduled health-check runner. Must not import Flutter so it can run
// under a bare test harness.

/// Number of consecutive failures before a provider is disabled.
const int healthFailureThreshold = 2;

/// Wire-format version emitted by the health runner.
const int healthManifestVersion = 1;

/// Health state for a single provider.
class ProviderHealthInfo {
  final bool disabled;
  final String? since;
  final String? reason;
  final int failureCount;
  final String? checked;

  const ProviderHealthInfo({
    required this.disabled,
    this.since,
    this.reason,
    this.failureCount = 0,
    this.checked,
  });

  factory ProviderHealthInfo.fromJson(Map<String, dynamic> json) {
    return ProviderHealthInfo(
      disabled: json['disabled'] as bool? ?? false,
      since: json['since'] as String?,
      reason: json['reason'] as String?,
      failureCount: (json['failureCount'] as num?)?.toInt() ?? 0,
      checked: json['checked'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'disabled': disabled,
        'since': since,
        'reason': reason,
        'failureCount': failureCount,
        'checked': checked,
      };
}

/// Applies a single probe result on top of [previous], returning the new
/// state. Success resets the failure counter and re-enables the provider.
/// A failure increments the counter and disables the provider once the
/// streak reaches [healthFailureThreshold]. `since` is stamped when the
/// provider becomes disabled and preserved while it stays disabled.
ProviderHealthInfo applyProbeResult(
  ProviderHealthInfo? previous, {
  required bool success,
  required DateTime now,
  String? reason,
}) {
  final checked = now.toUtc().toIso8601String();

  if (success) {
    return ProviderHealthInfo(
      disabled: false,
      failureCount: 0,
      checked: checked,
    );
  }

  final failureCount = (previous?.failureCount ?? 0) + 1;
  final disabled = failureCount >= healthFailureThreshold;
  final since = disabled
      ? (previous?.disabled == true && previous?.since != null
          ? previous!.since
          : checked)
      : null;

  return ProviderHealthInfo(
    disabled: disabled,
    failureCount: failureCount,
    since: since,
    reason: reason,
    checked: checked,
  );
}

/// Parses a health manifest, tolerating BOTH the legacy flat map
/// (`{"httpbin": {...}}`) and the versioned shape
/// (`{"version": 1, "updated": "...", "providers": {...}}`).
Map<String, ProviderHealthInfo> parseHealthManifest(dynamic decoded) {
  if (decoded is! Map) return {};

  final root = Map<String, dynamic>.from(decoded);
  final providersRaw = root['providers'];
  final Map<String, dynamic> providers = providersRaw is Map
      ? Map<String, dynamic>.from(providersRaw)
      : root;

  final result = <String, ProviderHealthInfo>{};
  providers.forEach((key, value) {
    if (value is Map) {
      result[key] =
          ProviderHealthInfo.fromJson(Map<String, dynamic>.from(value));
    }
  });
  return result;
}

/// Serializes [providers] to the versioned wire format.
Map<String, dynamic> buildHealthManifest(
  Map<String, ProviderHealthInfo> providers,
  DateTime now,
) {
  return {
    'version': healthManifestVersion,
    'updated': now.toUtc().toIso8601String(),
    'providers': {
      for (final entry in providers.entries) entry.key: entry.value.toJson(),
    },
  };
}
