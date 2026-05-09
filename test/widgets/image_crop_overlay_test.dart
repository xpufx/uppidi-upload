import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/l10n/app_localizations.dart';
import 'package:uppidi_upload/widgets/image_crop_overlay.dart';

/// Helper: create test image bytes (won't decode, but errorBuilder handles it).
Uint8List _testImageBytes(int width, int height) {
  return Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
}

void main() {
  group('ImageCropOverlay', () {
    testWidgets('shows crop overlay as a dialog via show()', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      // Launch the dialog
      final future = ImageCropOverlay.show(
        context: tester.element(find.byType(SizedBox)),
        imageBytes: _testImageBytes(100, 100),
        imageWidth: 100,
        imageHeight: 100,
      );
      await tester.pumpAndSettle();

      // Dialog content visible
      expect(find.text('Apply'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel button closes dialog with null result', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final future = ImageCropOverlay.show(
        context: tester.element(find.byType(SizedBox)),
        imageBytes: _testImageBytes(100, 100),
        imageWidth: 100,
        imageHeight: 100,
      );
      await tester.pumpAndSettle();

      // Tap Cancel (the X icon button in leading)
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      expect(await future, isNull);
    });

    testWidgets('Apply button closes dialog with a valid crop rect',
        (tester) async {
      Rect? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final future = ImageCropOverlay.show(
        context: tester.element(find.byType(SizedBox)),
        imageBytes: _testImageBytes(100, 100),
        imageWidth: 100,
        imageHeight: 100,
      );
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      result = await future;
      expect(result, isNotNull);
      expect(result!.left, greaterThanOrEqualTo(0));
      expect(result!.top, greaterThanOrEqualTo(0));
      expect(result!.right, lessThanOrEqualTo(100));
      expect(result!.bottom, lessThanOrEqualTo(100));
      expect(result!.width, greaterThan(0));
      expect(result!.height, greaterThan(0));
    });

    testWidgets('drag gesture on the dialog does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      ImageCropOverlay.show(
        context: tester.element(find.byType(SizedBox)),
        imageBytes: _testImageBytes(200, 200),
        imageWidth: 200,
        imageHeight: 200,
      );
      await tester.pumpAndSettle();

      // Drag on the dialog's crop area
      await tester.timedDrag(
        find.byType(GestureDetector).last,
        const Offset(20, 10),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();

      // Dialog still visible (no crash)
      expect(find.byType(ImageCropOverlay), findsOneWidget);
    });
  });
}
