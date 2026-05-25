import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secure = FlutterSecureStorage();

/// Loads all stored config keys for a given [providerId] from
/// FlutterSecureStorage.
///
/// Reads every key matching `provider_config_{providerId}_` and returns a
/// map of `{configKey: value}`.  Consumers never read secure storage
/// directly — they watch this provider.
///
/// Invalidation:
///   ref.invalidate(providerConfigProvider(someId))
///
/// The next watcher rebuild triggers a fresh readAll.
Future<Map<String, String>> _loadProviderConfig(String providerId) async {
  try {
    final allKeys = await _secure.readAll();
    final prefix = 'provider_config_${providerId}_';
    return {
      for (final e in allKeys.entries)
        if (e.key.startsWith(prefix)) e.key.substring(prefix.length): e.value,
    };
  } catch (_) {
    return <String, String>{};
  }
}

final providerConfigProvider =
    FutureProvider.family<Map<String, String>, String>(
  (ref, providerId) => _loadProviderConfig(providerId),
);

final providerInstancesProvider = FutureProvider.family<List<dynamic>, String>(
  (ref, providerId) async {
    final raw = await _secure.read(key: 'provider_instances_$providerId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list;
  },
);
