import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'interfaces/base_http_provider.dart';
import 'interfaces/uploader.dart';
import 'settings_service.dart';

/// Check whether the selected provider's connection is potentially insecure
/// and, if so, show a warning dialog before allowing the upload to proceed.
///
/// Returns `true` if the upload should proceed, `false` if the user cancelled.
Future<bool> checkInsecureWarning(
  BuildContext context,
  BaseUploader provider,
  WidgetRef ref,
) async {
  // Only HTTP-based providers have a URL we can inspect
  if (provider is! BaseHttpProvider) return true;

  final baseUrl = provider.baseUrl;
  final uri = Uri.tryParse(baseUrl);
  if (uri == null) return true;

  final svc = ref.read(settingsServiceProvider);

  // For plain HTTP — always warn (no encryption at all)
  if (uri.scheme == 'http') {
    final muted = await svc.isInsecureWarningMuted(provider.providerId);
    if (muted) return true;

    final l10n = AppLocalizations.of(context);
    return _showHttpWarning(context, provider, svc, l10n);
  }

  // For HTTPS — only warn if insecure connections are globally enabled
  if (uri.scheme == 'https') {
    final allowInsecure = await svc.isInsecureConnAllowed();
    if (!allowInsecure) return true; // SSL error will surface naturally

    final muted = await svc.isInsecureWarningMuted(provider.providerId);
    if (muted) return true;

    final l10n = AppLocalizations.of(context);
    return _showHttpsWarning(context, provider, svc, l10n);
  }

  return true; // other schemes don't need a warning
}

// ---------------------------------------------------------------------------
// HTTP warning
// ---------------------------------------------------------------------------

Future<bool> _showHttpWarning(
  BuildContext context,
  BaseUploader provider,
  SettingsService svc,
  AppLocalizations l10n,
) async {
  final baseUrl = _getBaseUrl(provider);
  final result = await showDialog<_WarningResult>(
    context: context,
    builder: (ctx) => _InsecureWarningDialog(
      title: l10n.insecureWarningTitle,
      body: l10n.insecureWarningHttp(provider.providerName, baseUrl),
      showViewCert: false,
    ),
  );
  return _handleResult(result, provider.providerId, svc);
}

// ---------------------------------------------------------------------------
// HTTPS (cert-bypass) warning
// ---------------------------------------------------------------------------

Future<bool> _showHttpsWarning(
  BuildContext context,
  BaseUploader provider,
  SettingsService svc,
  AppLocalizations l10n,
) async {
  final baseUrl = _getBaseUrl(provider);
  // Try to fetch the server certificate in the background
  final certInfo = await _fetchCertificate(baseUrl);

  final result = await showDialog<_WarningResult>(
    context: context,
    builder: (ctx) => _InsecureWarningDialog(
      title: l10n.insecureWarningTitle,
      body: l10n.insecureWarningHttps(provider.providerName, baseUrl),
      showViewCert: certInfo != null,
      onViewCert: certInfo != null
          ? () => _showCertificateDialog(ctx, certInfo, l10n)
          : null,
    ),
  );
  return _handleResult(result, provider.providerId, svc);
}

String _getBaseUrl(BaseUploader provider) {
  if (provider is BaseHttpProvider) return provider.baseUrl;
  return '';
}

// ---------------------------------------------------------------------------
// Result handling
// ---------------------------------------------------------------------------

Future<bool> _handleResult(
    _WarningResult? result, String providerId, SettingsService svc) async {
  if (result == null) return false; // dismissed / back

  if (result.mute) {
    await svc.muteInsecureWarning(providerId);
  }

  return result.proceed;
}

// ---------------------------------------------------------------------------
// Certificate fetching
// ---------------------------------------------------------------------------

class _CertInfo {
  final String subject;
  final String issuer;
  final DateTime startValidity;
  final DateTime endValidity;
  final String? fingerprint;

  _CertInfo({
    required this.subject,
    required this.issuer,
    required this.startValidity,
    required this.endValidity,
    this.fingerprint,
  });
}

/// Attempts to connect to [baseUrl] over HTTPS and capture the server's
/// X.509 certificate via [HttpClient.badCertificateCallback].
///
/// Returns `null` if the server uses HTTP, has a valid certificate (callback
/// not triggered), or the connection fails entirely.
Future<_CertInfo?> _fetchCertificate(String baseUrl) async {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || uri.scheme != 'https') return null;

  try {
    X509Certificate? captured;
    final client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        captured = cert;
        return true; // allow to read the response
      };

    try {
      // Connect to the root (cheapest round-trip we can make)
      final request = await client.getUrl(
        uri.replace(path: '/', queryParameters: null, fragment: null),
      );
      final response = await request.close();
      await response.drain<List<int>>();
    } finally {
      client.close(force: true);
    }

    if (captured == null) return null; // valid cert, callback not called

    // captured is assigned inside a closure (badCertificateCallback) so
    // Dart cannot promote it to non-null despite the null check above.
    return _CertInfo(
      subject: captured!.subject,
      issuer: captured!.issuer,
      startValidity: captured!.startValidity,
      endValidity: captured!.endValidity,
      fingerprint: _sha1Hex(captured!.sha1),
    );
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Certificate detail dialog
// ---------------------------------------------------------------------------

void _showCertificateDialog(
  BuildContext context,
  _CertInfo cert,
  AppLocalizations l10n,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.certificateDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _certRow(l10n.certSubject, cert.subject),
            const SizedBox(height: 8),
            _certRow(l10n.certIssuer, cert.issuer),
            const SizedBox(height: 8),
            _certRow(
              l10n.certValidFrom,
              '${cert.startValidity.year}-'
              '${_pad2(cert.startValidity.month)}-'
              '${_pad2(cert.startValidity.day)}',
            ),
            const SizedBox(height: 8),
            _certRow(
              l10n.certValidUntil,
              '${cert.endValidity.year}-'
              '${_pad2(cert.endValidity.month)}-'
              '${_pad2(cert.endValidity.day)}',
            ),
            if (cert.fingerprint != null) ...[
              const SizedBox(height: 8),
              _certRow(l10n.certFingerprint, cert.fingerprint!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

Widget _certRow(String label, String value) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

String _pad2(int n) => n.toString().padLeft(2, '0');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _sha1Hex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
}

// ---------------------------------------------------------------------------
// Shared dialog
// ---------------------------------------------------------------------------

class _WarningResult {
  final bool proceed;
  final bool mute;

  const _WarningResult({required this.proceed, this.mute = false});
}

class _InsecureWarningDialog extends StatelessWidget {
  final String title;
  final String body;
  final bool showViewCert;
  final VoidCallback? onViewCert;

  const _InsecureWarningDialog({
    required this.title,
    required this.body,
    required this.showViewCert,
    this.onViewCert,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(body),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _WarningResult(proceed: false)),
          child: Text(l10n.cancel),
        ),
        if (showViewCert && onViewCert != null) ...[
          TextButton(
            onPressed: onViewCert,
            child: Text(l10n.viewCertificate),
          ),
        ],
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const _WarningResult(proceed: true)),
          child: Text(l10n.proceedAnyway),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            const _WarningResult(proceed: true, mute: true),
          ),
          child: Text(l10n.dontShowAgain),
        ),
      ],
    );
  }
}
