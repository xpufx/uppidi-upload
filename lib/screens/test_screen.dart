import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/interfaces/uploader.dart';
import '../core/registry.dart';
import '../core/settings_service.dart';
import '../core/app_logo.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProviders = ProviderRegistry.all;
    final enabled = ref.watch(enabledProvidersProvider);
    final disabled = ref.watch(disabledProviderIdsProvider).asData?.value ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            Text('Providers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.icon(
              onPressed: enabled.isEmpty ? null : () {
                for (final p in enabled) {
                  TestScreen._setLoading(ref, p.providerId);
                  TestScreen._runTest(ref, p);
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Test All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (allProviders.isEmpty)
          const Center(child: Text('No providers available')),
        ...allProviders.map((p) => _ProviderRow(
          provider: p,
          isEnabled: !disabled.contains(p.providerId),
        )),
      ],
    );
  }

  static void _setLoading(WidgetRef ref, String id) {
    ref.read(_testStates.notifier).setFor(id, const AsyncValue.loading());
  }

  static void _setResult(WidgetRef ref, String id, _TestResult r) {
    ref.read(_testStates.notifier).setFor(id, AsyncValue.data(r));
  }

  static Future<void> _runTest(WidgetRef ref, BaseUploader p) async {
    try {
      final svc = ref.read(settingsServiceProvider);
      final config = await svc.loadProviderConfig(p.providerId, p.requiredConfigKeys);
      final allowInsecure = await svc.isInsecureConnAllowed();
      final dio = await p.createHttpClient(config, allowInsecureConn: allowInsecure);
      dio.options.connectTimeout = const Duration(seconds: 5);
      final sw = Stopwatch()..start();
      try {
        await dio.head('/');
      } catch (_) {
        await dio.get('/', options: Options(
          extra: {'noLog': true},
          responseType: ResponseType.bytes,
          headers: {'Range': 'bytes=0-0'},
        ));
      }
      sw.stop();
      _setResult(ref, p.providerId, _TestResult(
        providerId: p.providerId, providerName: p.providerName,
        online: true, latencyMs: sw.elapsedMilliseconds,
      ));
    } catch (e) {
      _setResult(ref, p.providerId, _TestResult(
        providerId: p.providerId, providerName: p.providerName,
        online: false, error: e.toString(),
      ));
    }
  }
}

/// All test states keyed by provider ID. Empty = not tested.
final _testStates = NotifierProvider<_TestStatesNotifier, Map<String, AsyncValue<_TestResult>>>(
  _TestStatesNotifier.new,
);

class _TestStatesNotifier extends Notifier<Map<String, AsyncValue<_TestResult>>> {
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
  _TestResult({required this.providerId, required this.providerName, required this.online, this.latencyMs = 0, this.error});
}

class _ProviderRow extends ConsumerWidget {
  final BaseUploader provider;
  final bool isEnabled;
  const _ProviderRow({required this.provider, required this.isEnabled});

  String _buildMetadataString() {
    final meta = provider.metadata;
    final parts = <String>[];
    if (meta.fileSizeLabel.isNotEmpty) {
      parts.add('Max: ${meta.fileSizeLabel}');
    }
    if (meta.mimeTypeLabel.isNotEmpty) {
      parts.add(meta.mimeTypeLabel);
    }
    if (meta.expiryInfo != null && meta.expiryInfo!.isNotEmpty) {
      parts.add(meta.expiryInfo!);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testStates = ref.watch(_testStates);
    final testState = testStates[provider.providerId];
    final isLoading = testState != null && testState.isLoading;
    final result = testState?.maybeWhen(data: (r) => r, orElse: () => null);

    final metadataStr = _buildMetadataString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(
                        result == null ? Icons.help_outline : result.online ? Icons.check_circle : Icons.error,
                        color: result == null ? Colors.grey : result.online ? Colors.green : Colors.red,
                        size: 20,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.providerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (metadataStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(metadataStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 20),
                  tooltip: 'Test',
                  onPressed: isLoading ? null : () {
                    TestScreen._setLoading(ref, provider.providerId);
                    TestScreen._runTest(ref, provider);
                  },
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (v) async {
                    final svc = ref.read(settingsServiceProvider);
                    final current = await svc.getDisabledProviders();
                    if (v) {
                      current.remove(provider.providerId);
                    } else {
                      current.add(provider.providerId);
                    }
                    await svc.setDisabledProviders(current);
                    ref.invalidate(disabledProviderIdsProvider);
                  },
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: result.online
                  ? Text('${result.latencyMs}ms', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500))
                  : Text(result.error ?? 'Connection failed', style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}