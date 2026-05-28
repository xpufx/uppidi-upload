import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logging/log.dart';
import 'version.dart';

final _log = Log('VersionCheck');

sealed class VersionCheckState {
  const VersionCheckState();
}

class VersionCheckIdle extends VersionCheckState {
  const VersionCheckIdle();
}

class VersionCheckChecking extends VersionCheckState {
  const VersionCheckChecking();
}

class VersionCheckUpToDate extends VersionCheckState {
  final String latestHash;
  final DateTime lastChecked;
  const VersionCheckUpToDate(this.latestHash, this.lastChecked);
}

class VersionCheckUpdateAvailable extends VersionCheckState {
  final String latestHash;
  final DateTime lastChecked;
  final String downloadUrl;
  const VersionCheckUpdateAvailable(
    this.latestHash,
    this.lastChecked,
    this.downloadUrl,
  );
}

class VersionCheckNotifier extends Notifier<VersionCheckState> {
  int _tick = 0;
  Timer? _ticker;

  @override
  VersionCheckState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const VersionCheckIdle();
  }

  Future<void> check() async {
    _ticker?.cancel();
    final now = DateTime.now();
    state = const VersionCheckChecking();
    try {
      if (cdnUrl.isNotEmpty) {
        await _checkFromCdn(now);
      } else {
        await _checkFromGitHub(now);
      }
    } catch (e) {
      _log.warn('Version check failed: $e', error: e);
      state = const VersionCheckIdle();
    }
    if (state is VersionCheckUpToDate || state is VersionCheckUpdateAvailable) {
      _startTicker();
    }
  }

  Future<void> _checkFromCdn(DateTime now) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$cdnUrl/latest.txt'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final latestHash = body.trim();
        final downloadUrl = _buildDownloadUrl();
        state = (latestHash.isNotEmpty && latestHash != gitHash)
            ? VersionCheckUpdateAvailable(latestHash, now, downloadUrl)
            : VersionCheckUpToDate(latestHash, now);
      } else {
        state = const VersionCheckIdle();
      }
    } finally {
      client.close();
    }
  }

  Future<void> _checkFromGitHub(DateTime now) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
      );
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'uppidi-upload');
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final tagName = json['tag_name'] as String? ?? '';
        final latestHash =
            tagName.startsWith('v') ? tagName.substring(1) : tagName;

        // Pick the right asset for this platform
        final assets = json['assets'] as List? ?? [];
        String? downloadUrl;
        if (Platform.isAndroid) {
          const abiPriority = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
          for (final abi in abiPriority) {
            final match = assets.cast<Map<String, dynamic>>().where(
                  (a) => (a['name'] as String).contains('-$abi.apk'),
                );
            if (match.isNotEmpty) {
              downloadUrl = match.first['browser_download_url'] as String?;
              break;
            }
          }
        } else {
          final desktopAssets = assets.cast<Map<String, dynamic>>().where(
            (a) {
              final name = a['name'] as String;
              return name.endsWith('.AppImage') || name.endsWith('.tar.gz');
            },
          );
          final appImage = desktopAssets.where(
            (a) => (a['name'] as String).endsWith('.AppImage'),
          );
          downloadUrl = appImage.isNotEmpty
              ? appImage.first['browser_download_url'] as String?
              : desktopAssets.isNotEmpty
                  ? desktopAssets.first['browser_download_url'] as String?
                  : null;
        }

        state = (latestHash.isNotEmpty && latestHash != appVersion)
            ? VersionCheckUpdateAvailable(latestHash, now, downloadUrl ?? '')
            : VersionCheckUpToDate(latestHash, now);
      } else {
        state = const VersionCheckIdle();
      }
    } finally {
      client.close();
    }
  }

  String _buildDownloadUrl() {
    return Platform.isAndroid
        ? '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk'
        : '$cdnUrl/uppidi-upload-latest-linux.tar.gz';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is VersionCheckUpToDate ||
          state is VersionCheckUpdateAvailable) {
        _tick++;
        ref.read(versionCheckAgeTicker.notifier).set(_tick);
      } else {
        _ticker?.cancel();
      }
    });
  }
}

final versionCheckProvider =
    NotifierProvider<VersionCheckNotifier, VersionCheckState>(
  VersionCheckNotifier.new,
);

/// Separate ticker for age display; updated every second by the version check
/// notifier. Watched by UI that shows "Xs ago" text. Keeps the main
/// [versionCheckProvider] clean from no-op self-assignment hacks.
class AgeTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final versionCheckAgeTicker =
    NotifierProvider<AgeTickNotifier, int>(AgeTickNotifier.new);
