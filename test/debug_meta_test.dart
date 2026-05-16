import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uppidi_upload/screens/test_screen.dart';
import 'package:uppidi_upload/core/registry.dart';
import 'package:uppidi_upload/core/interfaces/uploader.dart';
import 'package:uppidi_upload/core/metadata_badges.dart';
import 'package:uppidi_upload/core/settings_service.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/providers/tempsh_provider.dart';
import 'package:uppidi_upload/providers/litterbox_provider.dart';

void main() {
  testWidgets('debug row rendering', (tester) async {
    // Test rendering metadataBadges for TempSh
    final tempSh = TempShProvider();
    final litterbox = LitterboxProvider();
    
    print('TempSh fileSizeLabel: "${tempSh.metadata.fileSizeLabel}"');
    print('TempSh expiryInfo: "${tempSh.metadata.expiryInfo}"');
    print('TempSh fileSizeBytes: ${tempSh.metadata.maxFileSizeBytes}');
    
    print('Litterbox fileSizeLabel: "${litterbox.metadata.fileSizeLabel}"');
    print('Litterbox expiryInfo: "${litterbox.metadata.expiryInfo}"');
    print('Litterbox fileSizeBytes: ${litterbox.metadata.maxFileSizeBytes}');
    
    // Render just metadata badges
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Text('temp.sh'),
                metadataBadges(tempSh.metadata),
                SizedBox(height: 20),
                Text('Litterbox'),
                metadataBadges(litterbox.metadata),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    
    print('temp.sh text: ${find.text("temp.sh").evaluate().length}');
    print('Litterbox text: ${find.text("Litterbox").evaluate().length}');
    print('4GB text: ${find.text("4GB").evaluate().length}');
    print('1GB text: ${find.text("1GB").evaluate().length}');
    print('3 days text: ${find.text("3 days").evaluate().length}');
    
    // Now render full _ProviderRow for both
    print('');
    print('--- Now trying _ProviderRow ---');
    // Can't access _ProviderRow directly (private), so render through TestScreen with only these 2
    
    // Actually, let's check if there are RenderFlex overflow issues
    final overflow = tester.takeException();
    if (overflow != null) print('EXCEPTION: $overflow');
  });
}
