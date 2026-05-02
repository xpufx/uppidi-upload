import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/registry.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final uploadState = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);
    final provider = uploadState.selectedProviderIndex < ProviderRegistry.all.length
        ? ProviderRegistry.all[uploadState.selectedProviderIndex]
        : null;
    final webUnsupported = kIsWeb && provider != null && !provider.supportsWeb;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<int>(
            value: uploadState.selectedProviderIndex,
            isExpanded: true,
            onChanged: uploadState.isUploading
                ? null
                : (index) {
                    if (index != null) notifier.setProvider(index);
                  },
            items: ProviderRegistry.all.asMap().entries.map((entry) {
              final p = entry.value;
              final online = !kIsWeb || p.supportsWeb;
              return DropdownMenuItem(
                value: entry.key,
                enabled: online,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 20,
                      color: online
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      p.providerName,
                      style: online ? null : TextStyle(color: Theme.of(context).disabledColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${p.providerId})',
                      style: (online
                              ? Theme.of(context).textTheme.bodySmall
                              : Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ))
                          ?.copyWith(
                        color: online
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (webUnsupported) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.providerWebNotSupported,
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: uploadState.isUploading || webUnsupported ? null : notifier.pickAndUpload,
            child: Text(
              uploadState.isUploading ? l10n.uploading : l10n.pickAndUpload,
            ),
          ),
          if (uploadState.isUploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: uploadState.progress),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: notifier.cancelUpload,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.cancelUpload),
            ),
          ],
          if (uploadState.lastError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                '${l10n.error}: ${uploadState.lastError}',
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: uploadState.results.length,
              itemBuilder: (context, index) {
                final result = uploadState.results[index];
                return _UploadResultTile(result: result);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadResultTile extends StatelessWidget {
  final dynamic result;
  const _UploadResultTile({required this.result});

  static void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.urlCopiedToClipboard)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final success = result.success as bool;
    final url = result.url as String?;

    return ListTile(
      leading: Icon(
        success ? Icons.check_circle : Icons.error,
        color: success ? Colors.green : Colors.red,
      ),
      title: Text(success ? l10n.success : l10n.failed),
      subtitle: success && url != null
          ? Row(
              children: [
                Expanded(
                  child: SelectableText(
                    url,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    onTap: () => _copyUrl(context, url),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyUrl(context, url),
                  tooltip: l10n.urlCopiedToClipboard,
                ),
              ],
            )
          : Text(
              success
                  ? '${l10n.success}: ${result.statusCode}'
                  : '${result.errorMessage ?? l10n.unknownError} (${result.statusCode})',
            ),
    );
  }
}
