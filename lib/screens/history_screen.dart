import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/history_service.dart';
import '../core/share_message_dialog.dart';
import '../l10n/app_localizations.dart';
import '../widgets/provider_favicon.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(uploadHistoryProvider);
    final svc = ref.read(historyServiceProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(l10n.historyEmpty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade500,
                        )),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(l10n.historyRecords(records.length),
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: Text(l10n.historyClearAll),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.clearHistory),
                          content: Text(l10n.historyClearConfirm),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l10n.cancel)),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.ok)),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await svc.clearAll();
                        ref.invalidate(uploadHistoryProvider);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 0),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final hr = records[index];
                  return _HistoryTile(
                    record: hr,
                    onDelete: () {
                      svc.delete(hr.key);
                      ref.invalidate(uploadHistoryProvider);
                    },
                    onCopy: () {
                      if (hr.record.url != null) {
                        Clipboard.setData(ClipboardData(text: hr.record.url!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryRecord record;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _HistoryTile({
    required this.record,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = record.record;

    return Dismissible(
      key: ValueKey(record.key),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: r.thumbnailBytes != null && r.success
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.memory(
                      r.thumbnailBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        r.success ? Icons.check_circle : Icons.error,
                        color: r.success ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                )
              : Icon(
                  r.success ? Icons.check_circle : Icons.error,
                  color: r.success ? Colors.green : Colors.red,
                ),
          title: Text(r.fileName, overflow: TextOverflow.ellipsis),
          onLongPress: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(r.fileName),
                content: Text(l10n.deleteThisRecord),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.ok)),
                ],
              ),
            );
            if (confirmed == true) onDelete();
          },
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProviderFavicon(providerId: r.providerId, size: 14),
                  const SizedBox(width: 4),
                  Text(r.providerName, style: const TextStyle(fontSize: 12)),
                ],
              ),
              if (r.url != null)
                Text(r.url!,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              if (r.expiry != null)
                Text(
                  l10n.selectedExpiry(r.expiry!),
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              Text(
                  formatTime(
                    r.completedAt,
                    justNow: l10n.timeJustNow,
                    minutesAgo: (m) => l10n.timeMinutesAgo(m),
                    hoursAgo: (h) => l10n.timeHoursAgo(h),
                  ),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.url != null)
                IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: () async {
                      final uri = Uri.tryParse(r.url!);
                      if (uri != null)
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                    },
                    tooltip: l10n.openInBrowser),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: onCopy,
                tooltip: l10n.urlCopiedToClipboard,
              ),
              if (r.url != null)
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ShareMessageDialog(
                        url: r.url!,
                        providerName: r.providerName,
                        fileName: r.fileName,
                      ),
                    );
                  },
                  tooltip: l10n.shareUrl,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
