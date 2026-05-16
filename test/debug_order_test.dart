import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug provider order', (tester) async {
    // Check order: list what renders
    for (final p in ProviderRegistry.all) {
      print('  ${p.providerId}: "${p.providerName}"');
    }
    print('---');
    
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

    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Check for any error in the test
    final errors = tester.takeException();
    if (errors != null) {
      print('ERROR: $errors');
    }
    
    // Get positions of all Cards
    final cards = find.byType(Card);
    print('Cards found: ${cards.evaluate().length}');
    int i = 0;
    for (final c in cards.evaluate()) {
      final renderBox = c.findRenderObject() as RenderBox?;
      final pos = renderBox?.localToGlobal(Offset.zero);
      print('  Card $i: position=$pos, size=${renderBox?.size}');
      i++;
    }
    
    // Now check - are temp.sh and Litterbox provider IDs in the test states?
    print('Provider IDs:');
    for (final p in ProviderRegistry.all) {
      final byName = find.text(p.providerName);
      final byId = find.byKey(ValueKey(p.providerId));
      print('  ${p.providerName}: textCount=${byName.evaluate().length}');
    }
  });
}
