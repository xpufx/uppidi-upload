import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/android_save.dart';
import '../l10n/app_localizations.dart';

const _defaultOutputFormat = OutputFormat.jpg;

const _editorBg = Color(0xFF161616);
const _appBarBg = Color(0xFF000000);
const _bottomBarBg = Color(0xFF000000);

Future<Uint8List?> openImageEditor(
  BuildContext context, {
  required Uint8List imageBytes,
  String? fileName,
  OutputFormat outputFormat = _defaultOutputFormat,
  int jpegQuality = 100,
  ThemeData? theme,
  I18n? i18n,
}) {
  final cs = theme?.colorScheme;
  final editorBg = cs?.surface ?? _editorBg;

  return Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      builder: (_) => ProImageEditor.memory(
        imageBytes,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (bytes) async =>
              Navigator.pop(context, bytes),
        ),
        configs: ProImageEditorConfigs(
          theme: theme,
          i18n: i18n ?? const I18n(),
          imageGeneration: ImageGenerationConfigs(
            outputFormat: outputFormat,
            jpegQuality: jpegQuality,
          ),
          designMode: ImageEditorDesignMode.cupertino,
          mainEditor: _buildMainEditorConfigs(editorBg, cs, fileName),
          paintEditor: PaintEditorConfigs(
            style: PaintEditorStyle(background: editorBg),
          ),
          textEditor: TextEditorConfigs(
            style: TextEditorStyle(background: editorBg),
          ),
          cropRotateEditor: CropRotateEditorConfigs(
            style: CropRotateEditorStyle(background: editorBg),
          ),
          filterEditor: FilterEditorConfigs(
            style: FilterEditorStyle(background: editorBg),
          ),
          tuneEditor: TuneEditorConfigs(
            style: TuneEditorStyle(background: editorBg),
          ),
          blurEditor: BlurEditorConfigs(
            style: BlurEditorStyle(background: editorBg),
          ),
          emojiEditor: EmojiEditorConfigs(
            style: EmojiEditorStyle(backgroundColor: editorBg),
          ),
        ),
      ),
    ),
  );
}

MainEditorConfigs _buildMainEditorConfigs(
  Color editorBg,
  ColorScheme? cs,
  String? fileName,
) {
  return MainEditorConfigs(
    style: MainEditorStyle(
      background: editorBg,
      appBarBackground: cs?.surfaceContainerLow ?? _appBarBg,
      bottomBarBackground: cs?.surfaceContainer ?? _bottomBarBg,
    ),
    widgets: MainEditorWidgets(
      appBar: (editor, rebuildStream) => ReactiveAppbar(
        stream: rebuildStream,
        builder: (_) => _buildAppBar(editor, fileName: fileName),
      ),
    ),
  );
}

AppBar _buildAppBar(
  ProImageEditorState editor, {
  String? fileName,
}) {
  final context = editor.context;
  final l10n = AppLocalizations.of(context);
  return AppBar(
    automaticallyImplyLeading: false,
    foregroundColor: Colors.white,
    actions: [
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.cancel,
        onPressed: editor.closeEditor,
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.save_alt),
        tooltip: l10n.saveToFile,
        onPressed: () => _saveToFile(editor, fileName: fileName),
      ),
      IconButton(
        icon: Icon(Icons.undo,
            color: editor.canUndo == true
                ? Colors.white
                : Colors.white.withAlpha(80)),
        onPressed: editor.canUndo == true ? editor.undoAction : null,
      ),
      IconButton(
        icon: Icon(Icons.redo,
            color: editor.canRedo == true
                ? Colors.white
                : Colors.white.withAlpha(80)),
        onPressed: editor.canRedo == true ? editor.redoAction : null,
      ),
      IconButton(
        icon: const Icon(Icons.done),
        tooltip: l10n.done,
        onPressed: editor.doneEditing,
      ),
    ],
  );
}

Future<void> _saveToFile(
  ProImageEditorState editor, {
  String? fileName,
}) async {
  final context = editor.context;
  final l10n = AppLocalizations.of(context);

  final bytes = await editor.captureEditorImage();
  if (bytes.isEmpty) return;

  String? savedPath;
  if (Platform.isAndroid) {
    savedPath =
        await saveFileOnAndroid(bytes, '${fileName ?? 'image'}_edited.jpg');
  } else {
    savedPath = await FilePicker.saveFile(
      dialogTitle: l10n.saveEditedImage,
      fileName: '${fileName ?? 'image'}_edited.jpg',
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      bytes: bytes,
    );
  }
  if (savedPath != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.imageSaved)),
    );
  }
}
