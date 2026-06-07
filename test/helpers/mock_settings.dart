import 'package:flutter/material.dart';
import 'package:uppidi_upload/core/settings_service.dart';

class MockSettingsService implements SettingsService {
  final _store = <String, String>{};

  @override
  Future<bool> isInsecureConnAllowed() async =>
      _store[SettingsService.insecureConnKey] == 'true';

  @override
  Future<String?> getProxyUrl() async => _store[SettingsService.proxyUrlKey];

  @override
  Future<String?> getUserAgent() async => _store[SettingsService.userAgentKey];

  @override
  Future<bool> isDebugLoggingEnabled() async =>
      _store[SettingsService.debugLoggingKey] == 'true';

  @override
  Future<void> setDebugLoggingEnabled(bool enabled) async {
    _store[SettingsService.debugLoggingKey] = enabled ? 'true' : 'false';
  }

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll() async =>
      Map<String, String>.from(_store);

  @override
  String providerKey(String providerId, String configKey) =>
      '$providerId.$configKey';

  @override
  Future<Map<String, String>> loadProviderConfig(
          String providerId, List<String> requiredKeys) async =>
      {};

  @override
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

  @override
  Future<Color> getSeedColor() async => const Color(0xFF6750A4);

  @override
  Future<Set<String>> getDisabledProviders() async => {};

  @override
  Future<void> setDisabledProviders(Set<String> ids) async {}

  @override
  Future<Set<String>> getInsecureMutedProviders() async => {};

  @override
  Future<void> muteInsecureWarning(String providerId) async {}

  @override
  Future<bool> isInsecureWarningMuted(String providerId) async => false;

  @override
  Future<String> getNavigationLayout() async => 'bottom';

  @override
  Future<void> setNavigationLayout(String layout) async {}

  @override
  Future<String> getShellType() async => 'tabs';

  @override
  Future<void> setShellType(String type) async {}
}
