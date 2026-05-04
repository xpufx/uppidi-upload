import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'version.dart';

enum VersionCheckState { idle, checking, upToDate, updateAvailable }

class VersionCheckNotifier extends Notifier<VersionCheckState> {
  String? _latestHash;
  DateTime? _lastChecked;
  int _tick = 0;
  Timer? _ticker;

  @override
  VersionCheckState build() {
    ref.onDispose(() => _ticker?.cancel());
    return VersionCheckState.idle;
  }

  Future<void> check() async {
    if (cdnUrl.isEmpty) return;
    _ticker?.cancel();
    state = VersionCheckState.checking;
    _lastChecked = DateTime.now();
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$cdnUrl/latest.txt'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        _latestHash = body.trim();
        state = (_latestHash!.isNotEmpty && _latestHash != gitHash)
            ? VersionCheckState.updateAvailable
            : VersionCheckState.upToDate;
      } else {
        state = VersionCheckState.idle;
        _lastChecked = null;
      }
      client.close();
    } catch (_) {
      state = VersionCheckState.idle;
      _lastChecked = null;
    }
    if (state == VersionCheckState.upToDate || state == VersionCheckState.updateAvailable) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == VersionCheckState.upToDate || state == VersionCheckState.updateAvailable) {
        _tick++;
        state = state;
      } else {
        _ticker?.cancel();
      }
    });
  }

  String? get latestHash => _latestHash;
  DateTime? get lastChecked => _lastChecked;
  int get tick => _tick;
}

final versionCheckProvider = NotifierProvider<VersionCheckNotifier, VersionCheckState>(
  VersionCheckNotifier.new,
);