import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'version.dart';

enum VersionCheckState { idle, checking, upToDate, updateAvailable }

class VersionCheckNotifier extends Notifier<VersionCheckState> {
  String? _latestHash;
  String? _downloadUrl;
  DateTime? _lastChecked;
  int _tick = 0;
  Timer? _ticker;

  @override
  VersionCheckState build() {
    ref.onDispose(() => _ticker?.cancel());
    return VersionCheckState.idle;
  }

  Future<void> check() async {
    _ticker?.cancel();
    state = VersionCheckState.checking;
    _lastChecked = DateTime.now();
    try {
      if (cdnUrl.isNotEmpty) {
        await _checkFromCdn();
      } else {
        await _checkFromGitHub();
      }
    } catch (_) {
      state = VersionCheckState.idle;
      _lastChecked = null;
    }
    if (state == VersionCheckState.upToDate ||
        state == VersionCheckState.updateAvailable) {
      _startTicker();
    }
  }

  Future<void> _checkFromCdn() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$cdnUrl/latest.txt'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        _latestHash = body.trim();
        _buildDownloadUrl();
        state = (_latestHash!.isNotEmpty && _latestHash != gitHash)
            ? VersionCheckState.updateAvailable
            : VersionCheckState.upToDate;
      } else {
        state = VersionCheckState.idle;
        _lastChecked = null;
      }
    } finally {
      client.close();
    }
  }

  Future<void> _checkFromGitHub() async {
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
        _latestHash = tagName.startsWith('v') ? tagName.substring(1) : tagName;

        // Pick the right asset for this platform
        final assets = json['assets'] as List? ?? [];
        if (Platform.isAndroid) {
          final apk = assets.cast<Map<String, dynamic>>().where(
                (a) => (a['name'] as String).endsWith('.apk'),
              );
          _downloadUrl = apk.isNotEmpty
              ? apk.last['browser_download_url'] as String?
              : null;
        } else {
          final desktopAssets = assets.cast<Map<String, dynamic>>().where(
            (a) {
              final name = a['name'] as String;
              return name.endsWith('.AppImage') || name.endsWith('.tar.gz');
            },
          );
          // Prefer AppImage over tar.gz
          final appImage = desktopAssets.where(
            (a) => (a['name'] as String).endsWith('.AppImage'),
          );
          _downloadUrl = appImage.isNotEmpty
              ? appImage.first['browser_download_url'] as String?
              : desktopAssets.isNotEmpty
                  ? desktopAssets.first['browser_download_url'] as String?
                  : null;
        }

        state = (_latestHash!.isNotEmpty && _latestHash != appVersion)
            ? VersionCheckState.updateAvailable
            : VersionCheckState.upToDate;
      } else {
        state = VersionCheckState.idle;
        _lastChecked = null;
      }
    } finally {
      client.close();
    }
  }

  void _buildDownloadUrl() {
    // Build CDN download URL the same way settings_screen does
    final isMobile = Platform.isAndroid;
    _downloadUrl = isMobile
        ? '$cdnUrl/uppidi-upload-latest-android-arm64-v8a.apk'
        : '$cdnUrl/uppidi-upload-latest-linux.tar.gz';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == VersionCheckState.upToDate ||
          state == VersionCheckState.updateAvailable) {
        _tick++;
        state = state;
      } else {
        _ticker?.cancel();
      }
    });
  }

  String? get latestHash => _latestHash;
  String? get downloadUrl => _downloadUrl;
  DateTime? get lastChecked => _lastChecked;
  int get tick => _tick;
}

final versionCheckProvider =
    NotifierProvider<VersionCheckNotifier, VersionCheckState>(
  VersionCheckNotifier.new,
);
