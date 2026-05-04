import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/share_template.dart';
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
  final String _template = 'Shared via %appname: %url';

  @override
  void initState() {
    super.initState();
    _controller.text = ShareTemplate.expand(
      _template,
      url: widget.url,
      provider: widget.providerName,
      date: DateTime.now(),
      filename: widget.fileName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleShowTemplateInfo() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.templateVars),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ShareTemplate.variables.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(ctx).style,
                    children: [
                      TextSpan(text: e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' — ${e.value}'),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              Text(l10n.templateExamples, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...ShareTemplate.examples.map((ex) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(ex, style: const TextStyle(fontStyle: FontStyle.italic)),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok)),
        ],
      ),
    );
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
          Text(widget.url, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
            Row(
              children: [
                Text(l10n.customizeMessage, style: const TextStyle(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 16),
                  onPressed: handleShowTemplateInfo,
                  tooltip: l10n.templateVars,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
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
            final customMsg = _includeMessage ? _controller.text : null;
            final text = customMsg ?? widget.url;
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