import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';

class TestRow extends StatelessWidget {
  final BaseUploader provider;
  const TestRow(this.provider, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(provider.providerName),
      ),
    );
  }
}

void main() {
  testWidgets('debug exact match', (tester) async {
    final badProviders = ProviderRegistry.all.where((p) => 
      p.providerName == 'temp.sh' || p.providerName == 'Litterbox').toList();
      
    for (final p in badProviders) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Text(p.providerName),
            ),
          ),
        ),
      );
      await tester.pump();
      final count = find.text(p.providerName).evaluate().length;
      print('  Solo Found ${count}x "${p.providerName}"');
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              for (final p in badProviders)
                TestRow(p, key: ValueKey(p.providerId)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    for (final p in badProviders) {
      final count = find.text(p.providerName).evaluate().length;
      print('  In ListView: Found ${count}x "${p.providerName}"');
    }
    
    // Also check: what about using find.byType(Card)?
    print('Cards in ListView: ${find.byType(Card).evaluate().length}');
  });
}
