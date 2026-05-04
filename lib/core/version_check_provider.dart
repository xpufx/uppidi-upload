import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'version.dart';

enum VersionCheckState { idle, checking, upToDate, updateAvailable }

class VersionCheckNotifier extends Notifier<VersionCheckState> {
  String? _latestHash;

  @override
  VersionCheckState build() => VersionCheckState.idle;

  Future<void> check() async {
    if (cdnUrl.isEmpty) return;
    state = VersionCheckState.checking;
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
      }
      client.close();
    } catch (_) {
      state = VersionCheckState.idle;
    }
    // Auto-reset to idle after a few seconds for upToDate
    if (state == VersionCheckState.upToDate) {
      await Future.delayed(const Duration(seconds: 3));
      if (state == VersionCheckState.upToDate) state = VersionCheckState.idle;
    }
  }

  String? get latestHash => _latestHash;
}

final versionCheckProvider = NotifierProvider<VersionCheckNotifier, VersionCheckState>(
  VersionCheckNotifier.new,
);