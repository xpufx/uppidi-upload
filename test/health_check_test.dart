// ignore_for_file: avoid_print

// Live provider health runner.
//
// This is a test rather than a `dart run` script because the provider
// classes transitively import Flutter-only packages (e.g. `path_provider`
// via the logger), so `dart run` cannot link them. Driving the probes from
// `flutter test` keeps the exact production upload path.
//
// Skipped unless `RUN_HEALTH_CHECK=1` is set. Writes the versioned manifest
// to `HEALTH_OUTPUT` atomically (temp file + rename); when `HEALTH_OUTPUT`
// is unset it prints the manifest to stdout instead.
//
// Existing state is read from `HEALTH_INPUT` (defaults to `HEALTH_OUTPUT`)
// so `failureCount`/`since` survive between runs.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/core/health/provider_health.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/providers/bzzhr_provider.dart';
import 'package:uppidi_upload/providers/catbox_provider.dart';
import 'package:uppidi_upload/providers/fileditch_provider.dart';
import 'package:uppidi_upload/providers/filebin_provider.dart';
import 'package:uppidi_upload/providers/filester_provider.dart';
import 'package:uppidi_upload/providers/freeimage_provider.dart';
import 'package:uppidi_upload/providers/frisk_provider.dart';
import 'package:uppidi_upload/providers/gofile_provider.dart';
import 'package:uppidi_upload/providers/httpbin_provider.dart';
import 'package:uppidi_upload/providers/litterbox_provider.dart';
import 'package:uppidi_upload/providers/storage_to_provider.dart';
import 'package:uppidi_upload/providers/tempsh_provider.dart';
import 'package:uppidi_upload/providers/tmpfilelink_provider.dart';
import 'package:uppidi_upload/providers/uguu_provider.dart';

final bool _run = Platform.environment['RUN_HEALTH_CHECK'] == '1';

/// Anonymous, config-free providers. Auth/instance-configured providers
/// (Telegram, Zulip, Matterbridge, CustomUguu) and the device-only `local`
/// provider are intentionally excluded.
List<BaseUploader> anonymousProviders() => [
      HttpBinProvider(),
      TmpFileLinkProvider(),
      FileDitchProvider(),
      FilebinProvider(),
      FilesterProvider(),
      StorageToProvider(),
      BzzhrProvider(),
      GoFileProvider(),
      FriskProvider(),
      UguuProvider(name: 'uguu.se', url: 'https://uguu.se'),
      CatboxProvider(),
      FreeImageHostProvider(name: 'freeimage.host', url: 'https://freeimage.host'),
      TempShProvider(),
      LitterboxProvider(),
    ];

final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

FileUploadRequest _requestFor(BaseUploader provider) {
  final isImage = provider.providerId.startsWith('freeimage') ||
      provider.providerId == 'catbox' ||
      provider.providerId == 'litterbox';
  final data = isImage ? _pngBytes : Uint8List.fromList('uppidi health check'.codeUnits);
  return FileUploadRequest(
    fileName: isImage ? 'health.png' : 'health.txt',
    mimeType: isImage ? 'image/png' : 'text/plain',
    sizeInBytes: data.length,
    dataStream: Stream.value(data),
  );
}

Map<String, ProviderHealthInfo> _readExisting(String? path) {
  if (path == null || !File(path).existsSync()) return {};
  try {
    final decoded = jsonDecode(File(path).readAsStringSync());
    return parseHealthManifest(decoded);
  } catch (e) {
    print('health: unreadable existing manifest ($path): $e');
    return {};
  }
}

void _writeAtomically(String path, Map<String, dynamic> manifest) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  final tmp = File('$path.tmp');
  tmp.writeAsStringSync('${jsonEncode(manifest)}\n', flush: true);
  tmp.renameSync(path);
}

void main() {
  test(
    'live provider health check',
    () async {
      final output = Platform.environment['HEALTH_OUTPUT'];
      final input = Platform.environment['HEALTH_INPUT'] ?? output;
      final previous = _readExisting(input);

      final updated = Map<String, ProviderHealthInfo>.from(previous);

      for (final provider in anonymousProviders()) {
        final started = DateTime.now();
        String? reason;
        var success = false;
        try {
          final result = await provider
              .upload(_requestFor(provider))
              .timeout(const Duration(minutes: 2));
          success = result.success;
          if (!success) {
            reason = result.errorMessage ?? result.rawError ?? 'unknown error';
          }
        } catch (e) {
          reason = e.toString();
        }
        updated[provider.providerId] = applyProbeResult(
          previous[provider.providerId],
          success: success,
          now: started,
          reason: reason,
        );
        print('health: ${provider.providerId} '
            '${success ? 'OK' : 'FAIL ($reason)'}');
      }

      final manifest = buildHealthManifest(updated, DateTime.now());
      final pretty = const JsonEncoder.withIndent('  ').convert(manifest);

      if (output == null || output.isEmpty) {
        print(pretty);
        return;
      }
      _writeAtomically(output, manifest);
      print('health: wrote $output');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    skip: _run ? null : 'Set RUN_HEALTH_CHECK=1 to probe live providers',
  );
}
