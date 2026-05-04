import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../core/interfaces/uploader.dart';
import '../core/registry.dart';
import '../core/app_logo.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(enabledProvidersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            Text('Provider Tests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => ref.invalidate(_testResultsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Test All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...providers.map((p) => _ProviderTestTile(provider: p)),
      ],
    );
  }
}

// Test results
final _testResultsProvider =
    FutureProvider.autoDispose<List<_TestResult>>((ref) async {
  final providers = ref.watch(enabledProvidersProvider);
  final results = <_TestResult>[];

  for (final p in providers) {
    try {
      final dio = await p.createHttpClient({});
      dio.options.connectTimeout = const Duration(seconds: 5);
      final sw = Stopwatch()..start();
      try {
        await dio.head('/');
      } catch (_) {
        await dio.get('/',
            options: Options(
              extra: {'noLog': true},
              responseType: ResponseType.bytes,
              headers: {'Range': 'bytes=0-0'},
            ));
      }
      sw.stop();
      results.add(_TestResult(
        providerId: p.providerId,
        providerName: p.providerName,
        online: true,
        latencyMs: sw.elapsedMilliseconds,
      ));
    } catch (e) {
      results.add(_TestResult(
        providerId: p.providerId,
        providerName: p.providerName,
        online: false,
        error: e.toString(),
      ));
    }
  }
  return results;
});

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

class _ProviderTestTile extends ConsumerWidget {
  final BaseUploader provider;
  const _ProviderTestTile({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(_testResultsProvider);
    final result = resultsAsync.maybeWhen(
      data: (results) =>
          results.where((r) => r.providerId == provider.providerId).firstOrNull,
      orElse: () => null,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
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
        ),
        title: Text(provider.providerName),
        subtitle: result == null
            ? const Text('Not tested', style: TextStyle(fontSize: 12))
            : result.online
                ? Text('${result.latencyMs}ms',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700))
                : Text(result.error ?? 'Connection failed',
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
      ),
    );
  }
}