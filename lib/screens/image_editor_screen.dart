import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/logging/log.dart';
import '../core/save_file.dart';
import '../l10n/app_localizations.dart';
import '../widgets/image_editor.dart';

enum _ScreenState { picker, editing }

final _editorLog = Log('ImageEditor');

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
    if (result == null || result.files.isEmpty) {
      _editorLog.info('File pick cancelled');
      return;
    }
    if (!mounted) return;

    final bytes = await result.files.first.readAsBytes();
    final name = result.files.first.name;
    if (!mounted) return;

    _editorLog.info('Picked: $name, ${bytes.length} bytes');
    setState(() {
      _originalBytes = bytes;
      _fileName = name;
      _editorKey++;
      _state = _ScreenState.editing;
    });
  }

  Future<void> _onImageEditingComplete(Uint8List bytes) async {
    _editorLog.info('Edit complete: ${bytes.length} bytes');
    // Remove pro_image_editor from tree first so its loading overlay
    // doesn't block the save dialog.
    setState(() {
      _state = _ScreenState.picker;
    });
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

    if (action == null) {
      _editorLog.info('Save dialog dismissed (barrier tap)');
      setState(() {
        _originalBytes = null;
        _fileName = null;
      });
      return;
    }

    if (action == _SaveAction.save) {
      _editorLog.info('User chose Save');
      final saved = await _saveToDisk(bytes);
      if (saved && mounted) {
        _editorLog.info('Save dialog completed — file saved');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.imageSaved)),
        );
      } else {
        _editorLog.info('Save dialog cancelled by user');
      }
    } else {
      _editorLog.info('User chose Discard');
      setState(() {
        _originalBytes = null;
        _fileName = null;
      });
    }
  }

  void _onCloseEditor(EditorMode mode) {
    _editorLog.info('Editor closed: $_fileName (state=$_state)');
    setState(() {
      _originalBytes = null;
      _fileName = null;
      _state = _ScreenState.picker;
    });
  }

  Future<bool> _saveToDisk(Uint8List bytes) async {
    final name = _fileName?.replaceAll(RegExp(r'\.\w+$'), '') ?? 'image';
    _editorLog.info('Opening save dialog for $name');
    final savedPath = await saveFileCrossPlatform(
      bytes,
      '${name}_edited.jpg',
      dialogTitle: _l10n.saveEditedImage,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    _editorLog.info('Save dialog returned: ${savedPath ?? "null (cancelled)"}');
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
