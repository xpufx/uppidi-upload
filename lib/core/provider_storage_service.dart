import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secure = FlutterSecureStorage();

/// Builds the secure-storage key for a provider config value.
/// For a providerId like `telegram__12345` and key `bot_token`:
/// → `provider_config_telegram__12345_bot_token`
String configStorageKey(String providerId, String key) =>
    'provider_config_${providerId}_$key';

/// Metadata for a single provider instance.
class ProviderInstanceMeta {
  final String id;
  final String name;
  final bool urlOnly;

  const ProviderInstanceMeta({
    required this.id,
    required this.name,
    this.urlOnly = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'urlOnly': urlOnly};

  factory ProviderInstanceMeta.fromJson(Map<String, dynamic> json) =>
      ProviderInstanceMeta(
        id: json['id'] as String,
        name: json['name'] as String,
        urlOnly: json['urlOnly'] as bool? ?? false,
      );
}

/// Loads the list of instances for a provider.
Future<List<ProviderInstanceMeta>> loadProviderInstances(
    String providerId) async {
  final raw = await _secure.read(key: 'provider_instances_$providerId');
  if (raw == null) return [];
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => ProviderInstanceMeta.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Persists the instance list for a provider.
Future<void> saveProviderInstances(
    String providerId, List<ProviderInstanceMeta> instances) async {
  await _secure.write(
    key: 'provider_instances_$providerId',
    value: jsonEncode(instances.map((e) => e.toJson()).toList()),
  );
}

/// Deletes an instance: removes its config keys and removes it from the
/// instance list.
Future<void> deleteProviderInstance(
    String providerId, ProviderInstanceMeta instance,
    {required List<String> configKeys}) async {
  for (final key in configKeys) {
    await _secure.delete(
        key: configStorageKey('${providerId}__${instance.id}', key));
  }
  final remaining = (await loadProviderInstances(providerId))
      .where((i) => i.id != instance.id)
      .toList();
  if (remaining.isEmpty) {
    await _secure.delete(key: 'provider_instances_$providerId');
  } else {
    await saveProviderInstances(providerId, remaining);
  }
}
