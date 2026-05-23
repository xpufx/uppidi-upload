import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

void main(List<String> args) {
  final dir = args.isNotEmpty ? args[0] : 'lib';
  final root = Directory(dir);
  if (!root.existsSync()) {
    stderr.writeln('Directory not found: $dir');
    exit(1);
  }

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int violations = 0;

  for (final file in files) {
    final result = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final visitor = _BareStringVisitor(file.path, result.lineInfo);
    result.unit.visitChildren(visitor);
    // visitor.violations stores 2 entries per violation (file+line, value)
    // so we divide by 2 for the count
    for (final v in visitor.violations) {
      stdout.writeln(v);
    }
    violations += visitor.violations.length ~/ 2;
  }

  if (violations > 0) {
    stderr.writeln('\n❌ Found $violations bare string(s) in UI code.');
    stderr
        .writeln('   Replace with l10n.* calls or add new keys to ARB files.');
    exit(1);
  }

  stdout.writeln('   ✅ No bare UI strings found');
}

class _BareStringVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo _lineInfo;
  final List<String> violations = [];

  // Named params that take a bare string (not wrapped in a Text widget).
  // 'title' is excluded — the only widget with a String 'title' param is
  // MaterialApp, which can't use AppLocalizations (constructor param).
  static const _uiParams = {
    'label',
    'hintText',
    'tooltip',
    'subtitle',
    'semanticLabel',
    'helperText',
  };

  _BareStringVisitor(this.filePath, this._lineInfo);

  String _relativePath() {
    final uri = Uri.file(filePath);
    final segments = uri.pathSegments;
    final libIdx = segments.indexOf('lib');
    if (libIdx >= 0 && libIdx < segments.length - 1) {
      return segments.sublist(libIdx).join('/');
    }
    return filePath;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    final typeName = _typeName(node.constructorName);
    if (typeName == null) return;
    if (typeName != 'Text' && typeName != 'TextButton') return;

    final args = node.argumentList.arguments;

    // For Text('...'), the first positional arg is the string
    if (typeName == 'Text' && args.isNotEmpty) {
      _checkStringArg(args.first);
    }

    // Check named parameters
    for (final arg in args) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (_uiParams.contains(name)) {
          _checkStringArg(arg.expression);
        }
      }
    }
  }

  String? _typeName(ConstructorName cn) {
    final type = cn.type;
    return type.name.lexeme;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    super.visitNamedExpression(node);
    final name = node.name.label.name;
    if (_uiParams.contains(name)) {
      _checkStringArg(node.expression);
    }
  }

  void _checkStringArg(Expression expr) {
    if (expr is! SimpleStringLiteral) return;
    final value = expr.stringValue;
    if (value == null) return;

    if (value.trim().isEmpty) return;
    if (value.length <= 1) return;
    if (_isAllowed(value)) return;

    final offset = expr.offset;
    final line = _lineInfo.getLocation(offset).lineNumber;
    violations.add('   ${_relativePath()}:$line');
    violations.add('      "$value"');
  }

  bool _isAllowed(String s) {
    if (s.startsWith('http://') ||
        s.startsWith('https://') ||
        s.startsWith('/') ||
        s.startsWith('.')) {
      return true;
    }
    if (RegExp(r'^[\d.]+$').hasMatch(s)) return true;
    if (RegExp(r'^[a-z][a-zA-Z0-9]+$').hasMatch(s)) return true;
    if (_startsWithFlag(s)) return true;
    return false;
  }

  bool _startsWithFlag(String s) {
    if (s.isEmpty) return false;
    final first = s.runes.first;
    // Regional indicator symbols (flag emojis): U+1F1E6–U+1F1FF
    if (first >= 0x1F1E6 && first <= 0x1F1FF) return true;
    return false;
  }
}
