import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

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

  Future<bool> isInsecureConnAllowed() async {
    final val = await get(insecureConnKey);
    return val == 'true';
  }

  Future<String?> getProxyUrl() => get(proxyUrlKey);
}
