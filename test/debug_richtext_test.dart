import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug sliderender', (tester) async {
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

    // Try by widget type predicate
    final providerRowWidgets = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ProviderRow');
    print('_ProviderRow count: ${providerRowWidgets.evaluate().length}');
    
    // Find all RichText widgets and check their text
    for (final rt in find.byType(RichText).evaluate()) {
      final richText = rt.widget as RichText;
      final textSpan = richText.text;
      if (textSpan is TextSpan && textSpan.text != null) {
        final t = textSpan.text!;
        if (t.contains('temp') || t.contains('Litter') || t.contains('litter')) {
          print('  RichText: "$t"');
        }
      }
    }
    
    final exceptions = tester.takeException();
    if (exceptions != null) {
      print('EXCEPTION: $exceptions');
    }
  });
}
