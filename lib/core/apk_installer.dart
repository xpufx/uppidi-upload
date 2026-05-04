import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads an APK from [url] and opens the installer prompt.
Future<void> downloadAndInstallApk(String url) async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/uppidi-update.apk';

    final dio = Dio();
    await dio.download(url, filePath);

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