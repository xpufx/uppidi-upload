import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A crop overlay that displays an image with a draggable/resizable selection
/// rectangle. Calls [onConfirm] with the crop region in original-image
/// coordinates when the user taps Apply.
class ImageCropOverlay extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageWidth;
  final int imageHeight;
  final ValueChanged<Rect> onConfirm;
  final VoidCallback onCancel;

  const ImageCropOverlay({
    super.key,
    required this.imageBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ImageCropOverlay> createState() => _ImageCropOverlayState();
}

/// Enum for identifying which drag handle (or the interior) is being dragged.
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

  static const double _handleRadius = 8.0;
  static const double _edgeHandleRadius = 6.0;
  static const double _handleHitArea = 24.0;
  static const double _minCropSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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

        // Initialize or re-initialize crop rect when display size changes
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
                // Image layer
                Image.memory(
                  widget.imageBytes,
                  width: displayWidth,
                  height: displayHeight,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 64,
                  ),
                ),
                // Dark mask with crop hole
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CropOverlayPainter(
                      cropRect: _cropRect,
                      handleRadius: _handleRadius,
                      edgeHandleRadius: _edgeHandleRadius,
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
                // Confirm/Cancel buttons
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final region = _toImageCoordinates();
                          widget.onConfirm(region);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      return; // no interaction
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
        final dx = delta.dx;
        final dy = delta.dy;
        l += dx;
        r += dx;
        t += dy;
        b += dy;
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

  /// Converts the current crop rect from display coordinates to
  /// original-image coordinates, then calls [onConfirm].
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

/// Paints the semi-transparent dark mask and the crop rectangle border + handles.
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final double handleRadius;
  final double edgeHandleRadius;

  _CropOverlayPainter({
    required this.cropRect,
    required this.handleRadius,
    required this.edgeHandleRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    // Draw 4 dark rectangles around the crop hole
    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), maskPaint);
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        cropRect.bottom,
        size.width,
        size.height - cropRect.bottom,
      ),
      maskPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      maskPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(
        cropRect.right,
        cropRect.top,
        size.width - cropRect.right,
        cropRect.height,
      ),
      maskPaint,
    );

    // Crop rectangle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // Corner handles (white filled circles)
    final cornerPaint = Paint()..color = Colors.white;
    for (final corner in [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomRight,
      cropRect.bottomLeft,
    ]) {
      canvas.drawCircle(corner, handleRadius, cornerPaint);
    }

    // Edge handles (slightly smaller circles)
    final edgePaint = Paint()..color = Colors.white;
    for (final pt in [
      Offset(cropRect.center.dx, cropRect.top),
      Offset(cropRect.center.dx, cropRect.bottom),
      Offset(cropRect.left, cropRect.center.dy),
      Offset(cropRect.right, cropRect.center.dy),
    ]) {
      canvas.drawCircle(pt, edgeHandleRadius, edgePaint);
    }
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}
