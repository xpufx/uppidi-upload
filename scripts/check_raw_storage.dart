import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Checks that FlutterSecureStorage is only accessed in config_provider.dart.
/// Any import of flutter_secure_storage or direct use of _secure outside
/// that file is a violation — config should flow through Riverpod providers.
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
    final visitor = _StorageVisitor(file.path, result.lineInfo);
    result.unit.visitChildren(visitor);
    for (final v in visitor.violations) {
      stdout.writeln(v);
    }
    violations += visitor.violations.length ~/ 2;
  }

  if (violations > 0) {
    stderr.writeln('\n❌ Found $violations direct storage access violation(s).');
    stderr.writeln('   Config data must flow through providerConfigProvider.');
    stderr.writeln(
        '   Only lib/core/config_provider.dart may access FlutterSecureStorage directly.');
    exit(1);
  }

  stdout.writeln(
      '   ✅ No direct FlutterSecureStorage outside config_provider.dart');
}

class _StorageVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo _lineInfo;
  final List<String> violations = [];

  static const _allowedFile = 'config_provider.dart';

  _StorageVisitor(this.filePath, this._lineInfo);

  String _relativePath() {
    final uri = Uri.file(filePath);
    final segments = uri.pathSegments;
    final libIdx = segments.indexOf('lib');
    if (libIdx >= 0 && libIdx < segments.length - 1) {
      return segments.sublist(libIdx).join('/');
    }
    return filePath;
  }

  bool get _isAllowed => _relativePath() == 'lib/core/$_allowedFile';

  @override
  void visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);
    final uri = node.uri.stringValue;
    if (uri == 'package:flutter_secure_storage/flutter_secure_storage.dart' &&
        !_isAllowed) {
      final line = _lineInfo.getLocation(node.offset).lineNumber;
      violations.add('   ${_relativePath()}:$line');
      violations.add('      imports flutter_secure_storage');
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);
    if (_isAllowed) return;
    // Catches _secure.read() / _secure.write() / _secure.delete() etc.
    if (node.prefix.name == '_secure') {
      final line = _lineInfo.getLocation(node.offset).lineNumber;
      violations.add('   ${_relativePath()}:$line');
      violations.add('      _secure.${node.identifier.name}()');
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);
    if (_isAllowed) return;
    final type = node.constructorName.type;
    final name = type.name.lexeme;
    // Catch FlutterSecureStorage() constructor calls
    if (name == 'FlutterSecureStorage') {
      final line = _lineInfo.getLocation(node.offset).lineNumber;
      violations.add('   ${_relativePath()}:$line');
      violations.add('      FlutterSecureStorage() instantiation');
    }
  }
}
