import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/format.dart';
import '../core/interfaces/uploader.dart';
import '../l10n/app_localizations.dart';
import '../providers/upload_provider.dart';

/// Previews a selected file (image or document) with edit controls for
/// images (opens the full image editor). Used inside the upload screen.
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
      _hasCropped = false;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fileBytes != null && _isImage) ...[
            _buildImagePreview(),
            const SizedBox(height: 12),
          ] else if (_isImage) ...[
            const Center(
                child:
                    Icon(Icons.image_outlined, size: 80, color: Colors.grey)),
            const SizedBox(height: 12),
          ] else ...[
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
            icon: Icon(_hasCropped ? Icons.restore : Icons.edit),
            tooltip: _hasCropped ? _l10n.resetCrop : 'Edit image',
            onPressed: _hasCropped
                ? () {
                    widget.notifier.resetCrop();
                    setState(() => _hasCropped = false);
                  }
                : _openEditor,
            style: IconButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor() async {
    if (widget.fileBytes == null) return;
    if (!mounted) return;
    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          widget.fileBytes!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async =>
                Navigator.pop(context, bytes),
          ),
          configs: const ProImageEditorConfigs(
            imageGeneration: ImageGenerationConfigs(
              outputFormat: OutputFormat.jpg,
              jpegQuality: 100,
            ),
            designMode: ImageEditorDesignMode.cupertino,
          ),
        ),
      ),
    );
    if (edited == null || !mounted) return;
    widget.notifier.applyCrop(edited);
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
