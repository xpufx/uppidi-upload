import 'dart:convert';
import 'dart:io';

/// Checks that translated ARB files have actual translations, not just copies
/// of the English values.
///
/// Keys can be exempted by adding them to [exemptedKeys] below, with a reason.
///
/// Usage: dart run scripts/check_untranslated_arb.dart
void main(List<String> args) {
  final dir = args.isNotEmpty ? args[0] : 'lib/l10n';
  final l10nDir = Directory(dir);
  if (!l10nDir.existsSync()) {
    stderr.writeln('Directory not found: $dir');
    exit(1);
  }

  final files = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  File? templateFile;
  final Map<String, File> localeFiles = {};

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    if (name == 'intl_en.arb') {
      templateFile = f;
    } else {
      final match = RegExp(r'intl_(\w+)\.arb').firstMatch(name);
      if (match != null) {
        localeFiles[match.group(1)!] = f;
      }
    }
  }

  if (templateFile == null) {
    stderr.writeln('Template file intl_en.arb not found in $dir');
    exit(1);
  }

  final templateData =
      jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;

  int totalViolations = 0;

  for (final entry in localeFiles.entries) {
    final locale = entry.key;
    final localeData =
        jsonDecode(entry.value.readAsStringSync()) as Map<String, dynamic>;

    final localeViolations = <String, String>{};

    for (final key in templateData.keys) {
      if (key.startsWith('@')) continue;

      final templateValue = templateData[key];
      if (templateValue is! String) continue;
      if (templateValue.trim().isEmpty) continue;

      final localeValue = localeData[key];
      if (localeValue is! String) continue;

      if (localeValue == templateValue) {
        if (exemptedLocales.contains(locale)) continue;
        if (!exemptedKeys.contains(key)) {
          localeViolations[key] = templateValue;
        }
      }
    }

    if (localeViolations.isNotEmpty) {
      totalViolations += localeViolations.length;
      stdout.writeln(
          '\n=== $locale (${localeViolations.length} untranslated) ===');
      for (final entry in localeViolations.entries) {
        stdout.writeln('  ${entry.key}: "${entry.value}"');
      }
    }
  }

  if (totalViolations > 0) {
    stderr.writeln(
      '\n❌ Found $totalViolations untranslated string(s) in ARB files.',
    );
    stderr.writeln(
      '   Translate them in the respective intl_*.arb files, or',
    );
    stderr.writeln(
      '   add to exemptedKeys in scripts/check_untranslated_arb.dart',
    );
    stderr.writeln(
      '   if the value is intentionally identical (URLs, units, etc).',
    );
    exit(1);
  }

  stdout.writeln('   ✅ All translated ARB files have actual translations');
}

/// Keys where the translation is intentionally identical to English.
///
/// **Brand / proper nouns**: URLs, app names, unit patterns
/// **Technical terms adopted as-is in target locale**: e.g. cropImage
/// **Config field labels**: These are field names / identifiers, not UI text
///
/// Other keys should be translated. Add here only after confirming
/// with the user.
/// Locales to skip entirely (e.g. novelty/joke languages).
const exemptedLocales = <String>{
  'tlh', // Klingon — novelty language, not worth translating
};

const exemptedKeys = <String>{
  // Brand / metadata (never translated)
  'appTitle',
  'versionPrefix',
  'versionLabel',
  'gplUrl',

  // Unit / number patterns (structure, not words)
  'speedBS',
  'speedKBS',
  'speedMBS',
  'secondsAgo',
  'minutesAgo',

  // Config field labels — field names / identifiers, not UI text
  'proxyUrl',
  'userAgent',
  'configLabelServerUrl',
  'configLabelEmail',
  'configLabelApiKey',
  'configLabelInstanceName',
  'configInstanceNameHelper',
  'configLabelChannel',
  'configLabelTopic',
  'configLabelDirectMessage',
  'configLabelGateway',

  // Connectivity test — server response fragments, not user-facing UI
  'connectedAs',
  'chatAccessible',

  // Universal loanword, same in all locales
  'emojiTool',

  // Format / unit patterns — abbreviations differ by locale but "h" (hour)
  // and the numeric pattern are universal enough
  'expiryOptions1h12h24h72h',
  'proxyHint',

  // Universal short response
  'ok',
};
