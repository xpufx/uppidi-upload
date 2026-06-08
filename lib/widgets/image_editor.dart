import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../core/save_file.dart';
import '../l10n/app_localizations.dart';

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

Widget _checkeredStack(BuildContext context, Widget child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(painter: _CheckeredPainter(isDark: isDark)),
      ),
      child,
    ],
  );
}

ProImageEditorConfigs _themedConfigs(ThemeData? theme) {
  final cs = theme?.colorScheme;
  final fg = cs?.onSurface ?? Colors.white;
  return ProImageEditorConfigs(
    theme: theme,
    imageGeneration: const ImageGenerationConfigs(
      outputFormat: OutputFormat.jpg,
      jpegQuality: 100,
    ),
    designMode: defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? ImageEditorDesignMode.cupertino
        : ImageEditorDesignMode.material,
    mainEditor: MainEditorConfigs(
      enableSubEditorPage: true,
      style: MainEditorStyle(
        background: Colors.transparent,
        appBarBackground: cs?.surfaceContainerLow ?? const Color(0xFF000000),
        appBarColor: fg,
        bottomBarBackground: cs?.surfaceContainer ?? const Color(0xFF000000),
        bottomBarColor: cs?.onSurfaceVariant ?? Colors.white,
      ),
      widgets: MainEditorWidgets(
        appBar: (editor, rebuildStream) => ReactiveAppbar(
          stream: rebuildStream,
          builder: (_) => _buildAppBar(editor),
        ),
      ),
    ),
    paintEditor: PaintEditorConfigs(
      style: PaintEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
        bottomBarBackground: Colors.transparent,
        bottomBarActiveItemColor: cs?.primary ?? const Color(0xFF004C9E),
        bottomBarInactiveItemColor: cs?.onSurfaceVariant ?? Colors.white,
      ),
    ),
    textEditor: TextEditorConfigs(
      style: TextEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
        bottomBarBackground: Colors.transparent,
      ),
    ),
    cropRotateEditor: CropRotateEditorConfigs(
      animationDuration: Duration.zero,
      style: CropRotateEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
        bottomBarBackground: Colors.transparent,
      ),
    ),
    filterEditor: FilterEditorConfigs(
      style: FilterEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
      ),
    ),
    tuneEditor: TuneEditorConfigs(
      style: TuneEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
        bottomBarBackground: Colors.transparent,
      ),
    ),
    blurEditor: BlurEditorConfigs(
      style: BlurEditorStyle(
        background: cs?.surface ?? const Color(0xFF161616),
      ),
    ),
    emojiEditor: EmojiEditorConfigs(
      style: EmojiEditorStyle(
        backgroundColor: cs?.surface ?? const Color(0xFF161616),
      ),
    ),
  );
}

Future<Uint8List?> openImageEditor(
  BuildContext context, {
  required Uint8List imageBytes,
  String? fileName,
  OutputFormat outputFormat = OutputFormat.jpg,
  int jpegQuality = 100,
  ThemeData? theme,
  I18n? i18n,
}) {
  final configs = _themedConfigs(theme).copyWith(
    imageGeneration: ImageGenerationConfigs(
      outputFormat: outputFormat,
      jpegQuality: jpegQuality,
    ),
    i18n: i18n ?? const I18n(),
  );

  return Navigator.push<Uint8List>(
    context,
    MaterialPageRoute(
      builder: (_) => _checkeredStack(
        context,
        ProImageEditor.memory(
          imageBytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async =>
                Navigator.pop(context, bytes),
          ),
          configs: configs,
        ),
      ),
    ),
  );
}

Widget buildCheckeredEditor({
  required Uint8List imageBytes,
  required ProImageEditorCallbacks callbacks,
  Key? key,
  ThemeData? theme,
  OutputFormat outputFormat = OutputFormat.jpg,
  int jpegQuality = 100,
  I18n? i18n,
}) {
  final configs = _themedConfigs(theme).copyWith(
    imageGeneration: ImageGenerationConfigs(
      outputFormat: outputFormat,
      jpegQuality: jpegQuality,
    ),
    i18n: i18n ?? const I18n(),
  );

  return Builder(
    builder: (ctx) => _checkeredStack(
      ctx,
      ProImageEditor.memory(
        imageBytes,
        key: key,
        callbacks: callbacks,
        configs: configs,
      ),
    ),
  );
}

AppBar _buildAppBar(ProImageEditorState editor) {
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
        onPressed: () => _saveToFile(editor),
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

  final savedPath = await saveFileCrossPlatform(
    bytes,
    '${fileName ?? 'image'}_edited.jpg',
    dialogTitle: l10n.saveEditedImage,
    allowedExtensions: ['jpg', 'jpeg', 'png'],
  );
  if (savedPath != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.imageSaved)),
    );
  }
}
