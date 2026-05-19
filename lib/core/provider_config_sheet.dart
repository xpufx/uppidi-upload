import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'interfaces/uploader.dart';
import 'settings_service.dart';

/// Shows a configuration dialog/sheet for a provider that requires
/// authentication credentials (e.g. bot tokens, API keys).
///
/// Returns `true` if the user saved changes, `false` if cancelled.
Future<bool> showProviderConfigDialog(
  BuildContext context,
  WidgetRef ref,
  BaseUploader provider,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ProviderConfigDialog(provider: provider),
  );
  return result ?? false;
}

class _ProviderConfigDialog extends ConsumerStatefulWidget {
  final BaseUploader provider;

  const _ProviderConfigDialog({required this.provider});

  @override
  ConsumerState<_ProviderConfigDialog> createState() =>
      _ProviderConfigDialogState();
}

class _ProviderConfigDialogState extends ConsumerState<_ProviderConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final key in widget.provider.requiredConfigKeys) {
      _controllers[key] = TextEditingController();
    }
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final svc = ref.read(settingsServiceProvider);
    for (final key in widget.provider.requiredConfigKeys) {
      final value = await svc.get(
        svc.providerKey(widget.provider.providerId, key),
      );
      if (mounted && _controllers[key] != null) {
        _controllers[key]!.text = value ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = widget.provider.configLabels;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.vpn_key_outlined,
              size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.provider.providerName} ${l10n.settings}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.providerConfigDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.provider.requiredConfigKeys.map((key) {
                final label = labels[key] ?? key;
                final isSecret = key.toLowerCase().contains('token') ||
                    key.toLowerCase().contains('key') ||
                    key.toLowerCase().contains('secret');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers[key],
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText:
                          isSecret ? l10n.providerConfigSecretHint : null,
                    ),
                    obscureText: isSecret,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.providerConfigRequired;
                      }
                      return null;
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isSaving = true);
                  try {
                    final svc = ref.read(settingsServiceProvider);
                    for (final key in widget.provider.requiredConfigKeys) {
                      final value = _controllers[key]?.text.trim() ?? '';
                      if (value.isNotEmpty) {
                        await svc.set(
                          svc.providerKey(widget.provider.providerId, key),
                          value,
                        );
                      } else {
                        await svc.remove(
                          svc.providerKey(widget.provider.providerId, key),
                        );
                      }
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.providerConfigSaved(
                                widget.provider.providerName),
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Checks whether a provider's required config keys have all been set.
Future<bool> isProviderConfigured(WidgetRef ref, BaseUploader provider) async {
  final svc = ref.read(settingsServiceProvider);
  for (final key in provider.requiredConfigKeys) {
    final value = await svc.get(svc.providerKey(provider.providerId, key));
    if (value == null || value.trim().isEmpty) {
      return false;
    }
  }
  return true;
}
