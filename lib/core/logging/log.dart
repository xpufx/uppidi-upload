import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

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
  static bool _fileReady = false;
  static final List<LogEntry> _buffer = [];

  /// Max entries kept in the in-memory buffer (for instant display).
  /// The file log has no cap — it captures the full session.
  static const int _maxBufferEntries = 1000;

  Log(this.tag, {LogLevel minLevel = LogLevel.debug}) : _minLevel = minLevel;

  /// Ensure the log file exists and write a session start marker.
  static Future<void> _ensureFile() async {
    if (_fileReady) return;
    _fileReady = true;
    final dir = await pp.getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/debug.log');
    final marker =
        '===== Session started ${DateTime.now().toIso8601String()} =====\n';
    await _logFile!.writeAsString(marker, mode: FileMode.append);
  }

  /// Returns a snapshot of the in-memory buffer.
  static List<LogEntry> get buffer => List.unmodifiable(_buffer);

  /// Returns the full log from the file (all sessions).
  static Future<String> get fullLog async {
    if (_logFile == null) return _buffer.map((e) => e.formatted).join('\n');
    if (!await _logFile!.exists()) return '';
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
    if (_minLevel.index > level.index) return;

    dev.log(message, name: tag, level: level.index * 250);

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
    );

    _buffer.add(entry);
    if (_buffer.length > _maxBufferEntries) {
      _buffer.removeAt(0);
    }

    // Fire-and-forget: write to file for full session history.
    // This runs after the synchronous path so the UI is never blocked.
    _writeToFile(entry);
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
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error);
  }
}
