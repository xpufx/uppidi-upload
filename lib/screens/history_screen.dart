import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/history_service.dart';
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
          leading: Icon(
            r.success ? Icons.check_circle : Icons.error,
            color: r.success ? Colors.green : Colors.red,
          ),
          title: Text(r.fileName, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.providerName, style: const TextStyle(fontSize: 12)),
              if (r.url != null)
                Text(r.url!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              Text(formatTime(r.completedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
}
