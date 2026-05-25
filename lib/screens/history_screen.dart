import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config_provider.dart';
import '../core/format.dart';
import '../core/history_service.dart';
import '../core/interfaces/uploader.dart';
import '../core/registry.dart';
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
    final mbInstances = ProviderRegistry.all
        .where((p) => p.providerId.startsWith('matterbridge'))
        .toList();

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (records) {
        if (records.isEmpty) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(l10n.historyEmpty,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Column(
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
                          Clipboard.setData(
                              ClipboardData(text: hr.record.url!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.urlCopiedToClipboard)),
                          );
                        }
                      },
                      onMatterbridge:
                          mbInstances.isNotEmpty && hr.record.url != null
                              ? () => _shareViaMatterbridge(
                                  context, ref, hr.record.url!,
                                  fileName: hr.record.fileName,
                                  providerName: hr.record.providerName)
                              : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryRecord record;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback? onMatterbridge;

  const _HistoryTile({
    required this.record,
    required this.onDelete,
    required this.onCopy,
    this.onMatterbridge,
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
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
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
              if (onMatterbridge != null && r.url != null)
                IconButton(
                  icon: const Icon(Icons.cell_tower, size: 18),
                  onPressed: onMatterbridge,
                  tooltip: l10n.matterbridgeSend,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _shareViaMatterbridge(
    BuildContext context, WidgetRef ref, String url,
    {String? fileName, String? providerName}) async {
  final instances = ProviderRegistry.all
      .where((p) => p.providerId.startsWith('matterbridge'))
      .toList();
  if (instances.isEmpty) return;

  BaseUploader? chosen;
  if (instances.length == 1) {
    chosen = instances.first;
  } else {
    final mbL10n = AppLocalizations.of(context);
    chosen = await showDialog<BaseUploader>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mbL10n.matterbridgeSend),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: instances
              .map((p) => ListTile(
                    dense: true,
                    title: Text(p.providerName),
                    onTap: () => Navigator.pop(ctx, p),
                  ))
              .toList(),
        ),
      ),
    );
  }
  if (chosen == null) return;

  try {
    final config =
        await ref.read(providerConfigProvider(chosen.providerId).future);
    final gateway = config['mb_gateway'] ?? '';
    final serverUrl = (config['mb_url'] ?? '').trim();
    final token = (config['mb_token'] ?? '').trim();
    if (gateway.isEmpty || serverUrl.isEmpty || token.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matterbridge not fully configured')),
        );
      }
      return;
    }

    // Resolve message template the same way upload does
    var message = config['message_text'] ?? config['message_template'] ?? '';
    if (message.isEmpty) {
      message = url;
    } else {
      message = message
          .replaceAll('{url}', url)
          .replaceAll('{filename}', fileName ?? 'file')
          .replaceAll('{provider}', providerName ?? '');
    }

    final dio = Dio();
    try {
      final response = await dio.post(
        '${serverUrl.replaceAll(RegExp(r'/$'), '')}/api/message',
        data: {'text': message, 'gateway': gateway},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      dio.close();
      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sent to ${chosen.providerName}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Matterbridge error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      dio.close();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  } catch (_) {}
}
