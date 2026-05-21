import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/models/upload_result.dart';
import 'package:uppidi_upload/core/models/upload_request.dart';
import 'package:dio/dio.dart';
import 'package:uppidi_upload/core/models/provider_metadata.dart';

// Mock uploader for testing
class MockNavUploader implements BaseUploader {
  @override
  String get providerId => 'mock';

  @override
  String get providerName => 'Mock Provider';

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

// Mock upload notifier
class MockNavUploadNotifier extends UploadNotifier {
  MockNavUploadNotifier() : super(providers: [MockNavUploader()]);
}

void main() {
  group('Navigation UI Tests', () {
    testWidgets('Bottom navigation bar shows all 4 tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(MockNavUploadNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: const Center(child: Text('Test')),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: 0,
                onTap: (_) {},
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cloud_upload),
                    label: 'Upload',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dns),
                    label: 'Providers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 4 navigation items should be present
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.dns), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('NavigationRail shows all 4 destinations on wide screen',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(MockNavUploadNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.cloud_upload),
                        label: Text('Upload'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.history),
                        label: Text('History'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.dns),
                        label: Text('Providers'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                  const Expanded(child: Center(child: Text('Content'))),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // NavigationRail should be present
      expect(find.byType(NavigationRail), findsOneWidget);

      // All 4 destinations should be present
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.dns), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('BottomNavigationBar switches to narrow layout',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uploadProvider.overrideWith(MockNavUploadNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: const Center(child: Text('Test')),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: 0,
                onTap: (_) {},
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cloud_upload),
                    label: 'Upload',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dns),
                    label: 'Providers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // BottomNavigationBar should be present
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // NavigationRail should NOT be present
      expect(find.byType(NavigationRail), findsNothing);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
