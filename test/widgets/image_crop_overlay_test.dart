import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uppidi_upload/widgets/image_crop_overlay.dart';

/// Helper: create test image bytes (won't decode, but errorBuilder handles it).
Uint8List _testImageBytes(int width, int height) {
  // Return opaque bytes — errorBuilder will handle the failed decode
  return Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
}

void main() {
  group('ImageCropOverlay', () {
    testWidgets('renders image and shows crop rectangle', (tester) async {
      Rect? confirmedRect;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ImageCropOverlay(
                imageBytes: _testImageBytes(100, 100),
                imageWidth: 100,
                imageHeight: 100,
                onConfirm: (rect) => confirmedRect = rect,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Confirm/Cancel buttons present
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel button calls onCancel', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ImageCropOverlay(
                imageBytes: _testImageBytes(100, 100),
                imageWidth: 100,
                imageHeight: 100,
                onConfirm: (_) {},
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('Apply button calls onConfirm with image-coordinate rect',
        (tester) async {
      Rect? confirmedRect;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ImageCropOverlay(
                imageBytes: _testImageBytes(100, 100),
                imageWidth: 100,
                imageHeight: 100,
                onConfirm: (rect) => confirmedRect = rect,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(confirmedRect, isNotNull);
      // Rect should be within image bounds and in image coordinates
      expect(confirmedRect!.left, greaterThanOrEqualTo(0));
      expect(confirmedRect!.top, greaterThanOrEqualTo(0));
      expect(confirmedRect!.right, lessThanOrEqualTo(100));
      expect(confirmedRect!.bottom, lessThanOrEqualTo(100));
      expect(confirmedRect!.width, greaterThan(0));
      expect(confirmedRect!.height, greaterThan(0));
    });

    testWidgets('drag gesture does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: ImageCropOverlay(
                imageBytes: _testImageBytes(200, 200),
                imageWidth: 200,
                imageHeight: 200,
                onConfirm: (_) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag on the center of the widget area to move the crop rect
      await tester.timedDrag(
        find.byType(ImageCropOverlay),
        const Offset(20, 10),
        const Duration(milliseconds: 200),
      );
      await tester.pumpAndSettle();

      // No crash — widget remains responsive
      expect(find.byType(ImageCropOverlay), findsOneWidget);
    });
  });
}
