import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../core/settings_service.dart';
import '../providers/upload_provider.dart';
import 'logging/log.dart';
import 'mime_types.dart';

final _log = Log('ShareHandler');

class ShareHandler {
  static void init(BuildContext context, WidgetRef ref) {
    _log.info('Initializing share handler');

    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      _handleSharedFiles(files, ref);
    }, onError: (e) {
      _log.warn('Share stream error: $e');
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleSharedFiles(files, ref);
    });
  }

  static Future<void> _handleSharedFiles(
      List<SharedMediaFile>? files, WidgetRef ref) async {
    if (files == null || files.isEmpty) return;

    for (final file in files) {
      final path = file.path;
      if (path.isEmpty) continue;

      final uri = Uri.tryParse(path);
      final filePath = uri?.path ?? path;
      final ext = filePath.contains('.') ? filePath.split('.').last : '';
      final mimeType = mimeTypeFromExtension(ext);

      _log.info(
          'Received shared file: ${filePath.split('/').last} ($mimeType)');

      final notifier = ref.read(uploadProvider.notifier);
      final svc = ref.read(settingsServiceProvider);

      // Switch to default share provider if configured
      final defaultProvider =
          await svc.get(SettingsService.defaultShareProviderKey);
      if (defaultProvider != null) {
        final providers = ref.read(uploadProvider).providers;
        final idx =
            providers.indexWhere((p) => p.providerId == defaultProvider);
        if (idx >= 0) notifier.setProvider(idx);
      }

      notifier.uploadFromFile(filePath, mimeType);
    }

    ReceiveSharingIntent.instance.reset();
  }
}
