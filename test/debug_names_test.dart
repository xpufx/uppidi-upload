import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug missing providers', (tester) async {
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

    // Check each provider name
    for (final p in ProviderRegistry.all) {
      final nameWidgets = find.text(p.providerName);
      print('${p.providerName} (${p.providerId}): foundTexts=${nameWidgets.evaluate().length}');
    }
    
    // Check what Text widgets exist
    print('--- ALL TEXT WIDGETS ---');
    for (final t in find.byType(Text).evaluate()) {
      final text = t.widget as Text;
      if (text.data != null) print('  Text: "${text.data}"');
    }
    
    final exceptions = tester.takeException();
    if (exceptions != null) {
      print('EXCEPTION: $exceptions');
    }
  });
}
