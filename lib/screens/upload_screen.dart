import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

IconData _providerIcon(String id) => switch (id) {
      'httpbin' => Icons.science_outlined,
      'catbox' => Icons.folder_outlined,
      'tmpfilelink' => Icons.link,
      'uguu_uguu_se' || 'uguu_safe_uguu_se' => Icons.burst_mode_outlined,
      'freeimage_freeimage_host' => Icons.image_outlined,
      _ => Icons.cloud_upload,
    };

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final providers = uploadState.providers;
    final provider = uploadState.selectedProviderIndex < providers.length
        ? providers[uploadState.selectedProviderIndex]
        : null;
    final webUnsupported = kIsWeb && provider != null && !provider.supportsWeb;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProviderDropdown(
            selectedIndex: uploadState.selectedProviderIndex,
            providers: providers,
            isUploading: uploadState is UploadInProgress,
            onChanged: (i) {
              if (i != null) notifier.setProvider(i);
            },
          ),
          if (provider != null) _ProviderInfo(provider: provider),
          if (webUnsupported) const _WebWarning(),
          switch (uploadState) {
            UploadFileSelected(fileName: final n, fileSizeBytes: final s, mimeType: final m) =>
              _FileInfoBanner(fileName: n, fileSize: s, mimeType: m, provider: provider),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 16),
          switch (uploadState) {
            UploadIdle() || UploadFileSelected() => _PickAndUploadButton(notifier: notifier, provider: provider),
            _ => const SizedBox.shrink(),
          },
          switch (uploadState) {
            UploadInProgress(progress: final p) => _ProgressSection(
                progress: p,
                onCancel: notifier.cancelUpload,
              ),
            UploadCompleted(errorMessage: final e) when e != null => _ErrorBanner(error: e),
            UploadCompleted(isSuccess: final ok) => _ResultBanner(success: ok),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 16),
          Expanded(child: _ResultList(results: uploadState.results)),
        ],
      ),
    );
  }
}

class _ProviderDropdown extends StatelessWidget {
  final int selectedIndex;
  final List<dynamic> providers;
  final bool isUploading;
  final ValueChanged<int?> onChanged;

  const _ProviderDropdown({
    required this.selectedIndex,
    required this.providers,
    required this.isUploading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedIndex,
      isExpanded: true,
      onChanged: isUploading ? null : onChanged,
      items: providers.asMap().entries.map((entry) {
        final p = entry.value;
        final online = !kIsWeb || p.supportsWeb;
        return DropdownMenuItem(
          value: entry.key,
          enabled: online,
          child: Row(
            children: [
              Icon(_providerIcon(p.providerId), size: 20,
                color: online ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Text(p.providerName,
                style: online ? null : TextStyle(color: Theme.of(context).disabledColor)),
              _metadataBadges(p.metadata),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Widget _metadataBadges(dynamic meta) {
  final chips = <Widget>[];

  if (meta.fileSizeLabel is String && (meta.fileSizeLabel as String).isNotEmpty) {
    chips.add(_buildBadge(meta.fileSizeLabel as String));
  }
  if (meta.allowedMimeTypes != null) {
    chips.add(_buildBadge(meta.mimeTypeLabel as String));
  }
  if (meta.expiryInfo is String && (meta.expiryInfo as String).isNotEmpty) {
    chips.add(_buildBadge(meta.expiryInfo as String));
  }

  if (chips.isEmpty) return const SizedBox.shrink();

  return Row(mainAxisSize: MainAxisSize.min, children: chips);
}

Widget _buildBadge(String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue)),
    ),
  );
}

class _ProviderInfo extends StatelessWidget {
  final dynamic provider;
  const _ProviderInfo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final meta = provider.metadata;
    final infos = <String>[];

    if (meta.fileSizeLabel is String && (meta.fileSizeLabel as String).isNotEmpty) {
      infos.add('Max file size: ${meta.fileSizeLabel}');
    }
    if (meta.expiryInfo is String && (meta.expiryInfo as String).isNotEmpty) {
      infos.add(meta.expiryInfo as String);
    }
    if (meta.allowedMimeTypes != null) {
      infos.add(meta.mimeTypeLabel as String);
    }

    if (infos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: infos.map((info) => Text(info,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        )).toList(),
      ),
    );
  }
}

class _PickAndUploadButton extends ConsumerWidget {
  final dynamic notifier;
  final dynamic provider;

  const _PickAndUploadButton({required this.notifier, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scaffoldContext = context;
    return ElevatedButton(
      onPressed: () async {
        final needsApproval = await ref.read(settingsServiceProvider).needsApprovalBeforeUpload();
        if (needsApproval && scaffoldContext.mounted) {
          final name = provider?.providerName ?? 'this provider';
          final confirmed = await showDialog<bool>(
            context: scaffoldContext,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.approveUploadTitle),
              content: Text(l10n.approveUploadMessage(name)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok)),
              ],
            ),
          );
          if (confirmed != true) return;
        }
        notifier.pickAndUpload();
      },
      child: Text(l10n.pickAndUpload),
    );
  }
}

class _FileInfoBanner extends StatelessWidget {
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final dynamic provider;

  const _FileInfoBanner({
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final warnings = <Widget>[];
    final meta = provider?.metadata;

    if (meta?.allowedMimeTypes != null && mimeType != null) {
      if (!meta.allowsMimeType(mimeType)) {
        warnings.add(_warningRow('Provider only accepts: ${meta.mimeTypeLabel}'));
      }
    }

    if (meta?.maxFileSizeBytes != null && fileSize > meta.maxFileSizeBytes) {
      warnings.add(_warningRow('File exceeds ${meta.fileSizeLabel} limit'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(fileName, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(formatSize(fileSize),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              if (mimeType != null) ...[
                const SizedBox(width: 8),
                Text(mimeType!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ],
          ),
          ...warnings,
        ],
      ),
    );
  }

  Widget _warningRow(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
          const SizedBox(width: 4),
          Expanded(child: Text(msg,
            style: const TextStyle(fontSize: 12, color: Colors.orange))),
        ],
      ),
    );
  }
}

class _WebWarning extends StatelessWidget {
  const _WebWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.orange.shade100,
        child: Row(
          children: [
            const Icon(Icons.warning_amber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.providerWebNotSupported,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final VoidCallback onCancel;

  const _ProgressSection({required this.progress, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 16),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(l10n.cancelUpload),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  static String _translate(AppLocalizations l10n, String key) {
    return switch (key) {
      'genericError' => l10n.genericError,
      'errorSessionExpired' => l10n.errorSessionExpired,
      'errorFileTooLarge' => l10n.errorFileTooLarge,
      'errorConnectionFailed' => l10n.errorConnectionFailed,
      'uploadCancelled' => l10n.uploadCancelled,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.shade100,
        child: Row(
          children: [
            Text('${l10n.error}: ',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600)),
            Expanded(child: Text(_translate(l10n, error),
              style: TextStyle(color: Colors.red.shade800))),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool success;

  const _ResultBanner({required this.success});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Text(success ? l10n.uploadComplete : l10n.uploadFailed),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<dynamic> results;

  const _ResultList({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _ResultTile(result: results[index]),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final dynamic result;
  const _ResultTile({required this.result});

  static void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).urlCopiedToClipboard)),
    );
  }

  static void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final success = result.success as bool;
    final url = result.url as String?;

    return ListTile(
      leading: Icon(success ? Icons.check_circle : Icons.error,
        color: success ? Colors.green : Colors.red),
      title: Text(success ? l10n.success : l10n.failed),
      subtitle: success && url != null
          ? Row(children: [
              Expanded(child: SelectableText(url,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                onTap: () => _copyUrl(context, url))),
              IconButton(icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: () => _openUrl(url),
                tooltip: l10n.openInBrowser),
              IconButton(icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyUrl(context, url),
                tooltip: l10n.urlCopiedToClipboard),
            ])
          : Text(success
              ? '${l10n.success}: ${result.statusCode}'
              : '${result.errorMessage ?? l10n.unknownError} (${result.statusCode})'),
    );
  }
}
