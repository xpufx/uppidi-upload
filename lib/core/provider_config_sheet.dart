import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import 'interfaces/uploader.dart';

final _secure = FlutterSecureStorage();

String _configKey(String providerId, String key) =>
    'provider_config_${providerId}_$key';

class _TestStep {
  final String label;
  final bool ok;
  final String detail;
  const _TestStep(this.label, this.ok, this.detail);
}

/// Resolves a config field label to a localized string.
String _resolveCfgLabel(AppLocalizations l10n, String raw) {
  return switch (raw) {
    'Bot Token' => l10n.configLabelBotToken,
    'Chat ID' => l10n.configLabelChatId,
    _ => raw,
  };
}

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
  bool _isTesting = false;

  /// Each test step: (label, ok?, detail).
  final List<_TestStep> _testSteps = [];

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
    for (final key in widget.provider.requiredConfigKeys) {
      final value = await _secure.read(
        key: _configKey(widget.provider.providerId, key),
      );
      if (mounted && _controllers[key] != null) {
        _controllers[key]!.text = value ?? '';
      }
    }
  }

  /// Runs a multi-step auth test. For Telegram: step 1 = bot token (getMe),
  /// step 2 = chat access (getChat). For other providers: simple connectivity.
  Future<void> _testAuth() async {
    final steps = <_TestStep>[];
    setState(() {
      _isTesting = true;
      _testSteps.clear();
    });

    try {
      final provider = widget.provider;
      final config = <String, String>{};
      for (final key in provider.requiredConfigKeys) {
        final value = _controllers[key]?.text.trim() ?? '';
        if (value.isNotEmpty) config[key] = value;
      }

      final client = HttpClient();
      try {
        if (provider.providerId == 'telegram') {
          // ── Step 1: validate bot_token via getMe ──
          final token = config['bot_token'] ?? '';
          var meRequest = await client.getUrl(
            Uri.parse('https://api.telegram.org/bot$token/getMe'),
          );
          var meResponse = await meRequest.close();
          var meBody = await meResponse.transform(utf8.decoder).join();
          var meJson = jsonDecode(meBody) as Map<String, dynamic>;

          if (meResponse.statusCode == 200 && meJson['ok'] == true) {
            final botName = meJson['result']?['username'] ?? 'unknown';
            steps.add(_TestStep('Bot token', true, 'Connected as @$botName'));
          } else {
            steps.add(_TestStep(
                'Bot token', false, meJson['description'] ?? 'Invalid'));
            setState(() {
              _testSteps
                ..clear()
                ..addAll(steps);
            });
            return; // no point checking chat if token fails
          }

          // ── Step 2: verify chat_id via getChat ──
          final chatId = config['chat_id'] ?? '';
          if (chatId.isEmpty) {
            steps.add(const _TestStep('Chat ID', false, 'Not provided'));
          } else {
            var chatRequest = await client.getUrl(Uri.parse(
                'https://api.telegram.org/bot$token/getChat?chat_id=$chatId'));
            var chatResponse = await chatRequest.close();
            var chatBody = await chatResponse.transform(utf8.decoder).join();
            var chatJson = jsonDecode(chatBody) as Map<String, dynamic>;

            if (chatResponse.statusCode == 200 && chatJson['ok'] == true) {
              final title = chatJson['result']?['title'] ??
                  chatJson['result']?['first_name'] ??
                  'found';
              steps.add(_TestStep('Chat ID', true, 'Chat "$title" accessible'));
            } else {
              steps.add(_TestStep(
                  'Chat ID', false, chatJson['description'] ?? 'Not found'));
            }
          }
        } else {
          // Generic: try a simple HEAD/GET to the provider's base URL
          final dio = await provider.createHttpClient(config);
          try {
            await dio.head('/');
            steps.add(const _TestStep('Connectivity', true, 'Reachable'));
          } catch (_) {
            try {
              await dio.get('/');
              steps.add(const _TestStep('Connectivity', true, 'Reachable'));
            } catch (e2) {
              steps.add(_TestStep('Connectivity', false, '$e2'));
            }
          } finally {
            dio.close();
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      steps.add(_TestStep('Error', false, e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _testSteps
            ..clear()
            ..addAll(steps);
          _isTesting = false;
        });
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
                final label = _resolveCfgLabel(l10n, labels[key] ?? key);
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
              ..._testSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          step.ok ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: step.ok ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text('${step.label}: ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: step.ok
                                    ? Colors.green.shade800
                                    : Colors.red.shade800)),
                        Expanded(
                          child: Text(step.detail,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: step.ok
                                      ? Colors.green.shade700
                                      : Colors.red.shade700)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        OutlinedButton.icon(
          onPressed: _isTesting || _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  await _testAuth();
                },
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_find, size: 18),
          label: Text('Test'),
        ),
        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isSaving = true);
                  try {
                    final store = _secure;
                    for (final key in widget.provider.requiredConfigKeys) {
                      final value = _controllers[key]?.text.trim() ?? '';
                      final skey = _configKey(widget.provider.providerId, key);
                      if (value.isNotEmpty) {
                        await store.write(key: skey, value: value);
                      } else {
                        await store.delete(key: skey);
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
  for (final key in provider.requiredConfigKeys) {
    final value = await _secure.read(
      key: _configKey(provider.providerId, key),
    );
    if (value == null || value.trim().isEmpty) {
      return false;
    }
  }
  return true;
}
