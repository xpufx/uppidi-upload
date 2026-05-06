import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads an APK from [url] and opens the installer prompt.
/// [onProgress] receives (downloadedBytes, totalBytes, bytesPerSec).
Future<void> downloadAndInstallApk(String url, {void Function(int, int, int)? onProgress}) async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/uppidi-update.apk';

    final dio = Dio();

    DateTime lastTime = DateTime.now();
    int lastBytes = 0;

    await dio.download(
      url, filePath,
      onReceiveProgress: (received, total) {
        final now = DateTime.now();
        final elapsed = now.difference(lastTime).inMilliseconds;
        if (elapsed >= 500) {
          final delta = received - lastBytes;
          final bytesPerSec = (delta / (elapsed / 1000.0)).round();
          lastTime = now;
          lastBytes = received;
          onProgress?.call(received, total, bytesPerSec);
        } else {
          onProgress?.call(received, total, 0);
        }
      },
    );

    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception('Could not open APK: ${result.message}');
    }
  } catch (e) {
    rethrow;
  }
}