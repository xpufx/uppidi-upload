import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uppidi_upload/core/history_service.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/providers/upload_provider.dart';
import 'package:uppidi_upload/screens/tab_nav_strategy.dart';

import 'helpers/mock_uploader.dart';
import 'helpers/mock_settings.dart';
import 'helpers/mock_history.dart';

Widget buildTabNav() {
  final mockUploaders = [MockBaseUploader()];
  return ProviderScope(
    overrides: [
      settingsServiceProvider.overrideWith((ref) => MockSettingsService()),
      historyServiceProvider.overrideWith((ref) => MockHistoryService()),
      enabledProvidersProvider.overrideWith((ref) => mockUploaders),
      uploadProvider.overrideWith(
        () => UploadNotifier(providers: mockUploaders),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TabNavStrategy(),
    ),
  );
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('TabNavStrategy', () {
    testWidgets('renders bottom nav with 5 tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTabNav());
      await tester.pumpAndSettle();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.items.length, 5);
    });

    testWidgets('starts on Upload tab (index 0)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTabNav());
      await tester.pumpAndSettle();

      final navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);
    });

    testWidgets('tapping tabs switches correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTabNav());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.history));
      await tester.pumpAndSettle();

      var navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 2);

      await tester.tap(find.text(l10n.settings));
      await tester.pumpAndSettle();

      navBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navBar.currentIndex, 4);
    });
  });
}
