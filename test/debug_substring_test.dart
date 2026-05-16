import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug specific providers', (tester) async {
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

    // Find ALL Text widgets and their data
    for (final t in find.byType(Text).evaluate()) {
      final text = t.widget as Text;
      if (text.data != null) {
        print('  Text: "${text.data}" style: ${text.style?.fontSize}');
      }
    }

    // Check if the specific rows exist at all by looking for the Card children
    // Try temp.sh and Litterbox provider names with different finders
    print('--- find.text ---');
    final providers = ProviderRegistry.all;
    for (final p in providers) {
      var count = find.text(p.providerName).evaluate().length;
      if (count == 0) {
        // Try with textContaining
        count = find.textContaining(p.providerName).evaluate().length;
        print('  textContaining("${p.providerName}"): $count');
      }
    }
    
    final exceptions = tester.takeException();
    if (exceptions != null) {
      print('EXCEPTION: $exceptions');
    }
  });
}
