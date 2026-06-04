import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:hive/hive.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    Hive.init('.hive_test_test_screen');
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk('settings');
  });

  group('TestScreen Provider List Tests', () {
    testWidgets('Shows built-in providers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // All providers enabled (no disabled IDs)
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
            // Mock health provider - all healthy
            providerHealthProvider.overrideWith((ref) => Future.value({})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand Built-in section (collapsed by default)
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Built-in providers (non-auth) should be visible
      for (final provider in ProviderRegistry.all) {
        if (provider.metadata.capabilities
            .contains(ProviderCapability.requiresAuth)) {
          continue;
        }
        try {
          await tester.ensureVisible(find.text(provider.providerName));
        } catch (_) {
          await tester.pump();
        }
        expect(find.text(provider.providerName), findsWidgets);
      }

      // My Providers section shows "No instances configured" since
      // we haven't set up any auth provider instances.
      expect(find.text(l10n.noInstancesConfigured), findsOneWidget);
    });
  });

  group('Test All Button Tests', () {
    testWidgets('Test All button visible when providers enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
            providerHealthProvider.overrideWith((ref) => Future.value({})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test All button should be visible
      expect(find.text(l10n.testAll), findsOneWidget);
    });

    testWidgets(
        'Test All button has onPressed null when all providers disabled',
        (WidgetTester tester) async {
      // Disable all providers
      final allIds = ProviderRegistry.all.map((p) => p.providerId).toSet();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(allIds)),
            providerHealthProvider.overrideWith((ref) => Future.value({})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When no providers are enabled, the Test All button should be disabled
      // Find the FilledButton with "Test All" text
      final testAllFinder = find.ancestor(
        of: find.text(l10n.testAll),
        matching: find.byType(FilledButton),
      );
      expect(testAllFinder, findsOneWidget);

      final button = tester.widget<FilledButton>(testAllFinder);
      expect(button.onPressed, isNull);
    });
  });

  group('Health Warning Tests', () {
    testWidgets('Shows warning icon and text when provider health-disabled',
        (WidgetTester tester) async {
      const testProviderId = 'httpbin';
      const reason = 'Server maintenance';

      final mockHealth = {
        testProviderId: ProviderHealthInfo(disabled: true, reason: reason),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
            providerHealthProvider
                .overrideWith((ref) => Future.value(mockHealth)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand Built-in section to see the provider
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Warning icon should be visible
      expect(find.byIcon(Icons.warning_amber), findsWidgets);

      // The reason text should be visible
      expect(find.text(reason), findsOneWidget);
    });

    testWidgets('Health-disabled provider switch is still toggleable',
        (WidgetTester tester) async {
      final mockHealth = {
        'httpbin': ProviderHealthInfo(disabled: true, reason: 'Maintenance'),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
            providerHealthProvider
                .overrideWith((ref) => Future.value(mockHealth)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand Built-in section to see provider toggles
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Find all switches
      final switches = tester.widgetList<Switch>(find.byType(Switch));
      expect(switches, isNotEmpty);

      // All switches should be toggleable even when health-disabled (user override is allowed)
      final allToggleable = switches.every((s) => s.onChanged != null);
      expect(allToggleable, isTrue);
    });
  });

  group('Individual Test Button Tests', () {
    testWidgets('Play icon visible per provider', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
            providerHealthProvider.overrideWith((ref) => Future.value({})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expand Built-in section to see providers
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Each provider should have a play icon. Scroll to each name to account
      // for lazy sliver rendering. Skip auth providers (not shown without
      // configured instances).
      for (final provider in ProviderRegistry.all) {
        if (provider.metadata.capabilities
            .contains(ProviderCapability.requiresAuth)) {
          continue;
        }
        await tester.ensureVisible(find.text(provider.providerName));
        await tester.pump();
        expect(find.byIcon(Icons.play_arrow), findsWidgets);
      }
    });
  });
}
