import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'interfaces/uploader.dart';
import 'logging/log.dart';
import 'models/provider_instance.dart';

final _log = Log('Connectivity');
final _secure = FlutterSecureStorage();

/// Loads the stored config for a [ProviderInstance] from secure storage.
Future<Map<String, String>> _loadInstanceConfig(ProviderInstance p) async {
  final config = <String, String>{};
  for (final key in p.requiredConfigKeys) {
    final value =
        await _secure.read(key: 'provider_config_${p.providerId}_$key');
    if (value != null && value.isNotEmpty) config[key] = value;
  }
  return config;
}

/// Check if a provider is reachable. Returns latency in milliseconds, or null if unreachable.
/// Accepts optional proxyUrl for testing through proxy.
Future<int?> checkProviderConnectivity(BaseUploader provider,
    {String? proxyUrl}) async {
  final config = provider is ProviderInstance
      ? await _loadInstanceConfig(provider)
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
