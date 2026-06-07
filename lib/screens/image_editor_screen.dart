import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/save_file.dart';
import '../l10n/app_localizations.dart';
import '../widgets/image_editor.dart';
import 'shell_strategy.dart';

/// Persists edited image data across tab switches so the user never loses
/// work — even if they bypass the unsaved-changes guard (e.g. desktop).
class ImageEditorData {
  final Uint8List originalBytes;
  final Uint8List? editedBytes;
  final String fileName;

  const ImageEditorData({
    required this.originalBytes,
    this.editedBytes,
    required this.fileName,
  });
}

class ImageEditorDataNotifier extends Notifier<ImageEditorData?> {
  @override
  ImageEditorData? build() => null;

  void set(ImageEditorData? data) => state = data;
}

final imageEditorDataProvider =
    NotifierProvider<ImageEditorDataNotifier, ImageEditorData?>(
  ImageEditorDataNotifier.new,
);

// ── Disk persistence ───────────────────────────────────────────────────────

Future<Directory> get _editorTempDir async {
  final dir = await getTemporaryDirectory();
  final editorDir = Directory('${dir.path}/uppidi_editor');
  if (!await editorDir.exists()) {
    await editorDir.create(recursive: true);
  }
  return editorDir;
}

Future<void> persistEditorToDisk(
  String fileName,
  Uint8List original,
  Uint8List? edited,
) async {
  final dir = await _editorTempDir;
  await File('${dir.path}/original.dat').writeAsBytes(original);
  if (edited != null) {
    await File('${dir.path}/edited.dat').writeAsBytes(edited);
  } else {
    final f = File('${dir.path}/edited.dat');
    if (await f.exists()) await f.delete();
  }
  await File('${dir.path}/meta.json').writeAsString(jsonEncode({
    'fileName': fileName,
    'hasEdited': edited != null,
  }));
}

Future<ImageEditorData?> loadEditorFromDisk() async {
  try {
    final dir = await _editorTempDir;
    final metaFile = File('${dir.path}/meta.json');
    if (!await metaFile.exists()) return null;

    final meta = jsonDecode(await metaFile.readAsString()) as Map;
    final fileName = meta['fileName'] as String;
    final hasEdited = meta['hasEdited'] as bool;

    final originalFile = File('${dir.path}/original.dat');
    if (!await originalFile.exists()) return null;
    final original = await originalFile.readAsBytes();

    Uint8List? edited;
    if (hasEdited) {
      final editedFile = File('${dir.path}/edited.dat');
      if (await editedFile.exists()) {
        edited = await editedFile.readAsBytes();
      }
    }

    return ImageEditorData(
      originalBytes: original,
      editedBytes: edited,
      fileName: fileName,
    );
  } catch (_) {
    return null;
  }
}

Future<void> clearEditorDisk() async {
  try {
    final dir = await _editorTempDir;
    for (final f in ['meta.json', 'original.dat', 'edited.dat']) {
      final file = File('${dir.path}/$f');
      if (await file.exists()) await file.delete();
    }
  } catch (_) {}
}

// ── Screen ─────────────────────────────────────────────────────────────────

enum _ScreenState { picker, editing, preview }

class ImageEditorScreen extends ConsumerStatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  _ScreenState _state = _ScreenState.picker;
  Uint8List? _originalBytes;
  Uint8List? _editedBytes;
  String? _fileName;
  int _editorKey = 0;
  bool _isSaved = true;

  @override
  void initState() {
    super.initState();
    _restoreFromProvider();
    if (_originalBytes == null) _loadPersistedFromDisk();
  }

  void _restoreFromProvider() {
    final data = ref.read(imageEditorDataProvider);
    if (data != null) {
      _originalBytes = data.originalBytes;
      _editedBytes = data.editedBytes;
      _fileName = data.fileName;
      _isSaved = data.editedBytes == null;
      _state =
          _editedBytes != null ? _ScreenState.preview : _ScreenState.editing;
      if (!_isSaved) {
        ref.read(canSwitchTabProvider.notifier).block(
              onSave: () => _saveToDisk(_editedBytes!),
            );
      }
    }
  }

  Future<void> _loadPersistedFromDisk() async {
    final data = await loadEditorFromDisk();
    if (data != null && mounted) {
      ref.read(imageEditorDataProvider.notifier).set(data);
      _restoreFromProvider();
    }
  }

  void _persistState() {
    if (_originalBytes == null || _fileName == null) {
      ref.read(imageEditorDataProvider.notifier).set(null);
      return;
    }
    ref.read(imageEditorDataProvider.notifier).set(ImageEditorData(
          originalBytes: _originalBytes!,
          editedBytes: _editedBytes,
          fileName: _fileName!,
        ));
  }

  void _persistToDisk() {
    if (_originalBytes == null || _fileName == null) return;
    persistEditorToDisk(_fileName!, _originalBytes!, _editedBytes);
  }

  void _clearAllPersisted() {
    ref.read(imageEditorDataProvider.notifier).set(null);
    clearEditorDisk();
  }

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
      _isSaved = true;
      _editorKey++;
      _state = _ScreenState.editing;
    });
    _persistToDisk();
    _persistState();
  }

  Future<void> _onImageEditingComplete(Uint8List bytes) async {
    _editedBytes = bytes;
    _isSaved = false;
    ref
        .read(canSwitchTabProvider.notifier)
        .block(onSave: () => _saveToDisk(_editedBytes!));
    setState(() => _state = _ScreenState.preview);
    _persistToDisk();
    _persistState();
  }

  void _onCloseEditor(EditorMode mode) {
    setState(() => _state =
        _editedBytes != null ? _ScreenState.preview : _ScreenState.picker);
  }

  Future<void> _saveToDisk(Uint8List bytes) async {
    final name = _fileName?.replaceAll(RegExp(r'\.\w+$'), '') ?? 'image';
    final savedPath = await saveFileCrossPlatform(
      bytes,
      '${name}_edited.jpg',
      dialogTitle: _l10n.saveEditedImage,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (savedPath != null && mounted) {
      _clearAllPersisted();
      ref.read(canSwitchTabProvider.notifier).allow();
      _isSaved = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.imageSaved)),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    if (_isSaved) return true;
    if (!mounted) return true;

    final action = await showDialog<_DiscardAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.unsavedChangesTitle),
        content: Text(_l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DiscardAction.cancel),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DiscardAction.discard),
            child: Text(_l10n.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _DiscardAction.save),
            child: Text(_l10n.save),
          ),
        ],
      ),
    );

    if (action == null || action == _DiscardAction.cancel) return false;

    if (action == _DiscardAction.save && _editedBytes != null) {
      await _saveToDisk(_editedBytes!);
    }

    _clearAllPersisted();
    ref.read(canSwitchTabProvider.notifier).allow();
    return true;
  }

  @override
  void dispose() {
    _persistState();
    _persistToDisk();
    ref.read(canSwitchTabProvider.notifier).allow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isSaved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: switch (_state) {
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
      },
    );
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
              onPressed: () async {
                if (!await _confirmDiscard()) return;
                if (!mounted) return;
                _clearAllPersisted();
                ref.read(canSwitchTabProvider.notifier).allow();
                setState(() {
                  _originalBytes = null;
                  _editedBytes = null;
                  _fileName = null;
                  _isSaved = true;
                  _state = _ScreenState.picker;
                });
              },
              icon: const Icon(Icons.image),
              label: Text(_l10n.openNewImage),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DiscardAction { save, discard, cancel }
