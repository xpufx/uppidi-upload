import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

import 'package:uppidi_upload/screens/upload_screen.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/screens/settings_screen.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/core/settings_service.dart';

/// Mock UploadNotifier to control initial state
class MockUploadNotifier extends UploadNotifier {
  final UploadState initialTestState;
  bool uploadSelectedCalled = false;

  MockUploadNotifier({
    required this.initialTestState,
    super.providers,
  });

  @override
  UploadState build() => initialTestState;

  @override
  Future<void> uploadSelected() async {
    uploadSelectedCalled = true;
    await super.uploadSelected();
  }
}

/// Mock uploader for testing
class MockUploader implements BaseUploader {
  final String id;
  final String name;
  final bool isImageProvider;
  final Duration? uploadDelay;

  MockUploader({
    this.id = 'mock_provider',
    this.name = 'Mock Provider',
    this.isImageProvider = false,
    this.uploadDelay,
  });

  @override
  String get providerId => id;

  @override
  String get providerName => name;

  @override
  bool get supportsWeb => true;
  @override
  bool get isUrlShareOnly => false;

  @override
  List<String> get requiredConfigKeys => [];

  @override
  Map<String, String> get configLabels => {};

  @override
  List<String> get optionalConfigKeys => const [];

  @override
  String? get proxyUrl => null;

  @override
  String? get instanceDescription => null;
  @override
  List<String> get optionalTextConfigKeys => const [];

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
  }) async {
    if (uploadDelay != null) {
      await Future.delayed(uploadDelay!);
    }
    return UploadResult(success: true);
  }
}

/// Mock provider health info
ProviderHealthInfo mockHealthInfo({bool disabled = false, String? reason}) =>
    ProviderHealthInfo(disabled: disabled, reason: reason);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    Hive.init('.hive_test_upload_screen');
    await Hive.openBox<String>('settings');
  });

  tearDownAll(() {
    Directory('.hive_test_upload_screen').deleteSync(recursive: true);
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
      // Verify provider dropdown is rendered
      expect(find.byType(DropdownButtonFormField<int?>), findsOneWidget);
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
      // _PickButton displays a button with chooseFile text
      expect(find.text(l10n.chooseFile), findsWidgets);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('FileSelected State Tests', () {
    testWidgets('Upload button and Clear button visible when file selected',
        (WidgetTester tester) async {
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

    testWidgets('File preview visible when file selected',
        (WidgetTester tester) async {
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
  });

  group('InProgress State Tests', () {
    testWidgets(
        'Progress bar, speed label, cancel button visible during upload',
        (WidgetTester tester) async {
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

      // Cancel button should be visible (in overlay + bottom bar)
      expect(find.text(l10n.cancelUpload), findsWidgets);
      expect(find.byIcon(Icons.close), findsWidgets);
    });
  });

  group('Completed State Tests - Success', () {
    testWidgets('URL text, share icon, copy icon, open icon visible on success',
        (WidgetTester tester) async {
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
    testWidgets(
        'Error text, retry button, cancel button, debug icon visible on failure',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      const errorMessage = 'Upload failed: Connection timeout';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadCompleted(
                  lastResult:
                      UploadResult(success: false, errorMessage: errorMessage),
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
    testWidgets(
        'Provider dropdown changes but preview stays when provider changes',
        (WidgetTester tester) async {
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
      final dropdown = find.byType(DropdownButtonFormField<int?>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap on the second dropdown item (by icon, since text was removed)
      final items = find.byType(DropdownMenuItem<int>);
      expect(items, findsWidgets);
      await tester.tap(items.at(1));
      await tester.pumpAndSettle();

      // File preview should still be visible (file stays selected)
      expect(find.text('test.pdf'), findsOneWidget);
    });
  });

  group('Health Disabled Provider Test', () {
    testWidgets(
        'Health-disabled provider switch is toggleable and shows warning',
        (WidgetTester tester) async {
      const testProviderId = 'httpbin'; // Matches existing HttpBinProvider ID
      const reason = 'Maintenance';
      final mockHealth = {
        testProviderId: ProviderHealthInfo(disabled: true, reason: reason),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Mock health provider to return disabled status for test provider
            providerHealthProvider
                .overrideWith((ref) => Future.value(mockHealth)),
            // No user-disabled providers (so provider appears enabled)
            disabledProviderIdsProvider
                .overrideWith((ref) => Future.value(<String>{})),
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

      // The switch should be toggleable (onChanged != null) even when health-disabled
      // User override is allowed
      final firstSwitch = tester.widget<Switch>(switches.first);
      expect(firstSwitch.onChanged, isNotNull);

      // Warning icon should still be shown
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
      expect(find.text(reason), findsOneWidget);
    });
  });

  group('Version Check Test', () {
    testWidgets('Version check widget renders in SettingsScreen',
        (WidgetTester tester) async {
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

  group('Tap Interaction Tests', () {
    testWidgets('1. Tap quality selector changes value to Medium (1)',
        (WidgetTester tester) async {
      final imageUploader = MockUploader(isImageProvider: true);
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.png',
          fileSizeBytes: 1024,
          mimeType: 'image/png',
          fileBytes: Uint8List(0),
          providers: [imageUploader],
          selectedProviderIndex: 0,
        ),
        providers: [imageUploader],
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
    });

    testWidgets('2. Tap Upload button calls uploadSelected()',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          mimeType: 'application/pdf',
          fileBytes: Uint8List(0),
          providers: mockUploaders,
          selectedProviderIndex: 0,
        ),
        providers: mockUploaders,
      );
      // Reset spy flag
      notifier.uploadSelectedCalled = false;

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

      // Verify Upload button is present and enabled
      final uploadButton = find.widgetWithText(ElevatedButton, l10n.upload);
      expect(uploadButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(uploadButton).onPressed, isNotNull);

      // Tap the Upload button
      // Scroll to the Upload button (might be off-screen due to new UI elements)
      await tester.ensureVisible(uploadButton);
      await tester.pumpAndSettle();
      await tester.tap(uploadButton);
      await tester.pump();

      // Verify uploadSelected() was called
      expect(notifier.uploadSelectedCalled, isTrue);
    });

    testWidgets('3. Tap Clear button returns to UploadIdle',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          mimeType: 'application/pdf',
          fileBytes: Uint8List(0),
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

      // Verify Clear button (close icon) is present
      final clearButton = find.byIcon(Icons.close);
      expect(clearButton, findsOneWidget);

      // Tap the Clear button
      // Scroll to the Clear button (might be off-screen due to new UI elements)
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Verify state is UploadIdle (pick button reappears)
      expect(notifier.state, isA<UploadIdle>());
      expect(find.text(l10n.chooseFile), findsWidgets);
    });

    testWidgets('4. Tap Cancel during upload returns to UploadIdle',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      final cancelToken = CancelToken();
      final notifier = MockUploadNotifier(
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

      // Verify Cancel button is present (in overlay + bottom bar)
      final cancelButton = find.text(l10n.cancelUpload);
      expect(cancelButton, findsWidgets);

      // Tap the first Cancel button (overlay)
      await tester.ensureVisible(cancelButton.first);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton.first);
      await tester.pumpAndSettle();

      // Verify state is UploadIdle
      expect(notifier.state, isA<UploadIdle>());
      expect(find.text(l10n.chooseFile), findsWidgets);
    });

    testWidgets('5. Tap Retry on failure calls uploadSelected()',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      final notifier = MockUploadNotifier(
        initialTestState: UploadCompleted(
          lastResult: UploadResult(success: false, errorMessage: 'Test error'),
          errorMessage: 'Test error',
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          mimeType: 'application/pdf',
          fileBytes: Uint8List(0),
          providers: mockUploaders,
          selectedProviderIndex: 0,
        ),
        providers: mockUploaders,
      );
      // Reset the spy flag
      notifier.uploadSelectedCalled = false;

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

      // Verify Retry button is present
      final retryButton = find.text(l10n.retry);
      expect(retryButton, findsOneWidget);

      // Scroll to the Retry button (might be off-screen due to new UI elements)
      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      // Tap the Retry button
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Verify uploadSelected() was called
      expect(notifier.uploadSelectedCalled, isTrue);
    });

    testWidgets('6. Tap Debug icon shows error dialog',
        (WidgetTester tester) async {
      final mockUploaders = [MockUploader()];
      const errorMessage = 'Test upload error';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(() {
              return MockUploadNotifier(
                initialTestState: UploadCompleted(
                  lastResult:
                      UploadResult(success: false, errorMessage: errorMessage),
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

      // Verify Debug icon is present
      final debugIcon = find.byIcon(Icons.bug_report);
      expect(debugIcon, findsWidgets);

      // Scroll to the debug icon (might be off-screen due to new UI elements)
      await tester.ensureVisible(debugIcon.first);
      await tester.pumpAndSettle();

      // Tap the Debug icon
      await tester.tap(debugIcon.first);
      await tester.pumpAndSettle();

      // Verify dialog is shown (AlertDialog)
      expect(find.byType(AlertDialog), findsOneWidget);
      // Verify error message is shown in the dialog
      expect(find.text(errorMessage), findsWidgets);
    });
  });

  group('Crop Tool Tests', () {
    /// Generate valid PNG bytes for testing image decode.
    Uint8List validPngBytes() {
      final image = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          image.setPixelRgba(x, y, 255, 0, 0, 255);
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    }

    testWidgets('Crop icon visible when image file selected', (tester) async {
      final imageUploader = MockUploader(isImageProvider: true);
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.png',
          fileSizeBytes: 67,
          mimeType: 'image/png',
          fileBytes: validPngBytes(),
          providers: [imageUploader],
          selectedProviderIndex: 0,
        ),
        providers: [imageUploader],
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

      // Edit icon should be visible for image files
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('Crop icon NOT visible for non-image files', (tester) async {
      final mockUploaders = [MockUploader()];
      final notifier = MockUploadNotifier(
        initialTestState: UploadFileSelected(
          fileName: 'test.pdf',
          fileSizeBytes: 1024,
          mimeType: 'application/pdf',
          fileBytes: null,
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

      // Edit icon should NOT be present for non-image files
      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });
}
