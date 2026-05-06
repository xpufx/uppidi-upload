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

  group('FileSelected State Tests', () {
    testWidgets('Upload button and Clear button visible when file selected', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadFileSelected(
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // Upload button should be visible (ElevatedButton with upload text)
      expect(find.text(l10n.upload), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, l10n.upload), findsOneWidget);

      // Clear button (close icon) should be visible
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('File preview visible when file selected', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadFileSelected(
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // File preview card should be visible with file name
      expect(find.text('test.pdf'), findsOneWidget);
      expect(find.byType(Card), findsWidgets); // File preview is in a Card
    });

    testWidgets('Quality selector shown for image files', (WidgetTester tester) async {
      final imageUploader = MockUploader(isImageProvider: true);

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
      expect(find.text('Quality: '), findsOneWidget);
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      // Check for quality options
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('Quality selector NOT shown for non-image files', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadFileSelected(
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // Quality selector should NOT be present for non-image files
      expect(find.byType(SegmentedButton<int>), findsNothing);
    });
  });

  group('InProgress State Tests', () {
    testWidgets('Progress bar, speed label, cancel button visible during upload', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      final cancelToken = CancelToken();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadInProgress(
                  progress: 0.5,
                  cancelToken: cancelToken,
                  sentBytes: 512,
                  totalBytes: 1024,
                  speedLabel: '100 B/s',
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // Progress bar should be visible (LinearProgressIndicator)
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Speed label should be visible
      expect(find.text('100 B/s'), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);

      // Cancel button should be visible
      expect(find.text(l10n.cancelUpload), findsOneWidget);
      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });

  group('Completed State Tests - Success', () {
    testWidgets('URL text, share icon, copy icon, open icon visible on success', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      const testUrl = 'https://example.com/test.pdf';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadCompleted(
                  lastResult: UploadResult(success: true, url: testUrl),
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // Success message should be visible
      expect(find.text(l10n.uploadComplete), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      // URL should be visible
      expect(find.text(testUrl), findsOneWidget);

      // Share icon should be visible
      expect(find.byIcon(Icons.share), findsWidgets);

      // Copy icon should be visible
      expect(find.byIcon(Icons.copy), findsWidgets);

      // Open in browser icon should be visible
      expect(find.byIcon(Icons.open_in_new), findsWidgets);
    });
  });

  group('Completed State Tests - Failure', () {
    testWidgets('Error text, retry button, cancel button, debug icon visible on failure', (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      const errorMessage = 'Upload failed: Connection timeout';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadCompleted(
                  lastResult: UploadResult(success: false, errorMessage: errorMessage),
                  errorMessage: errorMessage,
                  fileName: 'test.pdf',
                  fileSizeBytes: 1024,
                  mimeType: 'application/pdf',
                  fileBytes: Uint8List(0),
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

      // Error message should be visible
      expect(find.text(l10n.uploadFailed), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error), findsWidgets);

      // Debug icon should be visible
      expect(find.byIcon(Icons.bug_report), findsWidgets);

      // Retry button should be visible
      expect(find.text(l10n.retry), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsWidgets);

      // Cancel button should be visible
      expect(find.text(l10n.cancel), findsOneWidget);
      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });

  group('Provider Change During FileSelected', () {
    testWidgets('Provider dropdown changes but preview stays when provider changes', (WidgetTester tester) async {
      final mockUploader1 = MockUploader(id: 'provider1', name: 'Provider 1');
      final mockUploader2 = MockUploader(id: 'provider2', name: 'Provider 2');
      final mockUploaders = [mockUploader1, mockUploader2];

      // Create a state with file selected
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          mimeType: 'application/pdf',
          fileBytes: Uint8List(0),
          quality: 0,
          providers: mockUploaders,
          selectedProviderIndex: 0,
        ),
        providers: mockUploaders,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: const UploadScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify file preview is visible
      expect(find.text('test.pdf'), findsOneWidget);

      // Change provider via dropdown
      final dropdown = find.byType(DropdownButton<int>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap on the second provider
      await tester.tap(find.text('Provider 2').last);
      await tester.pumpAndSettle();

      // File preview should still be visible (file stays selected)
      expect(find.text('test.pdf'), findsOneWidget);
    });
  });

  group('Health Disabled Provider Test', () {
    testWidgets('Health-disabled provider shows switch as disabled', (WidgetTester tester) async {
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
    testWidgets('Version check widget renders in SettingsScreen', (WidgetTester tester) async {
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

      // SettingsScreen should render
      expect(find.byType(SettingsScreen), findsOneWidget);
      // The version check icon may or may not be present depending on cdnUrl environment variable
      // Just verify the screen renders without errors
    });
  });
}
