import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/providers/tempsh_provider.dart';
import 'package:uppidi_upload/providers/litterbox_provider.dart';

void main() {
  testWidgets('debug isolated providers', (tester) async {
    // Test just TempSh
    final all = ProviderRegistry.all;
    print('Total: ${all.length}');
    
    // Try rendering just TempSh
    for (final p in all) {
      print('Rendering: ${p.providerName}');
    }
    
    // Check which are the missing ones
    final tempSh = TempShProvider();
    final litterbox = LitterboxProvider();
    print('TempSh metadata: ${tempSh.metadata.fileSizeLabel} ${tempSh.metadata.expiryInfo}');
    print('Litterbox metadata: ${litterbox.metadata.fileSizeLabel} ${litterbox.metadata.expiryInfo}');
    
    // Render a simple widget with just temp.sh and Litterbox
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [
              Text('temp.sh', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Litterbox', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    
    var count = find.text('temp.sh').evaluate().length;
    print('Plain temp.sh text count: $count');
    count = find.text('Litterbox').evaluate().length;
    print('Plain Litterbox text count: $count');
  });
}
