// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'package:uppidi_upload/core/provider_config_sheet.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/models/provider_instance.dart';
import 'package:uppidi_upload/providers/telegram_provider.dart';
import 'package:uppidi_upload/providers/zulip_provider.dart';
import 'package:uppidi_upload/providers/custom_uguu_provider.dart';

/// In-memory key/value store that mirrors FlutterSecureStorage.
class _MemStore {
  final _store = <String, String>{};
  Future<void> write(String key, String value) async => _store[key] = value;
  Future<String?> read(String key) async => _store[key];
  Future<void> delete(String key) async => _store.remove(key);
  Future<Map<String, String>> readAll() async => Map.from(_store);
}

/// A FlutterSecureStoragePlatform implementation backed by an in-memory map.
class _PlatformStore extends FlutterSecureStoragePlatform {
  final _MemStore _store;
  _PlatformStore(this._store);

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async =>
      _store.write(key, value);

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async =>
      _store.read(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async =>
      _store.delete(key);

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      _store.readAll();

  @override
  Future<void> deleteAll({
    required Map<String, String> options,
  }) async =>
      _store.readAll();

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      (await _store.read(key)) != null;
}

/// Overrides the production FlutterSecureStorage with our in-memory store.
void _useMemStore(_MemStore store) {
  FlutterSecureStoragePlatform.instance = _PlatformStore(store);
}

void main() {
  late _MemStore mem;

  setUp(() {
    mem = _MemStore();
    _useMemStore(mem);
  });

  group('Registry', () {
    test('instanceTypes contains Zulip, Telegram, CustomUguu with descriptions',
        () {
      final types = ProviderRegistry.instanceTypes;
      final ids = types.map((t) => t.providerId).toSet();

      expect(ids, contains('telegram'));
      expect(ids, contains('zulip'));
      expect(ids, contains('custom_uguu'));

      for (final t in types) {
        expect(t.instanceDescription, isNotNull,
            reason:
                '${t.providerName} has null instanceDescription — will not appear in "Add provider"');
      }
    });

    test('baseFor returns correct base provider', () {
      expect(ProviderRegistry.baseFor('telegram'), isA<TelegramProvider>());
      expect(
          ProviderRegistry.baseFor('telegram__12345'), isA<TelegramProvider>());
      expect(ProviderRegistry.baseFor('zulip__abc'), isA<ZulipProvider>());
      expect(ProviderRegistry.baseFor('nonexistent'), isNull);
    });
  });

  group('Config key format', () {
    test('instance metadata save/load round-trip', () async {
      await saveProviderInstances('telegram', [
        const ProviderInstanceMeta(id: 'test123', name: 'Test Bot'),
      ]);
      final loaded = await loadProviderInstances('telegram');
      expect(loaded.length, 1);
      expect(loaded.first.id, 'test123');
      expect(loaded.first.name, 'Test Bot');
    });

    test('required config keys round-trip through storage', () async {
      final key = 'provider_config_telegram__rt1_bot_token';
      await mem.write(key, 'test_token_123');
      expect(await mem.read(key), 'test_token_123');
    });

    test('optional checkbox config (send_as_photo) round-trips', () async {
      final key = 'provider_config_telegram__cb1_send_as_photo';
      await mem.write(key, 'true');
      expect(await mem.read(key), 'true');
      await mem.write(key, 'false');
      expect(await mem.read(key), 'false');
    });

    test('Zulip optional text keys round-trip through storage', () async {
      await mem.write('provider_config_zulip__ot1_zulip_channel', 'general');
      await mem.write('provider_config_zulip__ot1_zulip_topic', 'test topic');
      await mem.write('provider_config_zulip__ot1_zulip_recipient', '42');

      expect(await mem.read('provider_config_zulip__ot1_zulip_channel'),
          'general');
      expect(await mem.read('provider_config_zulip__ot1_zulip_topic'),
          'test topic');
      expect(
          await mem.read('provider_config_zulip__ot1_zulip_recipient'), '42');
    });

    test('send_as_photo is listed in Telegram optionalConfigKeys', () {
      expect(TelegramProvider().optionalConfigKeys, contains('send_as_photo'));
    });

    test('Zulip instanceDescription is non-null', () {
      expect(ZulipProvider().instanceDescription, isNotNull);
    });

    test('Telegram instanceDescription is non-null', () {
      expect(TelegramProvider().instanceDescription, isNotNull);
    });

    test('CustomUguu instanceDescription is non-null', () {
      expect(CustomUguuProvider().instanceDescription, isNotNull);
    });
  });

  group('Instance metadata persistence', () {
    test('save then load preserves instance list', () async {
      await saveProviderInstances('telegram', [
        const ProviderInstanceMeta(id: 'a', name: 'Alpha'),
        const ProviderInstanceMeta(id: 'b', name: 'Beta'),
      ]);
      final loaded = await loadProviderInstances('telegram');
      expect(loaded.length, 2);
      expect(loaded[0].id, 'a');
      expect(loaded[0].name, 'Alpha');
    });

    test('load from empty storage returns empty list', () async {
      expect(await loadProviderInstances('telegram'), isEmpty);
    });

    test('delete removes instance and its config keys', () async {
      await saveProviderInstances('telegram', [
        const ProviderInstanceMeta(id: 'x', name: 'Delete Me'),
        const ProviderInstanceMeta(id: 'y', name: 'Keep Me'),
      ]);
      await mem.write('provider_config_telegram__x_bot_token', 'secret');

      await deleteProviderInstance(
          'telegram', const ProviderInstanceMeta(id: 'x', name: 'Delete Me'),
          configKeys: ['bot_token']);

      final remaining = await loadProviderInstances('telegram');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'y');
      expect(await mem.read('provider_config_telegram__x_bot_token'), isNull);
    });
  });

  group('Connectivity config loading', () {
    test('ProviderInstance delegates config keys correctly', () async {
      final base = TelegramProvider();
      final instance = ProviderInstance(base, 'conn1', 'Connectivity Test');
      expect(instance.optionalConfigKeys, base.optionalConfigKeys);
      expect(instance.requiredConfigKeys, base.requiredConfigKeys);
      expect(instance.optionalTextConfigKeys, base.optionalTextConfigKeys);
    });
  });
}
