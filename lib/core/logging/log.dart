import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as pp;

enum LogLevel { debug, info, warn, error }

final class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
  });

  String get formatted {
    final ts = timestamp.toIso8601String().substring(11, 23);
    final lvl = level.name.toUpperCase().padLeft(5);
    return '$ts $lvl [${tag.padRight(20)}] $message';
  }
}

final class Log {
  final String tag;
  final LogLevel _minLevel;

  static File? _logFile;
  static bool _fileLoggingEnabled = false;
  static bool _enabled = false;
  static final List<LogEntry> _buffer = [];

  /// Enables or disables all logging. When disabled, no entries are
  /// written to the buffer or file.
  static void setEnabled(bool v) => _enabled = v;

  /// Max entries kept in the in-memory buffer (for instant display).
  /// The file log has no cap — it captures the full session.
  static const int _maxBufferEntries = 1000;

  Log(this.tag, {LogLevel minLevel = LogLevel.debug}) : _minLevel = minLevel;

  /// Enable or disable file-backed logging.
  /// When enabled, writes a session start marker and captures all log entries.
  /// When disabled, no file writes occur.
  static void enableFileLogging(bool enabled) {
    _fileLoggingEnabled = enabled;
    if (enabled) {
      unawaited(_writeSessionMarker());
    }
  }

  /// Write a session start marker to the file.
  static Future<void> _writeSessionMarker() async {
    try {
      await _ensureFile();
      final marker =
          '===== Session started ${DateTime.now().toIso8601String()} =====\n';
      await _logFile!.writeAsString(marker, mode: FileMode.append);
    } catch (_) {}
  }

  /// Max file size before truncation (1 MB).
  static const int _maxFileSize = 1024 * 1024;

  /// Ensure the log file exists (lazy init).
  static Future<void> _ensureFile() async {
    if (_logFile != null) return;
    final dir = await pp.getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/debug.log');
    _truncateIfNeeded();
  }

  /// Truncate the file to roughly the last [_maxFileSize] bytes.
  static Future<void> _truncateIfNeeded() async {
    try {
      if (_logFile == null) return;
      final exists = await _logFile!.exists();
      if (!exists) return;
      final len = await _logFile!.length();
      if (len <= _maxFileSize) return;
      // Keep the last 3/4 of max size from the end
      final keep = _maxFileSize * 3 ~/ 4;
      final raf = await _logFile!.open(mode: FileMode.read);
      await raf.setPosition(len - keep);
      final tail = await raf.read(keep);
      await raf.close();
      await _logFile!.writeAsString('=== truncated ===\n');
      await _logFile!.writeAsBytes(tail, mode: FileMode.append);
    } catch (_) {}
  }

  /// Returns a snapshot of the in-memory buffer.
  static List<LogEntry> get buffer => List.unmodifiable(_buffer);

  /// Returns the full log from the file (all sessions).
  static Future<String> get fullLog async {
    if (_logFile == null) return _buffer.map((e) => e.formatted).join('\n');
    if (!await _logFile!.exists()) return '';
    if (await _logFile!.length() > _maxFileSize * 2) {
      await _truncateIfNeeded();
    }
    return _logFile!.readAsString();
  }

  /// Clears both the in-memory buffer and the file.
  static void clearBuffer() {
    _buffer.clear();
    if (_logFile != null) {
      unawaited(_logFile!.writeAsString(''));
    }
  }

  void _log(LogLevel level, String message, {Object? error}) {
    if (!_enabled) return;
    if (_minLevel.index > level.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
    );

    dev.log(message, name: tag, level: level.index * 250);
    if (kDebugMode) stderr.writeln(entry.formatted);

    _buffer.add(entry);
    if (_buffer.length > _maxBufferEntries) {
      _buffer.removeAt(0);
    }

    if (_fileLoggingEnabled) {
      _writeToFile(entry);
    }
  }

  static Future<void> _writeToFile(LogEntry entry) async {
    try {
      await _ensureFile();
      await _logFile!
          .writeAsString('${entry.formatted}\n', mode: FileMode.append);
    } catch (_) {
      // File logging is best-effort; never crash over it.
    }
  }

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, message, error: error);
    // stackTrace intentionally unused here; _log writes structured entries
    // to the in-memory buffer and file. If full traceback is needed, callers
    // should include it in the message string.
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error);
    if (stackTrace != null) {
      _log(LogLevel.error, stackTrace.toString());
    }
  }
}

/// Traces all Riverpod provider state changes. One line captures every
/// state machine transition, settings change, and config update.
base class TracingObserver extends ProviderObserver {
  static final _log = Log('Tracing');

  /// Provider name substrings to skip entirely (noisy tickers/progress).
  static const _skip = ['AgeTick', 'VersionCheck', 'progress', 'sentBytes'];

  /// Provider name substrings whose values should be redacted.
  static const _secret = ['provider_config', 'ProviderConfig'];

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    final name =
        context.provider.name ?? context.provider.runtimeType.toString();
    for (final s in _skip) {
      if (name.contains(s)) return;
    }
    for (final s in _secret) {
      if (name.contains(s)) {
        _log.debug('$name: <redacted>');
        return;
      }
    }
    _log.debug('$name: $newValue');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final name =
        context.provider.name ?? context.provider.runtimeType.toString();
    _log.error('$name failed: $error', error: error, stackTrace: stackTrace);
  }
}

/// Traces all Navigator route changes (screen enter/leave).
class RouteTracer extends NavigatorObserver {
  static final _log = Log('Route');

  @override
  void didPush(Route route, Route? previousRoute) {
    _log.info('→ ${route.settings.name ?? route.runtimeType}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _log.info('← ${route.settings.name ?? route.runtimeType}');
  }
}

/// Singleton instance — use this, not `RouteTracer()`, to avoid leaks.
final routeTracer = RouteTracer();
