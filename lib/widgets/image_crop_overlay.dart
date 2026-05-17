import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// A full-screen image crop overlay shown as a dialog.
/// Returns the crop region in original-image coordinates via [Navigator.pop],
/// or null if cancelled.
class ImageCropOverlay extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;

  const ImageCropOverlay({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Shows the crop overlay as a full-screen dialog.
  /// Returns the crop [Rect] in original-image coordinates, or `null` if cancelled.
  static Future<Rect?> show({
    required BuildContext context,
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) {
    return showDialog<Rect>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => ImageCropOverlay(
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
    );
  }

  @override
  State<ImageCropOverlay> createState() => _ImageCropOverlayState();
}

/// Identifies which part of the crop rect is being dragged.
enum _DragHandle {
  move,
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

class _ImageCropOverlayState extends State<ImageCropOverlay> {
  Rect _cropRect = Rect.zero;
  bool _initialized = false;
  Size _displaySize = Size.zero;

  // Drag tracking
  _DragHandle? _activeHandle;
  Offset _dragStart = Offset.zero;
  Rect _rectAtDragStart = Rect.zero;

  static const double _handleRadius = 14.0;
  static const double _handleHitArea = 32.0;
  static const double _minCropSize = 60.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // AppLocalizations.of() never returns null, so ?. is unnecessary.
    final cancelLabel = l10n.cancel;
    final applyLabel = l10n.apply;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: cancelLabel,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          applyLabel,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              final region = _toImageCoordinates();
              Navigator.pop(context, region);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              applyLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final imageAspect = widget.imageWidth / widget.imageHeight;
            final containerAspect = maxWidth / maxHeight;

            double displayWidth, displayHeight;
            if (imageAspect > containerAspect) {
              displayWidth = maxWidth;
              displayHeight = maxWidth / imageAspect;
            } else {
              displayHeight = maxHeight;
              displayWidth = maxHeight * imageAspect;
            }

            final dispSize = Size(displayWidth, displayHeight);

            // Initialize when size changes
            if (!_initialized || _displaySize != dispSize) {
              _cropRect = _initialCropRect(dispSize);
              _displaySize = dispSize;
              _initialized = true;
            }

            return Center(
              child: SizedBox.fromSize(
                size: dispSize,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Image
                    Image.memory(
                      widget.imageBytes,
                      width: displayWidth,
                      height: displayHeight,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                    // Dark mask with crop hole + handles
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          cropRect: _cropRect,
                          activeHandle: _activeHandle,
                          handleRadius: _handleRadius,
                        ),
                      ),
                    ),
                    // Gesture layer
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: (_) => setState(() => _activeHandle = null),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Rect _initialCropRect(Size dispSize) {
    final margin = dispSize.shortestSide * 0.1;
    return Rect.fromLTWH(
      margin,
      margin,
      (dispSize.width - 2 * margin).clamp(_minCropSize, dispSize.width),
      (dispSize.height - 2 * margin).clamp(_minCropSize, dispSize.height),
    );
  }

  _DragHandle? _hitTest(Offset pos) {
    final r = _cropRect;
    const hit = _handleHitArea;

    // Corners
    if ((pos - r.topLeft).distance <= hit) return _DragHandle.topLeft;
    if ((pos - r.topRight).distance <= hit) return _DragHandle.topRight;
    if ((pos - r.bottomLeft).distance <= hit) return _DragHandle.bottomLeft;
    if ((pos - r.bottomRight).distance <= hit) return _DragHandle.bottomRight;

    // Edges
    if ((pos - Offset(r.center.dx, r.top)).distance <= hit) {
      return _DragHandle.top;
    }
    if ((pos - Offset(r.center.dx, r.bottom)).distance <= hit) {
      return _DragHandle.bottom;
    }
    if ((pos - Offset(r.left, r.center.dy)).distance <= hit) {
      return _DragHandle.left;
    }
    if ((pos - Offset(r.right, r.center.dy)).distance <= hit) {
      return _DragHandle.right;
    }

    return null;
  }

  void _onPanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    final handle = _hitTest(localPos);
    if (handle != null) {
      _activeHandle = handle;
    } else if (_cropRect.contains(localPos)) {
      _activeHandle = _DragHandle.move;
    } else {
      _activeHandle = null;
      return;
    }
    _dragStart = localPos;
    _rectAtDragStart = _cropRect;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle == null) return;
    final currentPos = details.localPosition;
    final delta = currentPos - _dragStart;
    setState(() {
      _cropRect = _applyDrag(_activeHandle!, _rectAtDragStart, delta);
    });
  }

  Rect _applyDrag(_DragHandle handle, Rect start, Offset delta) {
    double l = start.left, t = start.top, r = start.right, b = start.bottom;

    switch (handle) {
      case _DragHandle.move:
        l += delta.dx;
        r += delta.dx;
        t += delta.dy;
        b += delta.dy;
      case _DragHandle.topLeft:
        l += delta.dx;
        t += delta.dy;
      case _DragHandle.top:
        t += delta.dy;
      case _DragHandle.topRight:
        r += delta.dx;
        t += delta.dy;
      case _DragHandle.right:
        r += delta.dx;
      case _DragHandle.bottomRight:
        r += delta.dx;
        b += delta.dy;
      case _DragHandle.bottom:
        b += delta.dy;
      case _DragHandle.bottomLeft:
        l += delta.dx;
        b += delta.dy;
      case _DragHandle.left:
        l += delta.dx;
    }

    // Enforce minimum size
    if (r - l < _minCropSize) {
      if (handle == _DragHandle.left ||
          handle == _DragHandle.topLeft ||
          handle == _DragHandle.bottomLeft) {
        l = r - _minCropSize;
      } else {
        r = l + _minCropSize;
      }
    }
    if (b - t < _minCropSize) {
      if (handle == _DragHandle.top ||
          handle == _DragHandle.topLeft ||
          handle == _DragHandle.topRight) {
        t = b - _minCropSize;
      } else {
        b = t + _minCropSize;
      }
    }

    // Clamp to image bounds
    final w = _displaySize.width;
    final h = _displaySize.height;
    l = l.clamp(0.0, w - _minCropSize);
    t = t.clamp(0.0, h - _minCropSize);
    r = r.clamp(l + _minCropSize, w);
    b = b.clamp(t + _minCropSize, h);

    return Rect.fromLTRB(l, t, r, b);
  }

  Rect _toImageCoordinates() {
    final scaleX = widget.imageWidth / _displaySize.width;
    final scaleY = widget.imageHeight / _displaySize.height;
    return Rect.fromLTRB(
      (_cropRect.left * scaleX).round().toDouble(),
      (_cropRect.top * scaleY).round().toDouble(),
      (_cropRect.right * scaleX).round().toDouble(),
      (_cropRect.bottom * scaleY).round().toDouble(),
    );
  }
}

/// Paints the semi-transparent dark mask, crop border, and drag handles.
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final _DragHandle? activeHandle;
  final double handleRadius;

  _CropOverlayPainter({
    required this.cropRect,
    required this.activeHandle,
    required this.handleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // Draw 4 dark rectangles around the crop hole
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), maskPaint);
    canvas.drawRect(
      Rect.fromLTWH(
          0, cropRect.bottom, size.width, size.height - cropRect.bottom),
      maskPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      maskPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top, size.width - cropRect.right,
          cropRect.height),
      maskPaint,
    );

    // Crop rectangle border (white, slightly thicker)
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(cropRect, borderPaint);

    // Grid lines inside crop area (subtle)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + thirdW * i;
      canvas.drawLine(
          Offset(x, cropRect.top), Offset(x, cropRect.bottom), gridPaint);
    }
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + thirdH * i;
      canvas.drawLine(
          Offset(cropRect.left, y), Offset(cropRect.right, y), gridPaint);
    }

    // Corner handle positions
    final corners = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomRight,
      cropRect.bottomLeft,
    ];

    // Edge handle positions
    final edges = [
      Offset(cropRect.center.dx, cropRect.top),
      Offset(cropRect.center.dx, cropRect.bottom),
      Offset(cropRect.left, cropRect.center.dy),
      Offset(cropRect.right, cropRect.center.dy),
    ];

    // All handle positions mapped to their DragHandle type
    final Map<_DragHandle, Offset> allHandles = {
      _DragHandle.topLeft: cropRect.topLeft,
      _DragHandle.topRight: cropRect.topRight,
      _DragHandle.bottomRight: cropRect.bottomRight,
      _DragHandle.bottomLeft: cropRect.bottomLeft,
      _DragHandle.top: Offset(cropRect.center.dx, cropRect.top),
      _DragHandle.bottom: Offset(cropRect.center.dx, cropRect.bottom),
      _DragHandle.left: Offset(cropRect.left, cropRect.center.dy),
      _DragHandle.right: Offset(cropRect.right, cropRect.center.dy),
    };

    // Draw edge handles first (behind corners)
    final edgePaint = Paint()..color = Colors.white;
    final edgeHandleR = handleRadius * 0.55;
    for (final edgePos in edges) {
      canvas.drawCircle(edgePos, edgeHandleR, edgePaint);
    }

    // Draw corner handles
    final cornerPaint = Paint()..color = Colors.white;
    for (final cornerPos in corners) {
      canvas.drawCircle(cornerPos, handleRadius, cornerPaint);
    }

    // Draw active handle highlight
    if (activeHandle != null && allHandles.containsKey(activeHandle)) {
      final pos = allHandles[activeHandle]!;
      final isCorner = activeHandle == _DragHandle.topLeft ||
          activeHandle == _DragHandle.topRight ||
          activeHandle == _DragHandle.bottomRight ||
          activeHandle == _DragHandle.bottomLeft;
      final glowRadius = isCorner ? handleRadius + 6 : edgeHandleR + 6;

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, glowRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.activeHandle != activeHandle;
}
