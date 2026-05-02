import 'dart:developer' as dev;

enum LogLevel { debug, info, warn, error }

final class Log {
  final String tag;
  final LogLevel _minLevel;

  Log(this.tag, {LogLevel minLevel = LogLevel.debug}) : _minLevel = minLevel;

  void debug(String message) {
    if (_minLevel.index <= LogLevel.debug.index) {
      dev.log(message, name: tag, level: 0);
    }
  }

  void info(String message) {
    if (_minLevel.index <= LogLevel.info.index) {
      dev.log(message, name: tag, level: 800);
    }
  }

  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    if (_minLevel.index <= LogLevel.warn.index) {
      dev.log(message, name: tag, level: 900, error: error, stackTrace: stackTrace);
    }
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (_minLevel.index <= LogLevel.error.index) {
      dev.log(message, name: tag, level: 1000, error: error, stackTrace: stackTrace);
    }
  }
}
