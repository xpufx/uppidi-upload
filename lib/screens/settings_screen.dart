import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/registry.dart';
import '../core/settings_service.dart';
import '../core/theme_provider.dart';
import '../core/version.dart';
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
    final configurableProviders = ProviderRegistry.all.where((p) => p.requiredConfigKeys.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (configurableProviders.isNotEmpty) ...[
          Text(l10n.providersSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...configurableProviders.map((provider) {
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
        ],
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
        const SizedBox(height: 16),
        // Theme mode
        Text(l10n.themeMode, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Center(
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem), icon: const Icon(Icons.brightness_auto)),
              ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode)),
            ],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged: (sel) => ref.read(themeModeProvider.notifier).setMode(sel.first),
          ),
        ),
        const SizedBox(height: 16),
        // Seed color
        Text(l10n.themeSeedColor, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: const [
            Colors.deepPurple, Colors.blue, Colors.teal,
            Colors.orange, Colors.pink, Colors.indigo,
          ].map((color) {
            final selected = ref.watch(seedColorProvider);
            final isSelected = selected.toARGB32() == color.toARGB32();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ref.read(seedColorProvider.notifier).setColor(color),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                    boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)] : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom logo
        Text(l10n.themeCustomLogo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.image);
            if (result != null && result.files.isNotEmpty) {
              final path = result.files.single.path;
              ref.read(logoPathProvider.notifier).setPath(path);
            }
          },
          icon: const Icon(Icons.image, size: 18),
          label: Text(ref.watch(logoPathProvider) != null ? 'Change Logo' : 'Choose Logo'),
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
        Text('uppidi v$appVersion',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Cross-platform media uploader',
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text('${ProviderRegistry.all.length} providers · 45 tests · $gitHash',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 16),
        Center(child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/logo.png', width: 64, height: 64),
        )),
      ],
    );
  }
}
