import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:uppidi_upload/core/config_provider.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/provider_instance.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

/// A mock Dio adapter that returns a successful response without network I/O.
class _MockSuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('{"status":"ok"}', 200);
  }

  @override
  void close({bool force = false}) {}
}

/// A mock uploader that uses [_MockSuccessAdapter], so connectivity checks
/// always succeed fast.
class _MockConnectivityUploader implements BaseUploader {
  @override
  String get providerId => 'mock_success';

  @override
  String get providerName => 'Mock Success';

  @override
  bool get supportsWeb => true;
  @override
  bool get supportsMessage => false;

  @override
  bool get isUrlShareOnly => false;

  @override
  List<String> get requiredConfigKeys => const [];

  @override
  Map<String, String> get configLabels => const {};

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get proxyUrl => null;

  @override
  String? get instanceDescription => null;

  @override
  List<String> get optionalTextConfigKeys => const [];

  @override
  ProviderMetadata get metadata => ProviderMetadata();

  @override
  Future<Dio> createHttpClient(
    Map<String, String> config, {
    bool allowInsecureConn = false,
    String? proxyUrl,
  }) async {
    final dio = Dio();
    dio.httpClientAdapter = _MockSuccessAdapter();
    return dio;
  }

  @override
  Future<UploadResult> upload(
    FileUploadRequest request, {
    UploadProgressCallback? onProgress,
    CancelToken? cancelToken,
    Map<String, String> config = const {},
  }) async {
    return UploadResult(success: true);
  }
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    Hive.init('.hive_test_provider_ui');
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  tearDownAll(() {
    try {
      Directory('.hive_test_provider_ui').deleteSync(recursive: true);
    } catch (_) {
      // Directory may not exist if no box was created
    }
  });

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Builds a TestScreen wrapped in a ProviderScope with optional overrides.
  Widget buildTestScreen({
    Set<String> disabledIds = const {},
    Map<String, ProviderHealthInfo> health = const {},
    bool? builtinCollapsed,
    bool? myProvidersCollapsed,
    extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        disabledProviderIdsProvider
            .overrideWith((ref) => Future.value(disabledIds)),
        providerHealthProvider.overrideWith((ref) => Future.value(health)),
        if (builtinCollapsed != null)
          sectionBuiltinCollapsedProvider
              .overrideWith((ref) => Future.value(builtinCollapsed)),
        if (myProvidersCollapsed != null)
          sectionMyProvidersCollapsedProvider
              .overrideWith((ref) => Future.value(myProvidersCollapsed)),
        ...extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: const TestScreen()),
      ),
    );
  }

  // ── Section Collapse / Expand ───────────────────────────────────────────

  group('Section Collapse/Expand', () {
    testWidgets('Built-in providers visible after tap', (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

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
    });

    testWidgets('My Providers section shows empty state when no instances',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text(l10n.noInstancesConfigured), findsOneWidget);
    });
  });

  // ── Connectivity Flow ───────────────────────────────────────────────────

  group('Connectivity Flow', () {
    late List<BaseUploader> saved;

    setUp(() {
      saved = List.of(ProviderRegistry.all);
      ProviderRegistry.all = [_MockConnectivityUploader()];
    });

    tearDown(() {
      ProviderRegistry.all = saved;
    });

    testWidgets('Play button visible on provider row', (tester) async {
      await tester.pumpWidget(buildTestScreen(builtinCollapsed: false));
      await tester.pumpAndSettle();

      // Expand built-in section
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Tap play button triggers loading then success result',
        (tester) async {
      await tester.pumpWidget(buildTestScreen(builtinCollapsed: false));
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Tap the play button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Loading indicator should appear briefly
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the mock HTTP to resolve
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Success icon should appear
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  // ── Switch Toggle ───────────────────────────────────────────────────────

  group('Provider Switch', () {
    testWidgets('Switch value reflects disabled provider IDs override',
        (tester) async {
      // Disable one specific provider
      const disabledProviderId = 'httpbin';

      await tester.pumpWidget(
        buildTestScreen(
          builtinCollapsed: false,
          disabledIds: {disabledProviderId},
        ),
      );
      await tester.pumpAndSettle();

      // Expand
      await tester.tap(find.text(l10n.builtInProviders));
      await tester.pumpAndSettle();

      // Find the httpbin provider's switch
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // When disabled, its switch should show false
      // (The switch order matches provider list order; httpbin is among them)
      final anyDisabled =
          tester.widgetList<Switch>(switches).any((s) => s.value == false);
      expect(anyDisabled, isTrue);

      // All switches should have a valid onChanged handler
      final allToggleable =
          tester.widgetList<Switch>(switches).every((s) => s.onChanged != null);
      expect(allToggleable, isTrue);
    });
  });

  // ── My Providers ────────────────────────────────────────────────────────

  group('My Providers', () {
    late List<BaseUploader> saved;

    setUp(() {
      saved = List.of(ProviderRegistry.all);
    });

    tearDown(() {
      ProviderRegistry.all = saved;
    });

    testWidgets('ProviderInstance appears in My Providers section',
        (tester) async {
      final telegram = ProviderRegistry.baseFor('telegram');
      expect(telegram, isNotNull);

      final instance = ProviderInstance(telegram!, 'test_123', 'Test Bot');
      ProviderRegistry.all = [instance];

      await tester.pumpWidget(buildTestScreen(myProvidersCollapsed: false));
      await tester.pumpAndSettle();

      // Display name should appear: "Telegram (Test Bot)"
      expect(find.text(instance.displayName), findsOneWidget);
    });

    testWidgets('ProviderInstance shows configure button', (tester) async {
      final telegram = ProviderRegistry.baseFor('telegram');
      expect(telegram, isNotNull);

      final instance = ProviderInstance(telegram!, 'test_456', 'Config Test');
      ProviderRegistry.all = [instance];

      await tester.pumpWidget(buildTestScreen(myProvidersCollapsed: false));
      await tester.pumpAndSettle();

      // Configure icon should be visible for ProviderInstance rows
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Add Provider button visible in My Providers section',
        (tester) async {
      await tester.pumpWidget(buildTestScreen(myProvidersCollapsed: false));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addProvider), findsOneWidget);

      // The add button is a TextButton.icon
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  // ── Config Dialog Rendering ─────────────────────────────────────────────

  group('Config Dialog', () {
    late List<BaseUploader> saved;

    setUp(() {
      saved = List.of(ProviderRegistry.all);
    });

    tearDown(() {
      ProviderRegistry.all = saved;
    });

    testWidgets('Config dialog opens with form fields for ProviderInstance',
        (tester) async {
      final telegram = ProviderRegistry.baseFor('telegram');
      expect(telegram, isNotNull);

      final instance =
          ProviderInstance(telegram!, 'cfg_test', 'Config Dialog Test');
      ProviderRegistry.all = [instance];

      await tester.pumpWidget(
        buildTestScreen(
          myProvidersCollapsed: false,
          extraOverrides: [
            providerConfigProvider(instance.providerId)
                .overrideWith((ref) => Future.value(<String, String>{})),
            providerInstancesProvider('telegram')
                .overrideWith((ref) => Future.value([
                      {'id': 'cfg_test', 'name': 'Config Dialog Test'}
                    ])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the configure button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Dialog should be shown
      expect(find.byType(Dialog), findsOneWidget);

      // Required config keys should have visible fields
      for (final key in telegram.requiredConfigKeys) {
        final label = telegram.configLabels[key] ?? key;
        // Labels like "Bot Token", "Chat ID" should be visible
        expect(find.text(label), findsWidgets);
      }

      // Instance name field should be visible
      expect(find.text(l10n.configLabelInstanceName), findsOneWidget);

      // Action buttons should be visible
      expect(find.text(l10n.cancel), findsOneWidget);
      expect(find.text(l10n.testProvider), findsOneWidget);
      expect(find.text(l10n.save), findsOneWidget);
    });

    testWidgets('Config dialog shows empty field validation on Test button',
        (tester) async {
      final telegram = ProviderRegistry.baseFor('telegram');
      expect(telegram, isNotNull);

      final instance =
          ProviderInstance(telegram!, 'val_test', 'Validation Test');
      ProviderRegistry.all = [instance];

      await tester.pumpWidget(
        buildTestScreen(
          myProvidersCollapsed: false,
          extraOverrides: [
            providerConfigProvider(instance.providerId)
                .overrideWith((ref) => Future.value(<String, String>{})),
            providerInstancesProvider('telegram')
                .overrideWith((ref) => Future.value([
                      {'id': 'val_test', 'name': 'Validation Test'}
                    ])),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Tap Test button (fields are empty → shows validation)
      await tester.tap(find.text(l10n.testProvider));
      await tester.pumpAndSettle();

      // Validation error should appear
      expect(find.text(l10n.fillRequiredFields), findsOneWidget);
      expect(find.text(l10n.providerConfigRequired), findsWidgets);
    });
  });
}
