import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Checks that provider upload() methods use typed config classes instead of
/// raw `Map<String, String>`.  Wide maps allow invented keys that the type
/// system cannot check.
///
/// Run with `--fatal` to exit non-zero on violations (enabled after all
/// providers are migrated to typed configs).
void main(List<String> args) {
  final fatal = args.contains('--fatal');

  final dir = 'lib/providers';
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
    final visitor = _WideConfigVisitor(file.path, result.lineInfo);
    result.unit.visitChildren(visitor);
    for (final v in visitor.violations) {
      stdout.writeln(v);
    }
    violations += visitor.violations.length ~/ 2;
  }

  if (violations > 0) {
    stderr.writeln(
        '\n⚠️  Found $violations upload() with wide Map<String, String> config.');
    stderr.writeln('   Use a typed config class per provider instead.');
    if (fatal) {
      stderr.writeln('   (--fatal: failing build)');
      exit(1);
    }
  } else {
    stdout.writeln('   ✅ No wide Map<String, String> in upload() signatures');
  }
}

class _WideConfigVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo _lineInfo;
  final List<String> violations = [];

  _WideConfigVisitor(this.filePath, this._lineInfo);

  String _relativePath() {
    final uri = Uri.file(filePath);
    final segments = uri.pathSegments;
    final libIdx = segments.indexOf('lib');
    if (libIdx >= 0 && libIdx < segments.length - 1) {
      return segments.sublist(libIdx).join('/');
    }
    return filePath;
  }

  bool _isMapStringString(TypeAnnotation? type) {
    if (type is! NamedType) return false;
    final name = type.name.lexeme;
    if (name != 'Map') return false;
    // Check for Map<String, String>
    if (name == 'Map') {
      final args = type.typeArguments;
      if (args == null || args.arguments.length < 2) return false;
      final first = args.arguments[0];
      final second = args.arguments[1];
      return first is NamedType &&
          first.name.lexeme == 'String' &&
          second is NamedType &&
          second.name.lexeme == 'String';
    }
    return false;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    super.visitMethodDeclaration(node);
    if (node.name.lexeme != 'upload') return;
    // Check return type is Future<UploadResult>
    if (node.returnType is! NamedType) return;
    final ret = node.returnType as NamedType;
    if (ret.name.lexeme != 'Future') return;

    // Check parameters for Map<String, String>
    final params = node.parameters;
    if (params == null) return;
    for (final param in params.parameters) {
      // Get type annotation from any formal parameter kind
      TypeAnnotation? typeAnn;
      if (param is SimpleFormalParameter) {
        typeAnn = param.type;
      } else if (param is DefaultFormalParameter) {
        // Map<String, String> config = const {}  → wrapped in DefaultFormalParameter
        final inner = param.parameter;
        if (inner is SimpleFormalParameter) {
          typeAnn = inner.type;
        } else if (inner is FieldFormalParameter) {
          typeAnn = inner.type;
        }
      } else if (param is FieldFormalParameter) {
        typeAnn = param.type;
      }
      if (_isMapStringString(typeAnn)) {
        final line = _lineInfo.getLocation(param.offset).lineNumber;
        violations.add('   ${_relativePath()}:$line');
        final name = param is SimpleFormalParameter
            ? param.name?.lexeme ?? '?'
            : param is FieldFormalParameter
                ? param.name.lexeme
                : (param is DefaultFormalParameter
                    ? (param.parameter is SimpleFormalParameter
                        ? (param.parameter as SimpleFormalParameter)
                                .name
                                ?.lexeme ??
                            '?'
                        : '?')
                    : '?');
        violations.add('      $name: Map<String, String> — use typed config');
      }
    }
  }
}
