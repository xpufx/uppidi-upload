import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/android_save.dart';
import '../core/format.dart';
import '../core/interfaces/uploader.dart';
import '../core/editor_i18n.dart';
import '../core/logging/log.dart';
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
  bool _isModified = false;
  Uint8List? _lastEditedBytes;
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
      _isModified = false;
      _lastEditedBytes = null;
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
          if (_isModified) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore, size: 18),
                  label: Text(_l10n.revertEdits),
                  onPressed: () {
                    widget.notifier.revertEdits();
                    setState(() => _isModified = false);
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(_l10n.save),
                  onPressed: _saveEditedCopy,
                ),
              ],
            ),
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
            icon: Icon(_isModified ? Icons.restore : Icons.edit),
            tooltip: _isModified ? _l10n.revertEdits : _l10n.editImage,
            onPressed: _isModified
                ? () {
                    widget.notifier.revertEdits();
                    setState(() => _isModified = false);
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
    final l10n = AppLocalizations.of(context);

    final decoded = img.decodeImage(widget.fileBytes!);
    final dims =
        decoded != null ? '${decoded.width}\u00d7${decoded.height}' : null;
    final mimeLabel = widget.mimeType ?? 'image/jpeg';
    final outputMime = _outputMimeType(widget.mimeType);
    final outputFormat = _outputFormat(widget.mimeType);

    final i18n = buildEditorI18n(l10n);
    final log = Log('FilePreview');
    log.debug('editor i18n: cancel="${i18n.cancel}" done="${i18n.done}"');

    final edited = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          widget.fileBytes!,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async =>
                Navigator.pop(context, bytes),
          ),
          configs: ProImageEditorConfigs(
            imageGeneration: ImageGenerationConfigs(
              outputFormat: outputFormat,
              jpegQuality: 100,
            ),
            designMode: ImageEditorDesignMode.cupertino,
            i18n: i18n,
            mainEditor: MainEditorConfigs(
              widgets: MainEditorWidgets(
                wrapBody: (_, __, content) => Stack(
                  children: [
                    content,
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _ImageInfoBadge(
                        dimensions: dims,
                        fileSize: formatSize(widget.fileSize),
                        mimeType: mimeLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (edited == null || !mounted) return;
    _lastEditedBytes = edited;
    widget.notifier.applyEdit(edited, outputMimeType: outputMime);
    setState(() => _isModified = true);
  }

  Future<void> _saveEditedCopy() async {
    final raw = _lastEditedBytes;
    if (raw == null || !mounted) return;
    final baseName = widget.fileName.replaceAll(RegExp(r'\.\w+$'), '');
    final ext = _outputFormat(widget.mimeType) == OutputFormat.png
        ? 'png'
        : _outputFormat(widget.mimeType) == OutputFormat.bmp
            ? 'bmp'
            : 'jpg';
    String? savedPath;
    if (Platform.isAndroid) {
      savedPath = await saveFileOnAndroid(
        raw,
        '$baseName.$ext',
        mimeType: _outputMimeType(widget.mimeType),
      );
    } else {
      savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save edited image',
        fileName: '$baseName.$ext',
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: raw,
      );
    }
    if (savedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $savedPath')),
      );
    }
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

  static OutputFormat _outputFormat(String? mimeType) {
    return switch (mimeType) {
      'image/png' => OutputFormat.png,
      'image/bmp' => OutputFormat.bmp,
      'image/tiff' || 'image/tif' => OutputFormat.tiff,
      _ => OutputFormat.jpg,
    };
  }

  static String _outputMimeType(String? mimeType) {
    return switch (mimeType) {
      'image/png' => 'image/png',
      'image/bmp' => 'image/bmp',
      'image/tiff' || 'image/tif' => 'image/tiff',
      _ => 'image/jpeg',
    };
  }
}

class _ImageInfoBadge extends StatelessWidget {
  const _ImageInfoBadge({
    required this.dimensions,
    required this.fileSize,
    required this.mimeType,
  });

  final String? dimensions;
  final String fileSize;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (dimensions != null) dimensions!,
      fileSize,
      mimeType.split('/').last.toUpperCase(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        parts.join(' \u00b7 '),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
