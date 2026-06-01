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
      _ScreenState.editing => _buildEditor(),
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

  Widget _buildEditor() {
    if (_originalBytes == null) return _buildPicker();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final editorBg = cs.surface;
    final barFg = cs.onSurface;
    final bottomFg = cs.onSurfaceVariant;

    return ProImageEditor.memory(
      _originalBytes!,
      key: ValueKey(_editorKey),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: _onImageEditingComplete,
        onCloseEditor: _onCloseEditor,
      ),
      configs: ProImageEditorConfigs(
        theme: theme,
        imageGeneration: const ImageGenerationConfigs(
          outputFormat: OutputFormat.jpg,
          jpegQuality: 100,
        ),
        designMode: ImageEditorDesignMode.cupertino,
        mainEditor: MainEditorConfigs(
          enableSubEditorPage: true,
          style: MainEditorStyle(
            background: Colors.transparent,
            appBarBackground: cs.surfaceContainerLow,
            appBarColor: barFg,
            bottomBarBackground: cs.surfaceContainer,
            bottomBarColor: bottomFg,
          ),
          widgets: MainEditorWidgets(
            appBar: (editor, rebuildStream) => ReactiveAppbar(
              stream: rebuildStream,
              builder: (_) => _buildEditorAppBar(editor),
            ),
            wrapBody: checkeredWrapBody,
          ),
        ),
        paintEditor: PaintEditorConfigs(
          style: PaintEditorStyle(
            background: editorBg,
            bottomBarActiveItemColor: cs.primary,
            bottomBarInactiveItemColor: bottomFg,
          ),
        ),
        textEditor: TextEditorConfigs(
          style: TextEditorStyle(
            background: editorBg,
            bottomBarBackground: cs.surfaceContainer,
          ),
        ),
        cropRotateEditor: CropRotateEditorConfigs(
          style: CropRotateEditorStyle(
            background: editorBg,
            bottomBarBackground: cs.surfaceContainer,
          ),
        ),
        filterEditor: FilterEditorConfigs(
          style: FilterEditorStyle(background: editorBg),
        ),
        tuneEditor: TuneEditorConfigs(
          style: TuneEditorStyle(
            background: editorBg,
            bottomBarBackground: cs.surfaceContainer,
          ),
        ),
        blurEditor: BlurEditorConfigs(
          style: BlurEditorStyle(background: editorBg),
        ),
        emojiEditor: EmojiEditorConfigs(
          style: EmojiEditorStyle(backgroundColor: editorBg),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEditorAppBar(ProImageEditorState editor) {
    final context = editor.context;
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? Colors.black87 : Colors.white;
    return AppBar(
      automaticallyImplyLeading: false,
      foregroundColor: fg,
      actions: [
        IconButton(
          icon: Icon(Icons.close, color: fg),
          tooltip: l10n.cancel,
          onPressed: editor.closeEditor,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.save_alt, color: fg),
          tooltip: l10n.saveToFile,
          onPressed: () => _saveToFileInline(editor),
        ),
        IconButton(
          icon: Icon(Icons.undo,
              color: editor.canUndo == true ? fg : fg.withAlpha(80)),
          onPressed: editor.canUndo == true ? editor.undoAction : null,
        ),
        IconButton(
          icon: Icon(Icons.redo,
              color: editor.canRedo == true ? fg : fg.withAlpha(80)),
          onPressed: editor.canRedo == true ? editor.redoAction : null,
        ),
        IconButton(
          icon: Icon(Icons.done, color: fg),
          tooltip: l10n.done,
          onPressed: editor.doneEditing,
        ),
      ],
    );
  }

  Future<void> _saveToFileInline(ProImageEditorState editor) async {
    final bytes = await editor.captureEditorImage();
    if (bytes.isEmpty) return;
    await _saveToDisk(bytes);
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
