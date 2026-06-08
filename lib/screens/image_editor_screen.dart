import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/save_file.dart';
import '../l10n/app_localizations.dart';
import '../widgets/image_editor.dart';

enum _ScreenState { picker, editing }

class ImageEditorScreen extends ConsumerStatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  _ScreenState _state = _ScreenState.picker;
  Uint8List? _originalBytes;
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
      _editorKey++;
      _state = _ScreenState.editing;
    });
  }

  Future<void> _onImageEditingComplete(Uint8List bytes) async {
    final action = await showDialog<_SaveAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.saveEditedImage),
        content: Text(_l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SaveAction.discard),
            child: Text(_l10n.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SaveAction.save),
            child: Text(_l10n.save),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == _SaveAction.save) {
      final saved = await _saveToDisk(bytes);
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.imageSaved)),
        );
      }
    }

    if (mounted) {
      setState(() {
        _originalBytes = null;
        _fileName = null;
        _state = _ScreenState.picker;
      });
    }
  }

  void _onCloseEditor(EditorMode mode) {
    setState(() {
      _originalBytes = null;
      _fileName = null;
      _state = _ScreenState.picker;
    });
  }

  Future<bool> _saveToDisk(Uint8List bytes) async {
    final name = _fileName?.replaceAll(RegExp(r'\.\w+$'), '') ?? 'image';
    final savedPath = await saveFileCrossPlatform(
      bytes,
      '${name}_edited.jpg',
      dialogTitle: _l10n.saveEditedImage,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    return savedPath != null;
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
}

enum _SaveAction { save, discard }
