import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug widget tree', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disabledProviderIdsProvider.overrideWith((ref) => Future.value(<String>{})),
          providerHealthProvider.overrideWith((ref) => Future.value({})),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: const TestScreen()),
        ),
      ),
    );

    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Create a custom finder for texts matching Litterbox or temp.sh
    final allWidgets = find.byWidgetPredicate((w) => w is Text && (w.data == 'temp.sh' || w.data == 'Litterbox'));
    print('temp.sh/Litterbox texts found: ${allWidgets.evaluate().length}');
    
    // Now count all ListTile or ProviderRow type widgets
    print('--- SliverChildListDelegate children ---');
    final listViews = find.byType(ListView).evaluate();
    for (final lv in listViews) {
      final listWidget = lv.widget as ListView;
      print('ListView children: ${listWidget.childrenDelegate.estimatedChildCount}');
    }
    
    final exceptions = tester.takeException();
    if (exceptions != null) {
      print('EXCEPTION: $exceptions');
    }
  });
}
