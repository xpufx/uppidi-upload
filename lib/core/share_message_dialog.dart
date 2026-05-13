import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';

class ShareMessageDialog extends ConsumerStatefulWidget {
  final String url;
  final String? providerName;
  final String? fileName;

  const ShareMessageDialog({
    super.key,
    required this.url,
    this.providerName,
    this.fileName,
  });

  @override
  ConsumerState<ShareMessageDialog> createState() => _ShareMessageDialogState();
}

class _ShareMessageDialogState extends ConsumerState<ShareMessageDialog> {
  bool _includeMessage = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedMessage();
  }

  Future<void> _loadSavedMessage() async {
    final svc = ref.read(settingsServiceProvider);
    final saved = await svc.get(SettingsService.shareMessageKey);
    if (mounted) {
      setState(() {
        _controller.text = saved ?? '';
      });
    }
  }

  Future<void> _saveMessage(String text) async {
    final svc = ref.read(settingsServiceProvider);
    if (text.trim().isEmpty) {
      await svc.remove(SettingsService.shareMessageKey);
    } else {
      await svc.set(SettingsService.shareMessageKey, text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.shareLink),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.url,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.includeMessage),
            value: _includeMessage,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _includeMessage = v),
          ),
          if (_includeMessage) ...[
            const SizedBox(height: 8),
            Text(l10n.customizeMessage, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _saveMessage,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            final custom = _controller.text.trim();
            final text = _includeMessage && custom.isNotEmpty
                ? '$custom\n${widget.url}'
                : widget.url;
            SharePlus.instance.share(ShareParams(text: text));
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.share, size: 16),
          label: Text(l10n.shareUrl),
        ),
      ],
    );
  }
}
