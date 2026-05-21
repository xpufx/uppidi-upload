import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/core/settings_service.dart';

/// Mock uploader for testing
class MockTestUploader implements BaseUploader {
  final String id;
  final String name;
  final bool isImageProvider;

  MockTestUploader({
    this.id = 'mock_provider',
    this.name = 'Mock Provider',
    this.isImageProvider = false,
  });

  @override
  String get providerId => id;

  @override
  String get providerName => name;

  @override
  bool get supportsWeb => true;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get proxyUrl => null;

  @override
  ProviderMetadata get metadata => ProviderMetadata(
        allowedMimeTypes: isImageProvider ? {'image/*'} : null,
      );

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async =>
      Dio();

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async =>
      UploadResult(success: true);
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('TestScreen Provider List Tests', () {
    testWidgets('Shows all 6 providers listed', (WidgetTester tester) async {
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

      // Each provider name must be findable. Scroll to each one individually
      // since the list is rendered as lazy slivers.
      for (final provider in ProviderRegistry.all) {
        try {
          await tester.ensureVisible(find.text(provider.providerName));
        } catch (_) {
          // scrollUntilVisible will fail if the item is already visible
          // or the list is very short — just pump to be safe
          await tester.pump();
        }
        expect(find.text(provider.providerName), findsWidgets);
      }
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

      // Each provider should have a play icon. Scroll to each name to account
      // for lazy sliver rendering.
      for (final provider in ProviderRegistry.all) {
        await tester.ensureVisible(find.text(provider.providerName));
        await tester.pump();
        expect(find.byIcon(Icons.play_arrow), findsWidgets);
      }
    });
  });
}
