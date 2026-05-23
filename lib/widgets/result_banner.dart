import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/interfaces/uploader.dart';
import '../core/models/upload_result.dart';
import '../core/share_message_dialog.dart';
import '../core/version.dart';
import '../l10n/app_localizations.dart';

/// Shows the result of an upload — success URL with share/copy/open actions,
/// or an error message with retry and debug info.
class ResultBanner extends StatefulWidget {
  final String? url;
  final String? errorMessage;
  final String? fileName;
  final int fileSizeBytes;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadResult? lastResult;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const ResultBanner({
    super.key,
    this.url,
    this.errorMessage,
    this.fileName,
    this.fileSizeBytes = 0,
    this.mimeType,
    this.fileBytes,
    this.provider,
    this.lastResult,
    this.onRetry,
    this.onCancel,
  });

  @override
  State<ResultBanner> createState() => _ResultBannerState();
}

class _ResultBannerState extends State<ResultBanner> {
  String _errorText(AppLocalizations l10n) {
    final msg = widget.errorMessage;
    if (msg == null) return '';
    return switch (msg) {
      'genericError' => l10n.genericError,
      'errorSessionExpired' => l10n.errorSessionExpired,
      'errorFileTooLarge' => l10n.errorFileTooLarge,
      'errorInvalidUploader' => l10n.errorInvalidUploader,
      'failedToReadFile' => l10n.failedToReadFile,
      'noProvidersConfigured' => l10n.noProvidersConfigured,
      'connectionTimedOut' => l10n.connectionTimedOut,
      'errorConnectionFailed' => l10n.errorConnectionFailed,
      'invalidMimeType' => l10n.invalidMimeType,
      'fileSystemError' => l10n.fileSystemError,
      'uploadCancelled' => l10n.uploadCancelled,
      'telegramErrorChatNotFound' => l10n.telegramErrorChatNotFound,
      'telegramErrorBotBlocked' => l10n.telegramErrorBotBlocked,
      'telegramErrorNoRights' => l10n.telegramErrorNoRights,
      'telegramErrorInvalidToken' => l10n.telegramErrorInvalidToken,
      _ => msg,
    };
  }

  void _showDebugInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buffer = StringBuffer();
    final result = widget.lastResult;
    final p = widget.provider;

    buffer.writeln('=== PROVIDER ===');
    buffer.writeln('Name: ${p?.providerName ?? "unknown"}');
    buffer.writeln('ID: ${p?.providerId ?? "?"}');
    buffer.writeln('=== FILE ===');
    buffer.writeln('Name: ${widget.fileName ?? "none"}');
    buffer.writeln(
        'Size: ${formatSize(widget.fileSizeBytes)} (${widget.fileSizeBytes} bytes)');
    buffer.writeln('MIME: ${widget.mimeType ?? "unknown"}');
    buffer.writeln('=== ERROR ===');
    buffer.writeln('Message: ${widget.errorMessage ?? "none"}');
    buffer.writeln('Raw Error: ${result?.rawError ?? "none"}');
    buffer.writeln('Status Code: ${result?.statusCode ?? "none"}');
    buffer.writeln(
        'Timestamp: ${result?.completedAt.toIso8601String() ?? "none"}');
    if (result?.stackTrace != null) {
      buffer.writeln('Stack Trace: ${result!.stackTrace}');
    }
    buffer.writeln('Git Hash: $gitHash');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('Platform Version: ${Platform.operatingSystemVersion}');

    final text = buffer.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, size: 18),
            const SizedBox(width: 8),
            Text(l10n.debugInfo),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(text,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => SharePlus.instance.share(ShareParams(text: text)),
            icon: const Icon(Icons.share, size: 16),
            label: Text(l10n.share),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.copiedToClipboard)),
              );
            },
            child: Text(l10n.copyAll),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(hasError ? Icons.error : Icons.check_circle,
                  color: hasError ? Colors.red : Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(hasError ? l10n.uploadFailed : l10n.uploadComplete),
            ],
          ),
          if (hasError && widget.errorMessage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(_errorText(l10n),
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.bug_report, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: l10n.debugInfoTooltip,
                  onPressed: () => _showDebugInfo(context),
                ),
              ],
            ),
          ],
          if (widget.url != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    widget.url!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () async {
                    final uri = Uri.tryParse(widget.url!);
                    if (uri != null) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  tooltip: l10n.openInBrowser,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.url!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                    );
                  },
                  tooltip: l10n.urlCopiedToClipboard,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ShareMessageDialog(
                        url: widget.url!,
                        providerName: widget.provider?.providerName,
                        fileName: widget.fileName,
                      ),
                    );
                  },
                  tooltip: l10n.shareUrl,
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onRetry != null)
                OutlinedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.retry),
                ),
              if (widget.onRetry != null) const SizedBox(width: 8),
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, size: 16),
                label: Text(l10n.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
