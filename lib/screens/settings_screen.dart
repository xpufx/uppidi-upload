import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/registry.dart';
import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';

final providerConfigsProvider = FutureProvider.family<Map<String, String>, String>(
  (ref, providerId) async {
    final svc = ref.read(settingsServiceProvider);
    final provider = ProviderRegistry.all.firstWhere((p) => p.providerId == providerId);
    return svc.loadProviderConfig(providerId, provider.requiredConfigKeys);
  },
);

final insecureConnProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.isInsecureConnAllowed();
});

final proxyUrlProvider = FutureProvider<String?>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.getProxyUrl();
});

final _approveBeforeUploadProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.needsApprovalBeforeUpload();
});

final localeProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return (await svc.get(SettingsService.localeKey)) ?? 'en';
});

final _defaultShareProviderProvider = FutureProvider<String?>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return svc.get(SettingsService.defaultShareProviderKey);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final svc = ref.read(settingsServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.providersSection,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...ProviderRegistry.all.map((provider) {
          if (provider.requiredConfigKeys.isEmpty) return const SizedBox.shrink();

          final configAsync = ref.watch(providerConfigsProvider(provider.providerId));
          final saved = configAsync.asData?.value ?? {};
          final labels = provider.configLabels;

          return _ProviderConfigCard(
            providerName: provider.providerName,
            providerId: provider.providerId,
            configKeys: provider.requiredConfigKeys,
            labels: labels,
            saved: saved,
            onSave: (key, value) => svc.set(
              svc.providerKey(provider.providerId, key),
              value,
            ),
            onClear: (key) => svc.remove(
              svc.providerKey(provider.providerId, key),
            ),
          );
        }),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text(l10n.settings,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _GlobalToggles(),
      ],
    );
  }
}

class _ProviderConfigCard extends StatefulWidget {
  final String providerName;
  final String providerId;
  final List<String> configKeys;
  final Map<String, String> labels;
  final Map<String, String> saved;
  final void Function(String key, String value) onSave;
  final void Function(String key) onClear;

  const _ProviderConfigCard({
    required this.providerName,
    required this.providerId,
    required this.configKeys,
    required this.labels,
    required this.saved,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<_ProviderConfigCard> createState() => _ProviderConfigCardState();
}

class _ProviderConfigCardState extends State<_ProviderConfigCard> {
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final key in widget.configKeys) {
      _controllers[key] =
          TextEditingController(text: widget.saved[key] ?? '');
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.providerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.configKeys.map((key) {
              final label = widget.labels[key] ?? key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _controllers[key],
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => widget.onSave(key, value),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GlobalToggles extends ConsumerStatefulWidget {
  const _GlobalToggles();

  @override
  ConsumerState<_GlobalToggles> createState() => _GlobalTogglesState();
}

class _GlobalTogglesState extends ConsumerState<_GlobalToggles> {
  late TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    _proxyController = TextEditingController();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final proxy = await ref.read(proxyUrlProvider.future);
    _proxyController.text = proxy ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final svc = ref.read(settingsServiceProvider);
    final insecureAsync = ref.watch(insecureConnProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.enableInsecure),
          subtitle: Text(l10n.selfSignedCertWarning,
              style: const TextStyle(fontSize: 12)),
          value: insecureAsync.asData?.value ?? false,
          onChanged: (v) {
            svc.set(SettingsService.insecureConnKey, v.toString());
            ref.invalidate(insecureConnProvider);
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text(l10n.settingApproveBeforeUpload),
          value: ref.watch(_approveBeforeUploadProvider).asData?.value ?? false,
          onChanged: (v) {
            svc.set(SettingsService.approveBeforeUploadKey, v.toString());
            ref.invalidate(_approveBeforeUploadProvider);
          },
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Language'),
            const Spacer(),
            DropdownButton<String>(
              value: ref.watch(localeCodeProvider).asData?.value ?? 'en',
              onChanged: (v) {
                if (v != null) {
                  svc.set(SettingsService.localeKey, v);
                  ref.invalidate(localeCodeProvider);
                }
              },
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: ref.watch(_defaultShareProviderProvider).asData?.value,
          decoration: const InputDecoration(
            labelText: 'Default for sharing',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Last used')),
            ...ProviderRegistry.all.map((p) => DropdownMenuItem(
              value: p.providerId,
              child: Text(p.providerName),
            )),
          ],
          onChanged: (v) {
            if (v == null) {
              svc.remove(SettingsService.defaultShareProviderKey);
            } else {
              svc.set(SettingsService.defaultShareProviderKey, v);
            }
            ref.invalidate(_defaultShareProviderProvider);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _proxyController,
          decoration: InputDecoration(
            labelText: l10n.proxyUrl,
            hintText: 'socks5://10.0.10.11:1080',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) {
            if (v.isEmpty) {
              svc.remove(SettingsService.proxyUrlKey);
            } else {
              svc.set(SettingsService.proxyUrlKey, v);
            }
            ref.invalidate(proxyUrlProvider);
          },
        ),
        const Divider(height: 32),
        Text('uppidi v1.0.0',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Cross-platform media uploader',
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text('${ProviderRegistry.all.length} providers · 45 tests',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
