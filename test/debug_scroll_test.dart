import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug scroll', (tester) async {
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
    
    // Count before scroll
    print('Before scroll: Cards=${find.byType(Card).evaluate().length}');
    print('temp.sh texts=${find.text("temp.sh").evaluate().length}');
    
    // Scroll down
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    print('After scroll: Cards=${find.byType(Card).evaluate().length}');
    print('temp.sh texts=${find.text("temp.sh").evaluate().length}');
    print('Litterbox texts=${find.text("Litterbox").evaluate().length}');
  });
}
