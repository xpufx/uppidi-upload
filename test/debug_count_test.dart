import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

void main() {
  testWidgets('debug provider count', (tester) async {
    print('REGISTRY LENGTH: ${ProviderRegistry.all.length}');
    for (final p in ProviderRegistry.all) {
      print('  PROVIDER: ${p.providerId} - ${p.providerName}');
    }
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disabledProviderIdsProvider.overrideWith((ref) => Future.value(<String>{})),
          providerHealthProvider.overrideWith((ref) => Future.value({})),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Container()),
        ),
      ),
    );
    
    await tester.pump();
    
    // Just confirm registry length
    expect(ProviderRegistry.all.length, 9);
  });
}
