import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';
import 'interfaces/uploader.dart';
import 'logging/log.dart';
import 'models/provider_instance.dart';
import 'registry.dart';

final _secure = FlutterSecureStorage();

String _configKey(String providerId, String key) =>
    'provider_config_${providerId}_$key';

/// ── Instance storage helpers ────────────────────────────────────────────

/// Metadata for a single provider instance.
@visibleForTesting
class ProviderInstanceMeta {
  final String id;
  final String name;
  const ProviderInstanceMeta({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory ProviderInstanceMeta.fromJson(Map<String, dynamic> json) =>
      ProviderInstanceMeta(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

/// Loads the list of instances for a provider. Returns an empty list if
/// no instances have been configured (caller creates a default).
Future<List<ProviderInstanceMeta>> loadProviderInstances(
    String providerId) async {
  final raw = await _secure.read(key: 'provider_instances_$providerId');
  if (raw == null) return [];
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => ProviderInstanceMeta.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Persists the instance list for a provider.
Future<void> saveProviderInstances(
    String providerId, List<ProviderInstanceMeta> instances) async {
  await _secure.write(
    key: 'provider_instances_$providerId',
    value: jsonEncode(instances.map((e) => e.toJson()).toList()),
  );
}

/// Deletes an instance: removes its config keys and removes it from the
/// instance list.
Future<void> deleteProviderInstance(
    String providerId, ProviderInstanceMeta instance,
    {required List<String> configKeys}) async {
  for (final key in configKeys) {
    await _secure.delete(key: _configKey('${providerId}__${instance.id}', key));
  }
  final remaining = (await loadProviderInstances(providerId))
      .where((i) => i.id != instance.id)
      .toList();
  if (remaining.isEmpty) {
    await _secure.delete(key: 'provider_instances_$providerId');
  } else {
    await saveProviderInstances(providerId, remaining);
  }
}

/// ── Config dialog ───────────────────────────────────────────────────────

/// Splits a providerId like `telegram__work` into (`telegram`, `work`).
/// For bare ids like `catbox` returns (`catbox`, `default`).
(String, String) _splitInstanceId(String providerId) {
  final parts = providerId.split('__');
  if (parts.length >= 2) {
    return (parts[0], parts.sublist(1).join('__'));
  }
  return (providerId, 'default');
}

class _TestStep {
  final String label;
  final bool ok;
  final String detail;
  final String? rawResponse;
  const _TestStep(this.label, this.ok, this.detail, {this.rawResponse});
}

/// Resolves a config field label to a localized string.
String _resolveCfgLabel(AppLocalizations l10n, String raw) {
  return switch (raw) {
    'Bot Token' => l10n.configLabelBotToken,
    'Chat ID' => l10n.configLabelChatId,
    'Send images as photos' => l10n.configLabelSendAsPhoto,
    'Server URL' => l10n.configLabelServerUrl,
    'Email' => l10n.configLabelEmail,
    'API Key' => l10n.configLabelApiKey,
    'Channel' => l10n.configLabelChannel,
    'Topic' => l10n.configLabelTopic,
    _ => raw,
  };
}

/// Shows the instance manager dialog for a provider that requires
/// authentication. Always shows the instance list — handles 0, 1, or
/// many instances with Add / Edit / Delete controls.
/// After saving, refreshes the provider registry immediately.
Future<bool> showProviderConfigDialog(
  BuildContext context,
  WidgetRef ref,
  BaseUploader provider,
) async {
  final baseId = provider.providerId.split('__').first;
  final base = ProviderRegistry.baseFor(provider.providerId);
  if (base == null) return false;

  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => _InstanceListDialog(
      providerId: baseId,
      baseProvider: base,
      ref: ref,
    ),
  );
  if (changed == true) {
    await ProviderRegistry.refresh(ref);
  }
  return changed ?? false;
}

/// Opens the config dialog directly for an existing [provider] instance,
/// skipping the instance list dialog. Saves, refreshes the registry,
/// and returns true if something changed.
Future<bool> showProviderEditDialog(
  BuildContext context,
  WidgetRef ref,
  ProviderInstance provider,
) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _ProviderConfigDialog(provider: provider),
  );
  if (saved == true) {
    await ProviderRegistry.refresh(ref);
  }
  return saved ?? false;
}

/// ── Instance list dialog ────────────────────────────────────────────────

class _InstanceListDialog extends ConsumerStatefulWidget {
  final String providerId;
  final BaseUploader baseProvider;
  final WidgetRef ref;
  const _InstanceListDialog({
    required this.providerId,
    required this.baseProvider,
    required this.ref,
  });

  @override
  ConsumerState<_InstanceListDialog> createState() =>
      _InstanceListDialogState();
}

class _InstanceListDialogState extends ConsumerState<_InstanceListDialog> {
  List<ProviderInstanceMeta> _instances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await loadProviderInstances(widget.providerId);
    if (mounted) {
      setState(() {
        _instances = list;
        _loading = false;
      });
    }
  }

  Future<void> _edit(ProviderInstanceMeta instance) async {
    final wrapped =
        ProviderInstance(widget.baseProvider, instance.id, instance.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProviderConfigDialog(provider: wrapped),
    );
    if (saved == true) _reload();
  }

  Future<void> _add() async {
    final types = ProviderRegistry.instanceTypes;
    if (types.isEmpty) return;

    // Always show the type picker so the user sees what they're adding.
    final l10n = AppLocalizations.of(context);
    final chosen = await showDialog<BaseUploader>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addProvider),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: types
              .map((t) => ListTile(
                    dense: true,
                    title: Text(t.providerName),
                    subtitle: t.instanceDescription != null
                        ? Text(t.instanceDescription!,
                            style: const TextStyle(fontSize: 12))
                        : null,
                    onTap: () => Navigator.pop(ctx, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen == null) return;

    final baseId = chosen.providerId;
    final instances = await loadProviderInstances(baseId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final instance = ProviderInstanceMeta(
        id: newId, name: '${chosen.providerName} ${instances.length + 1}');
    final wrapped = ProviderInstance(chosen, instance.id, instance.name);
    final saved = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => _ProviderConfigDialog(provider: wrapped),
    );
    if (saved == true) {
      await ProviderRegistry.refresh(ref);
      _reload();
    }
  }

  Future<void> _delete(ProviderInstanceMeta instance) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteInstanceTitle),
        content: Text(l10n.deleteInstanceConfirm(instance.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await deleteProviderInstance(widget.providerId, instance,
        configKeys: widget.baseProvider.requiredConfigKeys);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.myProviders),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _instances.isEmpty
                ? Center(
                    child: Text(l10n.noInstancesConfigured,
                        style: theme.textTheme.bodySmall))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _instances.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final inst = _instances[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline, size: 20),
                        title: Text(inst.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _delete(inst),
                        ),
                        onTap: () => _edit(inst),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add, size: 16),
          label: Text(l10n.addProvider),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}

/// ── Instance edit dialog ────────────────────────────────────────────────

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
  final Map<String, bool> _checkboxValues = {};
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();
  final _log = Log('ProviderConfig');
  bool _isSaving = false;
  bool _isTesting = false;
  String? _validationError;

  /// Each test step: (label, ok?, detail).
  final List<_TestStep> _testSteps = [];

  // Zulip resources fetched from API (populated after test)
  List<String> _zulipStreams = [];
  List<Map<String, dynamic>> _zulipUsers = [];
  bool _loadingResources = false;

  bool get _isZulip => widget.provider.providerId.split('__').first == 'zulip';

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final key in widget.provider.requiredConfigKeys) {
      _controllers[key] = TextEditingController();
    }
    for (final key in widget.provider.optionalTextConfigKeys) {
      _controllers[key] = TextEditingController();
    }
    for (final key in widget.provider.optionalConfigKeys) {
      _checkboxValues[key] = false;
    }
    _nameController.text = widget.provider.providerName;
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final (baseId, instanceId) = _splitInstanceId(widget.provider.providerId);
    for (final key in widget.provider.requiredConfigKeys) {
      final value = await _secure.read(
        key: _configKey(widget.provider.providerId, key),
      );
      if (mounted && _controllers[key] != null) {
        _controllers[key]!.text = value ?? '';
      }
    }
    for (final key in widget.provider.optionalConfigKeys) {
      final value = await _secure.read(
        key: _configKey(widget.provider.providerId, key),
      );
      if (mounted) {
        _checkboxValues[key] = value == 'true';
      }
    }
    // Load optional text config keys
    for (final key in widget.provider.optionalTextConfigKeys) {
      final value = await _secure.read(
        key: _configKey(widget.provider.providerId, key),
      );
      if (mounted && _controllers[key] != null) {
        _controllers[key]!.text = value ?? '';
      }
    }
    // Load instance name from metadata if available
    if (mounted) {
      final instances = await loadProviderInstances(baseId);
      final match = instances.where((i) => i.id == instanceId);
      if (match.isNotEmpty) {
        _nameController.text = match.first.name;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _nameController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _scrollToTestSteps() {
    if (_contentScrollController.hasClients) {
      _contentScrollController.animateTo(
        _contentScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
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
        if (provider.providerId.split('__').first == 'telegram') {
          // ── Telegram test steps ──
          final token = config['bot_token'] ?? '';
          var meRequest = await client.getUrl(
            Uri.parse('https://api.telegram.org/bot$token/getMe'),
          );
          var meResponse = await meRequest.close();
          var meBody = await meResponse.transform(utf8.decoder).join();
          var meJson = jsonDecode(meBody) as Map<String, dynamic>;

          if (meResponse.statusCode == 200 && meJson['ok'] == true) {
            final botName = meJson['result']?['username'] ?? 'unknown';
            steps.add(_TestStep('Bot token', true, 'Connected as @$botName',
                rawResponse: meBody));
          } else {
            steps.add(_TestStep(
                'Bot token', false, meJson['description'] ?? 'Invalid',
                rawResponse: meBody));
            setState(() {
              _testSteps
                ..clear()
                ..addAll(steps);
            });
            _scrollToTestSteps();
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
              steps.add(_TestStep('Chat ID', true, 'Chat "$title" accessible',
                  rawResponse: chatBody));
            } else {
              steps.add(_TestStep(
                  'Chat ID', false, chatJson['description'] ?? 'Not found',
                  rawResponse: chatBody));
            }
          }
        } else {
          // Generic: try a simple HEAD/GET to the provider's base URL
          final dio = await provider.createHttpClient(config);
          String? rawResp;
          try {
            final resp = await dio.head('/');
            rawResp = resp.data?.toString();
            steps.add(_TestStep('Connectivity', true, 'Reachable',
                rawResponse: rawResp));
          } catch (_) {
            try {
              final resp = await dio.get('/');
              rawResp = resp.data?.toString();
              steps.add(_TestStep('Connectivity', true, 'Reachable',
                  rawResponse: rawResp));
            } catch (e2) {
              rawResp =
                  e2 is DioException ? e2.response?.data?.toString() : null;
              steps.add(_TestStep('Connectivity', false, '$e2',
                  rawResponse: rawResp));
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
      _log.error('Test auth unexpected error: $e', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _testSteps
            ..clear()
            ..addAll(steps);
          _isTesting = false;
        });
        _scrollToTestSteps();
      }
    }
  }

  Future<void> _fetchZulipResources() async {
    setState(() => _loadingResources = true);
    try {
      final config = <String, String>{};
      for (final key in widget.provider.requiredConfigKeys) {
        final value = _controllers[key]?.text.trim() ?? '';
        if (value.isNotEmpty) config[key] = value;
      }
      final dio = await widget.provider.createHttpClient(config);

      final subsResp = await dio.get('/api/v1/users/me/subscriptions');
      final subsData =
          jsonDecode(subsResp.data as String) as Map<String, dynamic>;
      final subscriptions = subsData['subscriptions'] as List;
      final streams = subscriptions
          .map((s) => (s as Map)['name'] as String)
          .toList()
        ..sort();

      final usersResp = await dio.get('/api/v1/users');
      final usersData =
          jsonDecode(usersResp.data as String) as Map<String, dynamic>;
      final members = usersData['members'] as List;
      final users = members.map((m) => m as Map<String, dynamic>).toList()
        ..sort((a, b) =>
            (a['full_name'] as String).compareTo(b['full_name'] as String));

      if (mounted) {
        setState(() {
          _zulipStreams = streams;
          _zulipUsers = users;
        });
      }
    } catch (e) {
      _log.error('Failed to fetch Zulip resources: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load channels/users: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingResources = false);
    }
  }

  Future<void> _save() async {
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
      for (final key in widget.provider.optionalConfigKeys) {
        final skey = _configKey(widget.provider.providerId, key);
        await store.write(
            key: skey, value: (_checkboxValues[key] ?? false).toString());
      }
      for (final key in widget.provider.optionalTextConfigKeys) {
        final value = _controllers[key]?.text.trim() ?? '';
        final skey = _configKey(widget.provider.providerId, key);
        if (value.isNotEmpty) {
          await store.write(key: skey, value: value);
        } else {
          await store.delete(key: skey);
        }
      }
      // Save instance metadata
      final (baseId, instanceId) = _splitInstanceId(widget.provider.providerId);
      final instances = await loadProviderInstances(baseId);
      final name = _nameController.text.trim();
      final existing = instances.indexWhere((i) => i.id == instanceId);
      if (existing >= 0) {
        instances[existing] = ProviderInstanceMeta(id: instanceId, name: name);
      } else {
        instances.add(ProviderInstanceMeta(id: instanceId, name: name));
      }
      await saveProviderInstances(baseId, instances);
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        final loc = AppLocalizations.of(context);
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.providerConfigSaved(widget.provider.providerName),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = widget.provider.configLabels;

    return Dialog(
      child: Stack(
        children: [
          // Scrollable content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
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
              ),
              // Scrollable form with bottom padding for the floating buttons
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: _contentScrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.providerConfigDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Instance name field
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.configLabelInstanceName,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              helperText: l10n.configInstanceNameHelper,
                            ),
                          ),
                        ),
                        ...widget.provider.requiredConfigKeys.map((key) {
                          final label =
                              _resolveCfgLabel(l10n, labels[key] ?? key);
                          final isSecret =
                              key.toLowerCase().contains('token') ||
                                  key.toLowerCase().contains('key') ||
                                  key.toLowerCase().contains('secret');
                          final keys = widget.provider.requiredConfigKeys;
                          final isLast = keys.lastOrNull == key;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _controllers[key],
                              textInputAction: isLast
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              onFieldSubmitted: isLast
                                  ? (_) {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      _save();
                                    }
                                  : null,
                              decoration: InputDecoration(
                                labelText: label,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                helperText: isSecret
                                    ? l10n.providerConfigSecretHint
                                    : null,
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
                        ...widget.provider.optionalConfigKeys.map((key) {
                          final label =
                              _resolveCfgLabel(l10n, labels[key] ?? key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(label,
                                  style: theme.textTheme.bodyMedium),
                              value: _checkboxValues[key] ?? false,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _checkboxValues[key] = v);
                                }
                              },
                            ),
                          );
                        }),
                        ...widget.provider.optionalTextConfigKeys.map((key) {
                          final label =
                              _resolveCfgLabel(l10n, labels[key] ?? key);
                          final isChannel = key == 'zulip_channel' &&
                              _isZulip &&
                              _zulipStreams.isNotEmpty;
                          final isRecipient = key == 'zulip_recipient' &&
                              _isZulip &&
                              _zulipUsers.isNotEmpty;

                          if (isChannel) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<String>(
                                initialValue: _controllers[key]!.text.isNotEmpty
                                    ? _controllers[key]!.text
                                    : null,
                                decoration: InputDecoration(
                                  labelText: label,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: _zulipStreams
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _controllers[key]!.text = v;
                                },
                              ),
                            );
                          }

                          if (isRecipient) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<String>(
                                initialValue: _controllers[key]!.text.isNotEmpty
                                    ? _controllers[key]!.text
                                    : null,
                                decoration: InputDecoration(
                                  labelText: label,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: _zulipUsers
                                    .map((u) => DropdownMenuItem(
                                          value: u['user_id'].toString(),
                                          child: Text(
                                              '${u['full_name']} (${u['user_id']})'),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _controllers[key]!.text = v;
                                },
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _controllers[key],
                              decoration: InputDecoration(
                                labelText: label,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
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
                                  if (step.rawResponse != null)
                                    IconButton(
                                      icon: const Icon(Icons.info_outline,
                                          size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: l10n.debugResponse,
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(
                                              '${step.label} — ${l10n.debugResponse}'),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              step.rawResponse!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace'),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text(l10n.cancel),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )),
                        if (_isZulip && _testSteps.any((s) => s.ok))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: OutlinedButton.icon(
                              onPressed: _loadingResources
                                  ? null
                                  : _fetchZulipResources,
                              icon: _loadingResources
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.cloud_download, size: 16),
                              label: Text(_zulipStreams.isNotEmpty
                                  ? 'Reload channels & users'
                                  : 'Load channels & users'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Floating action bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_validationError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _validationError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isTesting || _isSaving
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  setState(() => _validationError =
                                      l10n.fillRequiredFields);
                                  return;
                                }
                                setState(() => _validationError = null);
                                await _testAuth();
                              },
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find, size: 18),
                        label: Text(l10n.testProvider),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                await _save();
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: Text(l10n.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
