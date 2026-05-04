import 'package:dio/dio.dart';
import 'interfaces/uploader.dart';

/// Check if a provider is reachable. Returns latency in milliseconds, or null if unreachable.
/// Accepts optional proxyUrl for testing through proxy.
Future<int?> checkProviderConnectivity(BaseUploader provider, {String? proxyUrl}) async {
  try {
    final dio = await provider.createHttpClient({}, proxyUrl: proxyUrl);
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
    return sw.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}