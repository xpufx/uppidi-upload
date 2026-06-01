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

const _checkSize = 12.0;
const _checkLight = Color(0xFFD9D9D9);
const _checkDark = Color(0xFFBFBFBF);
const _checkLightDark = Color(0xFF404040);
const _checkDarkDark = Color(0xFF505050);

class _CheckeredPainter extends CustomPainter {
  final bool isDark;

  const _CheckeredPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final light = isDark ? _checkLightDark : _checkLight;
    final dark = isDark ? _checkDarkDark : _checkDark;
    final paint = Paint();
    final cols = (size.width / _checkSize).ceil();
    final rows = (size.height / _checkSize).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        paint.color = (x + y).isEven ? light : dark;
        canvas.drawRect(
          Rect.fromLTWH(x * _checkSize, y * _checkSize, _checkSize, _checkSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget checkeredWrapBody(
    ProImageEditorState editor, Stream<void> stream, Widget content) {
  final isDark = Theme.of(editor.context).brightness == Brightness.dark;
  return Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(painter: _CheckeredPainter(isDark: isDark)),
      ),
      content,
    ],
  );
}

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
            style: PaintEditorStyle(
              background: editorBg,
              bottomBarActiveItemColor: cs?.primary ?? const Color(0xFF004C9E),
              bottomBarInactiveItemColor: cs?.onSurfaceVariant ?? Colors.white,
            ),
          ),
          textEditor: TextEditorConfigs(
            style: TextEditorStyle(
              background: editorBg,
              bottomBarBackground: cs?.surfaceContainer ?? _bottomBarBg,
            ),
          ),
          cropRotateEditor: CropRotateEditorConfigs(
            style: CropRotateEditorStyle(
              background: editorBg,
              bottomBarBackground: cs?.surfaceContainer ?? _bottomBarBg,
            ),
          ),
          filterEditor: FilterEditorConfigs(
            style: FilterEditorStyle(background: editorBg),
          ),
          tuneEditor: TuneEditorConfigs(
            style: TuneEditorStyle(
              background: editorBg,
              bottomBarBackground: cs?.surfaceContainer ?? _bottomBarBg,
            ),
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
  final bottomFg = cs?.onSurfaceVariant ?? Colors.white;
  return MainEditorConfigs(
    enableSubEditorPage: true,
    style: MainEditorStyle(
      background: Colors.transparent,
      appBarBackground: cs?.surfaceContainerLow ?? _appBarBg,
      bottomBarBackground: cs?.surfaceContainer ?? _bottomBarBg,
      bottomBarColor: bottomFg,
      appBarColor: cs?.onSurface ?? Colors.white,
    ),
    widgets: MainEditorWidgets(
      appBar: (editor, rebuildStream) => ReactiveAppbar(
        stream: rebuildStream,
        builder: (_) => _buildAppBar(editor, fileName: fileName),
      ),
      wrapBody: checkeredWrapBody,
    ),
  );
}

AppBar _buildAppBar(
  ProImageEditorState editor, {
  String? fileName,
}) {
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
        onPressed: () => _saveToFile(editor, fileName: fileName),
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
