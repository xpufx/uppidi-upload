import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/connectivity.dart';
import '../core/interfaces/uploader.dart';
import '../core/logging/log.dart';
import '../core/metadata_badges.dart';
import '../core/models/provider_instance.dart';
import '../core/models/provider_metadata.dart';
import '../core/provider_config_sheet.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';
import '../l10n/app_localizations.dart';

final _log = Log('TestScreen');

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  bool _builtinExpanded = false;
  bool _myProvidersExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final svc = ref.read(settingsServiceProvider);
      final builtin = await svc.get(SettingsService.sectionBuiltinCollapsed);
      final myprov = await svc.get(SettingsService.sectionMyProvidersCollapsed);
      if (mounted) {
        setState(() {
          _builtinExpanded = builtin != 'true';
          _myProvidersExpanded = myprov != 'true';
        });
      }
    } catch (e) {
      _log.error('Failed to load section prefs: $e', error: e);
    }
  }

  Future<void> _toggleBuiltin() async {
    final newVal = !_builtinExpanded;
    setState(() => _builtinExpanded = newVal);
    try {
      final svc = ref.read(settingsServiceProvider);
      await svc.set(
          SettingsService.sectionBuiltinCollapsed, newVal ? 'false' : 'true');
    } catch (e) {
      _log.error('Failed to save builtin section pref: $e', error: e);
    }
  }

  Future<void> _toggleMyProviders() async {
    final newVal = !_myProvidersExpanded;
    setState(() => _myProvidersExpanded = newVal);
    try {
      final svc = ref.read(settingsServiceProvider);
      await svc.set(SettingsService.sectionMyProvidersCollapsed,
          newVal ? 'false' : 'true');
    } catch (e) {
      _log.error('Failed to save MyProviders section pref: $e', error: e);
    }
  }

  Future<ProviderInstance> _createInstance(
      WidgetRef ref, BaseUploader base) async {
    final instances = await loadProviderInstances(base.providerId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final name = '${base.providerName} ${instances.length + 1}';
    return ProviderInstance(base, newId, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allProviders = ProviderRegistry.all;
    final enabled = ref.watch(enabledProvidersProvider);
    final health = ref.watch(providerHealthProvider).asData?.value ?? {};

    // Split into built-in (non-instance) and custom instances
    // Built-in = non-auth providers (no config needed, always available).
    // Auth providers like Zulip/Telegram are only available as configured
    // instances in "My Providers" — they never appear as built-in.
    final builtIn = allProviders
        .where((p) =>
            p is! ProviderInstance &&
            !p.metadata.capabilities.contains(ProviderCapability.requiresAuth))
        .toList();
    final myProviders = allProviders.whereType<ProviderInstance>().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Test All button ──
        Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: enabled.isEmpty
                  ? null
                  : () {
                      for (final p in enabled) {
                        _setLoading(ref, p.providerId);
                        _runTest(ref, p, l10n.connectionFailed);
                      }
                    },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.testAll),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Built-in Providers (collapsible) ──
        InkWell(
          onTap: _toggleBuiltin,
          child: Row(
            children: [
              Icon(
                _builtinExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(l10n.builtInProviders,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_builtinExpanded) ...[
          const SizedBox(height: 8),
          if (builtIn.isEmpty)
            Center(child: Text(l10n.noProvidersAvailable))
          else
            ...builtIn.map((p) => _ProviderRow(
                  provider: p,
                  isEnabled: enabled.any((e) => e.providerId == p.providerId),
                  health: health[p.providerId],
                )),
        ],
        const SizedBox(height: 24),

        // ── My Providers (collapsible) ──
        InkWell(
          onTap: _toggleMyProviders,
          child: Row(
            children: [
              Icon(
                _myProvidersExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(l10n.myProviders,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (_myProvidersExpanded) ...[
          const SizedBox(height: 8),
          if (myProviders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.noInstancesConfigured,
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...myProviders.map((p) => _ProviderRow(
                  provider: p,
                  isEnabled: enabled.any((e) => e.providerId == p.providerId),
                  health: health[p.providerId],
                  showConfigure: true,
                )),
          const SizedBox(height: 8),
          // Add button
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final types = ProviderRegistry.instanceTypes;
                if (types.isEmpty) return;
                if (types.length == 1) {
                  final instance = await _createInstance(ref, types.first);
                  if (!context.mounted) return;
                  final saved =
                      await showProviderEditDialog(context, ref, instance);
                  if (saved) ref.invalidate(enabledProvidersProvider);
                } else {
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
                  final instance = await _createInstance(ref, chosen);
                  if (!context.mounted) return;
                  final saved =
                      await showProviderEditDialog(context, ref, instance);
                  if (saved) ref.invalidate(enabledProvidersProvider);
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.addProvider),
            ),
          ),
        ],
      ],
    );
  }
}

/// All test states keyed by provider ID. Empty = not tested.
final _testStates =
    NotifierProvider<_TestStatesNotifier, Map<String, AsyncValue<_TestResult>>>(
  _TestStatesNotifier.new,
);

class _TestStatesNotifier
    extends Notifier<Map<String, AsyncValue<_TestResult>>> {
  @override
  Map<String, AsyncValue<_TestResult>> build() => {};

  void setFor(String id, AsyncValue<_TestResult> value) {
    state = {...state, id: value};
  }
}

class _TestResult {
  final String providerId;
  final String providerName;
  final bool online;
  final int latencyMs;
  final String? error;
  _TestResult(
      {required this.providerId,
      required this.providerName,
      required this.online,
      this.latencyMs = 0,
      this.error});
}

class _ProviderRow extends ConsumerWidget {
  final BaseUploader provider;
  final bool isEnabled;
  final ProviderHealthInfo? health;
  final bool showConfigure;

  const _ProviderRow({
    required this.provider,
    required this.isEnabled,
    this.health,
    this.showConfigure = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final testStates = ref.watch(_testStates);
    final testState = testStates[provider.providerId];
    final isLoading = testState != null && testState.isLoading;
    final result = testState?.maybeWhen(data: (r) => r, orElse: () => null);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Icon(
                      result == null
                          ? Icons.help_outline
                          : result.online
                              ? Icons.check_circle
                              : Icons.error,
                      color: result == null
                          ? Colors.grey
                          : result.online
                              ? Colors.green
                              : Colors.red,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                            provider is ProviderInstance
                                ? (provider as ProviderInstance).displayName
                                : provider.providerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      if (result != null) ...[
                        const SizedBox(width: 6),
                        result.online
                            ? Text('${result.latencyMs}ms',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500))
                            : Text(result.error ?? '',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.red)),
                      ],
                    ],
                  ),
                  if (health?.disabled == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 10, color: Colors.orange),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                                health?.reason ?? l10n.currentlyUnavailable,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.orange)),
                          ),
                        ],
                      ),
                    ),
                  metadataBadges(provider.metadata),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: l10n.testProvider,
              onPressed: isLoading
                  ? null
                  : () {
                      _setLoading(ref, provider.providerId);
                      _runTest(ref, provider, l10n.connectionFailed);
                    },
            ),
            if (showConfigure && provider is ProviderInstance)
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: l10n.providerConfigure,
                onPressed: () async {
                  final saved = await showProviderEditDialog(
                      context, ref, provider as ProviderInstance);
                  if (saved) ref.invalidate(enabledProvidersProvider);
                },
              ),
            Switch(
              value: isEnabled,
              onChanged: (v) async {
                final current = Set<String>.from(
                    await ref.read(disabledProviderIdsProvider.future));
                if (v) {
                  current.remove(provider.providerId);
                } else {
                  current.add(provider.providerId);
                }
                await ref
                    .read(settingsServiceProvider)
                    .setDisabledProviders(current);
                ref.invalidate(disabledProviderIdsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Top-level helpers
void _setLoading(WidgetRef ref, String id) {
  ref.read(_testStates.notifier).setFor(id, const AsyncValue.loading());
}

void _setResult(WidgetRef ref, String id, _TestResult r) {
  ref.read(_testStates.notifier).setFor(id, AsyncValue.data(r));
}

Future<void> _runTest(
    WidgetRef ref, BaseUploader p, String connectionFailed) async {
  final latency = await checkProviderConnectivity(p, ref: ref);
  if (latency != null) {
    _setResult(
        ref,
        p.providerId,
        _TestResult(
          providerId: p.providerId,
          providerName: p.providerName,
          online: true,
          latencyMs: latency,
        ));
  } else {
    _setResult(
        ref,
        p.providerId,
        _TestResult(
          providerId: p.providerId,
          providerName: p.providerName,
          online: false,
          error: connectionFailed,
        ));
  }
}
