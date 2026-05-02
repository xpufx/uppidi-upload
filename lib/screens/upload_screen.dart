import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
          if (webUnsupported) const _WebWarning(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: uploadState is UploadInProgress || webUnsupported
                ? null
                : notifier.pickAndUpload,
            child: Text(
              uploadState is UploadInProgress ? l10n.uploading : l10n.pickAndUpload,
            ),
          ),
          switch (uploadState) {
            UploadInProgress(progress: final p, cancelToken: final _) => _ProgressSection(
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
              Icon(Icons.cloud_upload, size: 20,
                color: online ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Text(p.providerName,
                style: online ? null : TextStyle(color: Theme.of(context).disabledColor)),
              const SizedBox(width: 4),
              Text('(${p.providerId})',
                style: (online
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).disabledColor))
                    ?.copyWith(color: online ? Theme.of(context).colorScheme.outline : Theme.of(context).disabledColor)),
            ],
          ),
        );
      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.shade100,
        child: Text(
          '${l10n.error}: $error',
          style: TextStyle(color: Colors.red.shade800),
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
