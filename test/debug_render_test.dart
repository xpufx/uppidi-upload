import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug provider rendering', (tester) async {
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

    // Pump multiple frames
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    final cards = find.byType(Card);
    print('CARDS FOUND: ${cards.evaluate().length}');
    for (final c in cards.evaluate()) {
      print('  Card: ${c.widget}');
    }
    
    // Check for exceptions
    final exceptions = tester.takeException();
    if (exceptions != null) {
      print('EXCEPTION: $exceptions');
    }
    
    expect(ProviderRegistry.all.length, 9);
  });
}
