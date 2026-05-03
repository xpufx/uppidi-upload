import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../providers/upload_provider.dart';
import 'logging/log.dart';
import 'mime_types.dart';

final _log = Log('ShareHandler');

class ShareHandler {
  static void init(BuildContext context, WidgetRef ref) {
    _log.info('Initializing share handler');
    final notifier = ref.read(uploadProvider.notifier);

    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      _handleSharedFiles(files, notifier);
    }, onError: (e) {
      _log.warn('Share stream error: $e');
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleSharedFiles(files, notifier);
    });
  }

  static void _handleSharedFiles(List<SharedMediaFile>? files, UploadNotifier notifier) {
    if (files == null || files.isEmpty) return;

    for (final file in files) {
      final path = file.path;
      if (path.isEmpty) continue;

      final uri = Uri.tryParse(path);
      final filePath = uri?.path ?? path;
      final ext = filePath.contains('.') ? filePath.split('.').last : '';
      final mimeType = mimeTypeFromExtension(ext);

      _log.info('Received shared file: ${filePath.split('/').last} ($mimeType)');
      notifier.uploadFromFile(filePath, mimeType);
    }

    ReceiveSharingIntent.instance.reset();
  }
}
