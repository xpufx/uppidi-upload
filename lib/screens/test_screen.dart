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
    final providers = ref.watch(enabledProvidersProvider);
    final disabled = ref.watch(disabledProviderIdsProvider).asData?.value ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            Text('Provider Tests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                for (final p in providers) {
                  ref.invalidate(_testProviderProvider(p.providerId));
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Test All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (providers.isEmpty)
          const Center(child: Text('No providers enabled')),
        ...providers.map((p) => _ProviderRow(
          provider: p,
          isEnabled: !disabled.contains(p.providerId),
        )),
      ],
    );
  }
}

/// Per-provider test result. Invalidated to re-trigger.
final _testProviderProvider = FutureProvider.autoDispose.family<_TestResult, String>((ref, id) async {
  final providers = ref.watch(enabledProvidersProvider);
  final p = providers.firstWhere((p) => p.providerId == id);

  try {
    final dio = await p.createHttpClient({});
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
    return _TestResult(
      providerId: id,
      providerName: p.providerName,
      online: true,
      latencyMs: sw.elapsedMilliseconds,
    );
  } catch (e) {
    return _TestResult(
      providerId: id,
      providerName: p.providerName,
      online: false,
      error: e.toString(),
    );
  }
});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(_testProviderProvider(provider.providerId));
    final result = testAsync.maybeWhen(data: (r) => r, orElse: () => null);
    final isLoading = testAsync.isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Status icon (spinner / check / error / help)
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
                // Provider name + latency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.providerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (result != null) ...[
                        const SizedBox(height: 2),
                        result.online
                          ? Text('${result.latencyMs}ms', style: TextStyle(fontSize: 12, color: Colors.green.shade700))
                          : Text(result.error ?? 'Connection failed', style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ],
                  ),
                ),
                // Test button
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 20),
                  tooltip: 'Test',
                  onPressed: isLoading ? null : () => ref.invalidate(_testProviderProvider(provider.providerId)),
                ),
                // Enable/disable switch
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
          ],
        ),
      ),
    );
  }
}