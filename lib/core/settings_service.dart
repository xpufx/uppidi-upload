import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

final localeCodeProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return (await svc.get(SettingsService.localeKey)) ?? 'en';
});

final navigationLayoutProvider = FutureProvider<String>((ref) async {
  final svc = ref.read(settingsServiceProvider);
  return await svc.getNavigationLayout();
});

final disabledProviderIdsProvider = FutureProvider<Set<String>>((ref) async {
  return ref.read(settingsServiceProvider).getDisabledProviders();
});

final providerHealthProvider =
    FutureProvider<Map<String, ProviderHealthInfo>>((ref) async {
  final cdnUrl = const String.fromEnvironment('CDN_URL', defaultValue: '');
  if (cdnUrl.isEmpty) return {};
  try {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$cdnUrl/providers.json'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json.map((k, v) {
          final info = v as Map<String, dynamic>;
          return MapEntry(
              k,
              ProviderHealthInfo(
                disabled: info['disabled'] as bool? ?? false,
                since: info['since'] as String?,
                reason: info['reason'] as String?,
              ));
        });
      }
    } finally {
      client.close(force: true);
    }
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
  Box<String>? _box;

  SettingsService();

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>('settings');
    return _box!;
  }

  Future<String?> get(String key) async {
    final box = await _getBox();
    return box.get(key);
  }

  Future<void> set(String key, String value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  Future<void> remove(String key) async {
    final box = await _getBox();
    await box.delete(key);
  }

  Future<bool> containsKey(String key) async {
    final box = await _getBox();
    return box.containsKey(key);
  }

  Future<Map<String, String>> readAll() async {
    final box = await _getBox();
    return Map<String, String>.from(box.toMap());
  }

  String providerKey(String providerId, String configKey) =>
      '$providerId.$configKey';

  Future<Map<String, String>> loadProviderConfig(
      String providerId, List<String> configKeys) async {
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
  static const disabledProvidersKey = 'global.disabled_providers';
  static const debugLoggingKey = 'global.debug_logging';
  static const shellTypeKey = 'global.shell_type';
  static const insecureMutedKey = 'global.insecure_muted_providers';
  static const navigationLayoutKey = 'global.nav_layout';
  static const shareMessageKey = 'global.share_message';
  static const lastUsedProviderKey = 'global.last_used_provider';
  static const sectionBuiltinCollapsed = 'global.section_builtin_collapsed';
  static const sectionMyProvidersCollapsed =
      'global.section_myproviders_collapsed';

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

  Future<Set<String>> getInsecureMutedProviders() async {
    final raw = await get(insecureMutedKey);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> muteInsecureWarning(String providerId) async {
    final muted = await getInsecureMutedProviders();
    muted.add(providerId);
    await set(insecureMutedKey, muted.join(','));
  }

  Future<bool> isInsecureWarningMuted(String providerId) async {
    final muted = await getInsecureMutedProviders();
    return muted.contains(providerId);
  }

  Future<bool> isDebugLoggingEnabled() async {
    final val = await get(debugLoggingKey);
    return val == 'true';
  }

  Future<void> setDebugLoggingEnabled(bool enabled) async {
    await set(debugLoggingKey, enabled ? 'true' : 'false');
  }

  Future<String> getShellType() async {
    final val = await get(shellTypeKey);
    return val ?? 'tabs';
  }

  Future<void> setShellType(String type) async {
    if (!['tabs', 'modals'].contains(type)) {
      throw ArgumentError(
        'Invalid shell type: $type. Must be one of tabs, modals.',
      );
    }
    await set(shellTypeKey, type);
  }

  Future<String> getNavigationLayout() async {
    final val = await get(navigationLayoutKey);
    return val ?? 'left';
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
