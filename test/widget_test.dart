import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/main.dart';
import 'package:uppidi_upload/screens/tab_nav_strategy.dart';

import 'helpers/mock_settings.dart';

void main() {
  setUpAll(() async {
    Hive.init('.hive_test_widget');
    await Hive.openBox<String>('settings');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsServiceProvider.overrideWith((ref) => MockSettingsService()),
        ],
        child: const UppidiApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Default shell type is 'tabs' — renders TabNavStrategy
    expect(find.byType(TabNavStrategy), findsOneWidget);
  });
}
