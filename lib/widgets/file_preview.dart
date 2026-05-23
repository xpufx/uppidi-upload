import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../core/format.dart';
import '../core/interfaces/uploader.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';
import 'image_crop_overlay.dart';

/// Previews a selected file (image or document) with crop and quality
/// controls for images. Used inside the upload screen.
class FilePreview extends StatefulWidget {
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final Uint8List? fileBytes;
  final BaseUploader? provider;
  final UploadNotifier notifier;

  const FilePreview({
    super.key,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.fileBytes,
    this.provider,
    required this.notifier,
  });

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  bool _hasCropped = false;
  Widget? _cachedImageWidget;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _isImage {
    final mime = widget.mimeType ?? '';
    return mime.startsWith('image/');
  }

  @override
  void didUpdateWidget(FilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileBytes != oldWidget.fileBytes) {
      _cachedImageWidget = null;
    }
  }

  Widget _createImageWidget() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Image.memory(
              widget.fileBytes!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnings = _buildWarnings();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.fileBytes != null && _isImage) ...[
                _buildImagePreview(),
                const SizedBox(height: 12),
              ] else if (_isImage) ...[
                const Center(
                    child: Icon(Icons.image_outlined,
                        size: 80, color: Colors.grey)),
                const SizedBox(height: 12),
              ] else ...[
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.insert_drive_file,
                        size: 48, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatSize(widget.fileSize),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (widget.mimeType != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.mimeType!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                ...warnings,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    _cachedImageWidget ??= _createImageWidget();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _cachedImageWidget!,
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(_hasCropped ? Icons.restore : Icons.crop),
            tooltip: _hasCropped ? _l10n.resetCrop : _l10n.apply,
            onPressed: _hasCropped
                ? () {
                    widget.notifier.resetCrop();
                    setState(() => _hasCropped = false);
                  }
                : _enterCropMode,
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(2),
            child: ValueListenableBuilder<int>(
              valueListenable: qualityNotifier,
              builder: (context, quality, _) {
                return SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                        value: 0, icon: const Icon(Icons.photo, size: 18)),
                    ButtonSegment(
                        value: 1, icon: const Icon(Icons.photo, size: 14)),
                    ButtonSegment(
                        value: 2, icon: const Icon(Icons.photo, size: 10)),
                  ],
                  selected: {quality},
                  onSelectionChanged: (v) =>
                      widget.notifier.setQuality(v.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0)),
                    minimumSize: WidgetStateProperty.all(const Size(0, 24)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _enterCropMode() async {
    if (widget.fileBytes == null) return;
    final decoded = img.decodeImage(widget.fileBytes!);
    if (decoded == null) return;
    final cropW = decoded.width;
    final cropH = decoded.height;

    if (!mounted) return;
    final cropRect = await ImageCropOverlay.show(
      context: context,
      imageBytes: widget.fileBytes!,
      imageWidth: cropW,
      imageHeight: cropH,
    );

    if (cropRect == null) return;

    final src = img.decodeImage(widget.fileBytes!);
    if (src == null || !mounted) return;

    final cropped = img.copyCrop(
      src,
      x: cropRect.left.toInt(),
      y: cropRect.top.toInt(),
      width: cropRect.width.toInt(),
      height: cropRect.height.toInt(),
    );

    final outBytes = img.encodeJpg(cropped, quality: 90);
    widget.notifier.applyCrop(outBytes);
    if (!mounted) return;
    setState(() => _hasCropped = true);
  }

  List<Widget> _buildWarnings() {
    final warnings = <Widget>[];
    final p = widget.provider;
    if (p == null) return warnings;
    final meta = p.metadata;

    if (meta.allowedMimeTypes != null && widget.mimeType != null) {
      if (!meta.allowsMimeType(widget.mimeType!)) {
        warnings
            .add(_warningRow(_l10n.providerOnlyAccepts(meta.mimeTypeLabel)));
      }
    }

    if (meta.maxFileSizeBytes != null &&
        widget.fileSize > meta.maxFileSizeBytes!) {
      warnings.add(_warningRow(_l10n.fileExceedsLimit(meta.fileSizeLabel)));
    }

    return warnings;
  }

  Widget _warningRow(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
