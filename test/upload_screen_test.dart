import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:uppidi_upload/screens/upload_screen.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/screens/settings_screen.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/core/version_check_provider.dart';
import 'package:uppidi_upload/core/settings_service.dart';

/// Mock UploadNotifier to control initial state
class MockUploadNotifier extends UploadNotifier {
  final UploadState initialTestState;

  MockUploadNotifier({
    required this.initialTestState,
    super.providers,
  });

  @override
  UploadState build() => initialTestState;
}

/// Mock uploader for testing
class MockUploader implements BaseUploader {
  final String id;
  final String name;
  final bool isImageProvider;

  MockUploader({
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

/// Mock provider health info
ProviderHealthInfo mockHealthInfo({bool disabled = false, String? reason}) =>
    ProviderHealthInfo(disabled: disabled, reason: reason);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('Upload Screen Widget Tests', () {
    testWidgets('1. Renders provider dropdown', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadIdle(providers: mockUploaders),
                providers: mockUploaders,
              );
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const UploadScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Verify provider dropdown (DropdownButton) is rendered
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('2. Shows pick button when idle', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadIdle(providers: mockUploaders),
                providers: mockUploaders,
              );
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const UploadScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // _PickButton displays an ElevatedButton with pickAndUpload text
      expect(find.text(l10n.pickAndUpload), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('3a. Quality selector hidden for non-images', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      // Test non-image file (PDF)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadFileSelected(
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: null,
                  quality: 0,
                  providers: mockUploaders,
                  selectedProviderIndex: 0,
                ),
                providers: mockUploaders,
              );
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const UploadScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Quality selector (SegmentedButton) should not be present for non-images
      expect(find.byType(SegmentedButton<int>), findsNothing);
    });

    testWidgets('3b. Quality selector shown for images', (WidgetTester tester) async {
      final imageUploader = MockUploader(isImageProvider: true);

      // Test image file (PNG)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadFileSelected(
                  fileName: 'test.png',
                  fileSizeBytes: 1024,
                  mimeType: 'image/png',
                  fileBytes: Uint8List(0),
                  quality: 0,
                  providers: [imageUploader],
                  selectedProviderIndex: 0,
                ),
                providers: [imageUploader],
              );
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const UploadScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Quality selector should be shown for image files
      expect(find.text('Quality: '), findsOneWidget, reason: 'Quality text should be present for image files');
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
    });
  });

  group('Health Disabled Provider Test', () {
    testWidgets('4. Health-disabled provider shows switch as disabled', (WidgetTester tester) async {
      const testProviderId = 'httpbin'; // Matches existing HttpBinProvider ID
      final mockHealth = {
        testProviderId: ProviderHealthInfo(disabled: true, reason: 'Maintenance'),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Mock health provider to return disabled status for test provider
            providerHealthProvider.overrideWith((ref) => Future.value(mockHealth)),
            // No user-disabled providers (so provider appears enabled)
            disabledProviderIdsProvider.overrideWith((ref) => Future.value(<String>{})),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const TestScreen()),
          ),
        ),
      );

      // Wait for all async providers to resolve
      await tester.pumpAndSettle();

      // Find switches (one per provider in TestScreen)
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // The first switch corresponds to httpbin provider (first in ProviderRegistry)
      final firstSwitch = tester.widget<Switch>(switches.first);
      // Switch should be disabled (onChanged is null) due to health disabled status
      expect(firstSwitch.onChanged, isNull);
    });
  });

  group('Version Check Test', () {
    testWidgets('5. Version check shows refresh icon initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const SettingsScreen()),
          ),
        ),
      );

      // Wait for initial frame rendering
      await tester.pumpAndSettle();

      // VersionCheckState.idle shows Icons.refresh icon
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
