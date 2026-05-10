import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:uppidi_upload/core/settings_service.dart';

void main() {
  const testBoxName = 'settings';

  setUpAll(() async {
    Hive.init('.hive_test_settings_service');
    await Hive.openBox<String>(testBoxName);
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk(testBoxName);
  });

  setUp(() async {
    // Start each test with a clean settings box
    final box = Hive.box<String>(testBoxName);
    await box.clear();
  });

  group('SettingsService — insecure connections', () {
    test('isInsecureConnAllowed returns false by default', () async {
      final svc = SettingsService();
      expect(await svc.isInsecureConnAllowed(), isFalse);
    });

    test('isInsecureConnAllowed returns true when key is "true"', () async {
      final svc = SettingsService();
      await svc.set(SettingsService.insecureConnKey, 'true');
      expect(await svc.isInsecureConnAllowed(), isTrue);
    });

    test('isInsecureConnAllowed returns false after key is removed', () async {
      final svc = SettingsService();
      await svc.set(SettingsService.insecureConnKey, 'true');
      await svc.remove(SettingsService.insecureConnKey);
      expect(await svc.isInsecureConnAllowed(), isFalse);
    });

    test('isInsecureConnAllowed returns false when value is arbitrary text',
        () async {
      final svc = SettingsService();
      await svc.set(SettingsService.insecureConnKey, 'not_a_boolean');
      expect(await svc.isInsecureConnAllowed(), isFalse);
    });
  });

  group('SettingsService — proxy URL', () {
    test('getProxyUrl returns null by default', () async {
      final svc = SettingsService();
      expect(await svc.getProxyUrl(), isNull);
    });

    test('getProxyUrl returns the set proxy URL', () async {
      final svc = SettingsService();
      await svc.set(SettingsService.proxyUrlKey, 'http://proxy.example:8080');
      expect(await svc.getProxyUrl(), 'http://proxy.example:8080');
    });

    test('getProxyUrl returns null after key is removed', () async {
      final svc = SettingsService();
      await svc.set(SettingsService.proxyUrlKey, 'http://proxy.example:8080');
      await svc.remove(SettingsService.proxyUrlKey);
      expect(await svc.getProxyUrl(), isNull);
    });

    test('getProxyUrl returns updated value after overwrite', () async {
      final svc = SettingsService();
      await svc.set(SettingsService.proxyUrlKey, 'http://old:8080');
      await svc.set(SettingsService.proxyUrlKey, 'http://new:9090');
      expect(await svc.getProxyUrl(), 'http://new:9090');
    });
  });

  group('SettingsService — debug logging', () {
    test('isDebugLoggingEnabled returns false by default', () async {
      final svc = SettingsService();
      expect(await svc.isDebugLoggingEnabled(), isFalse);
    });

    test('setDebugLoggingEnabled(true) persists the setting', () async {
      final svc = SettingsService();
      await svc.setDebugLoggingEnabled(true);
      expect(await svc.isDebugLoggingEnabled(), isTrue);
    });

    test('setDebugLoggingEnabled(false) persists the setting', () async {
      final svc = SettingsService();
      await svc.setDebugLoggingEnabled(true);
      await svc.setDebugLoggingEnabled(false);
      expect(await svc.isDebugLoggingEnabled(), isFalse);
    });

    test('setDebugLoggingEnabled persists across service instances', () async {
      final svc1 = SettingsService();
      await svc1.setDebugLoggingEnabled(true);

      final svc2 = SettingsService();
      expect(await svc2.isDebugLoggingEnabled(), isTrue);
    });
  });
}
