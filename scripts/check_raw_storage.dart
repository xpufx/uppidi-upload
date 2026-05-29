import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// Checks that `FlutterSecureStorage` config VALUE reads go through
/// `providerConfigProvider`, not through direct `_secure` calls.
///
/// Allows:
/// - `config_provider.dart` — the single source of truth
/// - `provider_instances_*` key reads (metadata, separate domain)
/// - Writes to config keys (followed by `ref.invalidate`)
/// - Export/Import bulk ops (serialization concern)
///
/// Flags:
/// - `_secure.read(key)` where key starts with `provider_config_`
/// - `_secure.readAll()` whose result is iterated for config keys
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
    stderr.writeln(
        '\n❌ Found $violations direct config read(s) outside config_provider.');
    stderr.writeln('   Use providerConfigProvider to read config values.');
    exit(1);
  }

  stdout.writeln('   ✅ No direct config reads outside config_provider.dart');
}

class _StorageVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo _lineInfo;
  final List<String> violations = [];

  static const _allowedFiles = {'config_provider.dart', 'export_import.dart'};

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

  bool get _isAllowed {
    final name = _relativePath().split('/').last;
    return _allowedFiles.contains(name);
  }

  /// Returns true if [keyArg] is a string literal containing
  /// `provider_config_` (config value key, NOT instance metadata).
  bool _isConfigRead(Expression? keyArg) {
    if (keyArg is! SimpleStringLiteral) return false;
    final val = keyArg.stringValue ?? '';
    return val.startsWith('provider_config_');
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    if (_isAllowed) return;
    final methodName = node.methodName.name;

    // Catch _secure.read(key) where key starts with provider_config_
    if ((methodName == 'read' || methodName == 'delete') &&
        node.argumentList.arguments.isNotEmpty) {
      final firstArg = node.argumentList.arguments.first;
      if (_isConfigRead(firstArg)) {
        final line = _lineInfo.getLocation(node.offset).lineNumber;
        violations.add('   ${_relativePath()}:$line');
        violations.add('      direct config read — use providerConfigProvider');
      }
    }

    // Catch _secure.readAll() used for config keys
    if (methodName == 'readAll') {
      // Check if the node's target is _secure
      if (node.target is SimpleIdentifier &&
          (node.target as SimpleIdentifier).name == '_secure') {
        // Look at the parent — if it's used to iterate config keys, flag it
        // (Conservative: flag all readAll outside allowed file)
        final line = _lineInfo.getLocation(node.offset).lineNumber;
        violations.add('   ${_relativePath()}:$line');
        violations.add('      _secure.readAll() — use providerConfigProvider');
      }
    }
  }
}
