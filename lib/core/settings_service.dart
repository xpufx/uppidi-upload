import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

final localeCodeProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return (await svc.get(SettingsService.localeKey)) ?? 'en';
});

final disabledProviderIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.read(settingsServiceProvider).getDisabledProviders();
});

final providerHealthProvider = FutureProvider<Map<String, ProviderHealthInfo>>((ref) async {
  final cdnUrl = const String.fromEnvironment('CDN_URL', defaultValue: '');
  if (cdnUrl.isEmpty) return {};
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('$cdnUrl/providers.json'));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      client.close();
      return json.map((k, v) {
        final info = v as Map<String, dynamic>;
        return MapEntry(k, ProviderHealthInfo(
          disabled: info['disabled'] as bool? ?? false,
          since: info['since'] as String?,
          reason: info['reason'] as String?,
        ));
      });
    }
    client.close();
  } catch (_) {}
  return {};
});

class ProviderHealthInfo {
  final bool disabled;
  final String? since;
  final String? reason;
  const ProviderHealthInfo({required this.disabled, this.since, this.reason});
}

class SettingsService {
  final FlutterSecureStorage _storage;

  SettingsService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> get(String key) => _storage.read(key: key);
  Future<void> set(String key, String value) => _storage.write(key: key, value: value);
  Future<void> remove(String key) => _storage.delete(key: key);
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
  Future<Map<String, String>> readAll() => _storage.readAll();

  String providerKey(String providerId, String configKey) =>
      '$providerId.$configKey';

  Future<Map<String, String>> loadProviderConfig(String providerId,
      List<String> configKeys) async {
    final config = <String, String>{};
    for (final key in configKeys) {
      final value = await get(providerKey(providerId, key));
      if (value != null) config[key] = value;
    }
    return config;
  }

  static const insecureConnKey = 'global.allow_insecure_conn';
  static const proxyUrlKey = 'global.proxy_url';
  static const localeKey = 'global.locale';
  static const defaultShareProviderKey = 'global.default_share_provider';
  static const themeModeKey = 'global.theme_mode';
  static const seedColorKey = 'global.seed_color';
  static const logoPathKey = 'global.logo_path';
  static const disabledProvidersKey = 'global.disabled_providers';
  static const debugLoggingKey = 'global.debug_logging';
  static const navigationLayoutKey = 'global.navigation_layout';

  Future<bool> isInsecureConnAllowed() async {
    final val = await get(insecureConnKey);
    return val == 'true';
  }

  Future<String?> getProxyUrl() => get(proxyUrlKey);

  Future<ThemeMode> getThemeMode() async {
    final val = await get(themeModeKey);
    return switch (val) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<Color> getSeedColor() async {
    final val = await get(seedColorKey);
    if (val != null && val.length == 8) {
      return Color(int.parse(val, radix: 16));
    }
    return Colors.deepPurple;
  }

  Future<String?> getLogoPath() => get(logoPathKey);

  Future<Set<String>> getDisabledProviders() async {
    final raw = await get(disabledProvidersKey);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> setDisabledProviders(Set<String> ids) async {
    if (ids.isEmpty) {
      await remove(disabledProvidersKey);
    } else {
      await set(disabledProvidersKey, ids.join(','));
    }
  }

  Future<bool> isDebugLoggingEnabled() async {
    final val = await get(debugLoggingKey);
    return val == 'true';
  }

  Future<void> setDebugLoggingEnabled(bool enabled) async {
    await set(debugLoggingKey, enabled ? 'true' : 'false');
  }

  Future<String> getNavigationLayout() async {
    final val = await get(navigationLayoutKey);
    return val ?? 'bottom';
  }

  Future<void> setNavigationLayout(String layout) async {
    if (!['left', 'bottom', 'right'].contains(layout)) {
      throw ArgumentError(
        'Invalid navigation layout: $layout. Must be one of left, bottom, right.',
      );
    }
    await set(navigationLayoutKey, layout);
  }
}
