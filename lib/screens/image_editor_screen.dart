import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/android_save.dart';
import '../l10n/app_localizations.dart';
import '../widgets/image_editor.dart';

enum _ScreenState { picker, editing, preview }

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  _ScreenState _state = _ScreenState.picker;
  Uint8List? _originalBytes;
  Uint8List? _editedBytes;
  String? _fileName;
  int _editorKey = 0;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final bytes = await result.files.first.readAsBytes();
    if (!mounted) return;

    setState(() {
      _originalBytes = bytes;
      _fileName = result.files.first.name;
      _editedBytes = null;
      _editorKey++;
      _state = _ScreenState.editing;
    });
  }

  Future<void> _onImageEditingComplete(Uint8List bytes) async {
    _editedBytes = bytes;
    setState(() => _state = _ScreenState.preview);
  }

  void _onCloseEditor(EditorMode mode) {
    setState(() => _state =
        _editedBytes != null ? _ScreenState.preview : _ScreenState.picker);
  }

  Future<void> _saveToDisk(Uint8List bytes) async {
    final name = _fileName?.replaceAll(RegExp(r'\.\w+$'), '') ?? 'image';
    String? savedPath;
    if (Platform.isAndroid) {
      savedPath = await saveFileOnAndroid(bytes, '${name}_edited.jpg');
    } else {
      savedPath = await FilePicker.saveFile(
        dialogTitle: _l10n.saveEditedImage,
        fileName: '${name}_edited.jpg',
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        bytes: bytes,
      );
    }
    if (savedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.imageSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _ScreenState.picker => _buildPicker(),
      _ScreenState.editing => buildCheckeredEditor(
          imageBytes: _originalBytes!,
          key: ValueKey(_editorKey),
          theme: Theme.of(context),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: _onImageEditingComplete,
            onCloseEditor: _onCloseEditor,
          ),
        ),
      _ScreenState.preview => _buildPreview(),
    };
  }

  Widget _buildPicker() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _l10n.selectImageToEdit,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.image),
              label: Text(_l10n.chooseFile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final bytes = _editedBytes;
    if (bytes == null) return _buildPicker();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _saveToDisk(bytes),
              icon: const Icon(Icons.save),
              label: Text(_l10n.saveToFile),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _editedBytes = null;
                _editorKey++;
                _state = _ScreenState.editing;
              }),
              icon: const Icon(Icons.edit),
              label: Text(_l10n.editAgain),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _originalBytes = null;
                _editedBytes = null;
                _fileName = null;
                _state = _ScreenState.picker;
              }),
              icon: const Icon(Icons.image),
              label: Text(_l10n.openNewImage),
            ),
          ],
        ),
      ),
    );
  }
}
