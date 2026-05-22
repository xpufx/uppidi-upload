import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/screens/settings_screen.dart';

/// A controllable MockSettingsService for widget tests.
class MockSettingsService implements SettingsService {
  final _store = <String, String>{};

  @override
  Future<bool> isInsecureConnAllowed() async =>
      _store[SettingsService.insecureConnKey] == 'true';

  @override
  Future<String?> getProxyUrl() async => _store[SettingsService.proxyUrlKey];

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

Widget buildTestApp({
  required MockSettingsService mockSettings,
}) {
  return ProviderScope(
    overrides: [
      settingsServiceProvider.overrideWithValue(mockSettings),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsScreen()),
    ),
  );
}

void main() {
  late AppLocalizations l10n;
  late MockSettingsService mockSettings;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    mockSettings = MockSettingsService();
  });

  group('SettingsScreen — insecure connection toggle', () {
    testWidgets('shows the insecure connection switch', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      expect(find.text(l10n.enableInsecure), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('switch defaults to off', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Find the insecure connection switch (the first Switch in the column)
      final switches = find.byType(Switch);
      final firstSwitch = tester.widget<Switch>(switches.first);
      expect(firstSwitch.value, isFalse);
    });

    testWidgets('turning switch on persists the setting', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Toggle the insecure connection switch on
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Verify the value was saved
      expect(await mockSettings.isInsecureConnAllowed(), isTrue);
    });

    testWidgets('turning switch off and on toggles the setting',
        (tester) async {
      // Start with it in one state
      await mockSettings.set(SettingsService.insecureConnKey, 'true');

      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Should be on initially
      var switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.first).value, isTrue);

      // Toggle off
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      expect(await mockSettings.isInsecureConnAllowed(), isFalse);

      // Toggle back on
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      expect(await mockSettings.isInsecureConnAllowed(), isTrue);
    });

    testWidgets('info icon opens the insecure connection dialog',
        (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Tap the info icon next to insecure connection toggle
      await tester.tap(find.byIcon(Icons.info_outline).first);
      await tester.pumpAndSettle();

      // Dialog should appear with the warning text
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n.selfSignedCertWarning), findsOneWidget);

      // Tap OK to dismiss
      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsScreen — proxy URL', () {
    testWidgets('shows the proxy URL text field', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.proxyHint), findsOneWidget);
    });

    testWidgets('displays saved proxy URL', (tester) async {
      await mockSettings.set(SettingsService.proxyUrlKey, 'http://proxy:8080');

      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // The text field should contain the saved proxy URL
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'http://proxy:8080');
    });

    testWidgets('typing in proxy field persists after debounce',
        (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Type a proxy URL
      await tester.enterText(find.byType(TextField), 'http://new-proxy:3128');
      // Advance past the debounce timer (500ms)
      await tester.pump(const Duration(milliseconds: 600));

      // Verify the value was saved
      expect(await mockSettings.getProxyUrl(), 'http://new-proxy:3128');
    });

    testWidgets('clearing proxy field removes the setting', (tester) async {
      // Pre-set a proxy URL
      await mockSettings.set(SettingsService.proxyUrlKey, 'http://proxy:8080');

      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Clear the text field
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 600));

      // Verify the value was removed
      expect(await mockSettings.getProxyUrl(), isNull);
    });
  });

  group('SettingsScreen — debug logging toggle', () {
    testWidgets('shows the debug logging switch', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      expect(find.text(l10n.debugLogging), findsOneWidget);
    });

    testWidgets('debug logging switch defaults to off', (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Find the debug logging switch — it's the second Switch widget
      final switches = find.byType(Switch);
      expect(switches, findsAtLeastNWidgets(2));

      // The last switch visible should be the debug logging one
      final lastSwitch = tester.widget<Switch>(switches.last);
      expect(lastSwitch.value, isFalse);
    });

    testWidgets('turning debug logging on persists and shows snackbar',
        (tester) async {
      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Toggle the last switch (debug logging) — scroll if needed
      final switches = find.byType(Switch);
      await tester.ensureVisible(switches.last);
      await tester.pumpAndSettle();
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // Verify the value was saved
      expect(await mockSettings.isDebugLoggingEnabled(), isTrue);

      // Snackbar should appear
      expect(find.text('${l10n.debugLogging} ${l10n.enabled}'), findsOneWidget);
    });

    testWidgets('turning debug logging off persists and shows snackbar',
        (tester) async {
      await mockSettings.setDebugLoggingEnabled(true);

      await tester.pumpWidget(buildTestApp(mockSettings: mockSettings));
      await tester.pumpAndSettle();

      // Toggle the last switch (debug logging) off — scroll if needed
      final switches = find.byType(Switch);
      await tester.ensureVisible(switches.last);
      await tester.pumpAndSettle();
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // Verify the value was saved
      expect(await mockSettings.isDebugLoggingEnabled(), isFalse);

      // Snackbar should appear
      expect(
          find.text('${l10n.debugLogging} ${l10n.disabled}'), findsOneWidget);
    });
  });
}
