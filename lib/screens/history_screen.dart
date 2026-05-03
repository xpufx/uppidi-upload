import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/history_service.dart';
import '../core/models/upload_record.dart';
import '../l10n/app_localizations.dart';

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

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: records.length,
          itemBuilder: (context, index) => _HistoryTile(
            record: records[index],
            onDelete: () => svc.delete(index),
            onCopy: () {
              if (records[index].url != null) {
                Clipboard.setData(ClipboardData(text: records[index].url!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                );
              }
            },
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final UploadRecord record;
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

    return Dismissible(
      key: ValueKey('${record.completedAt.millisecondsSinceEpoch}_${record.fileName}'),
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
          leading: Icon(
            record.success ? Icons.check_circle : Icons.error,
            color: record.success ? Colors.green : Colors.red,
          ),
          title: Text(record.fileName, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.providerName, style: const TextStyle(fontSize: 12)),
              if (record.url != null)
                Text(record.url!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              Text(_formatTime(record.completedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
            tooltip: l10n.urlCopiedToClipboard,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
