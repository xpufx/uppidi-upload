import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config_provider.dart';
import 'interfaces/uploader.dart';
import 'logging/log.dart';
import 'models/provider_instance.dart';

final _log = Log('Connectivity');

/// Check if a provider is reachable. Returns latency in milliseconds, or null if unreachable.
/// Accepts optional proxyUrl for testing through proxy.
Future<int?> checkProviderConnectivity(BaseUploader provider,
    {String? proxyUrl, WidgetRef? ref}) async {
  final config = provider is ProviderInstance
      ? await ref?.read(providerConfigProvider(provider.providerId).future) ??
          <String, String>{}
      : <String, String>{};
  final dio = await provider.createHttpClient(config, proxyUrl: proxyUrl);
  dio.options.connectTimeout = const Duration(seconds: 5);
  final sw = Stopwatch()..start();
  try {
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
    return sw.elapsedMilliseconds;
  } catch (e) {
    _log.warn('Provider check failed: $e');
    return null;
  } finally {
    dio.close();
  }
}
