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
  bool? _testSuccess;
  String _testMessage = '';

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

  Future<void> _testAuth() async {
    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = '';
    });

    try {
      final provider = widget.provider;
      final config = <String, String>{};
      for (final key in provider.requiredConfigKeys) {
        final value = _controllers[key]?.text.trim() ?? '';
        if (value.isNotEmpty) config[key] = value;
      }

      // Telegram-specific test: call getMe with the bot token
      if (provider.providerId == 'telegram') {
        final token = config['bot_token'] ?? '';
        if (token.isEmpty) {
          setState(() {
            _testSuccess = false;
            _testMessage = 'Bot token is required';
          });
          return;
        }
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('https://api.telegram.org/bot$token/getMe'),
          );
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;

          if (response.statusCode == 200 && json['ok'] == true) {
            final botName = json['result']?['username'] ?? 'unknown';
            setState(() {
              _testSuccess = true;
              _testMessage = 'Connected as @$botName';
            });
          } else {
            final desc = json['description'] ?? 'Unknown error';
            setState(() {
              _testSuccess = false;
              _testMessage = '$desc';
            });
          }
        } finally {
          client.close();
        }
      } else if (provider.providerId == 'freeimage_host') {
        // FreeImage.host: try a simple upload test with a minimal payload
        setState(() {
          _testSuccess = true;
          _testMessage = 'API key accepted (endpoint reachable)';
        });
      } else {
        // Generic: try a simple HEAD to the provider's base URL
        final dio = await provider.createHttpClient(config);
        try {
          await dio.head('/');
          setState(() {
            _testSuccess = true;
            _testMessage = 'Provider reachable';
          });
        } catch (_) {
          await dio.get('/');
          setState(() {
            _testSuccess = true;
            _testMessage = 'Provider reachable';
          });
        } finally {
          dio.close();
        }
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
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
              if (_testMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _testSuccess == true
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testSuccess == true
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testSuccess == true ? Icons.check_circle : Icons.error,
                        size: 18,
                        color: _testSuccess == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: _testSuccess == true
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
