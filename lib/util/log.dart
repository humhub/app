import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';

class GlobalLog extends LoggyPrinter {
  const GlobalLog({
    this.showColors,
  }) : super();

  final bool? showColors;

  bool get _colorize => showColors ?? false;

  static final _levelColors = {
    LogLevel.debug:
    AnsiColor(foregroundColor: AnsiColor.grey(0.5), italic: true),
    LogLevel.info: AnsiColor(foregroundColor: 35),
    LogLevel.warning: AnsiColor(foregroundColor: 214),
    LogLevel.error: AnsiColor(foregroundColor: 196),
  };

  static final _levelPrefixes = {
    LogLevel.debug: '🐛 ',
    LogLevel.info: '👻 ',
    LogLevel.warning: '⚠️ ',
    LogLevel.error: '‼️ ',
  };

  static const _defaultPrefix = '🤔 ';

  @override
  void onLog(LogRecord record) {
    final time = record.time.toIso8601String().split('T')[1];
    final callerFrame =
    record.callerFrame == null ? '-' : '(${record.callerFrame?.location})';
    final logLevel = record.level
        .toString()
        .replaceAll('Level.', '')
        .toUpperCase()
        .padRight(8);

    final color =
    _colorize ? levelColor(record.level) ?? AnsiColor() : AnsiColor();
    final prefix = levelPrefix(record.level) ?? _defaultPrefix;

    if (kDebugMode) {
      print(color(
        '$prefix$time $logLevel GLOBAL $callerFrame ${record.message}'));
    }

    if (record.stackTrace != null) {
      if (kDebugMode) {
        print(record.stackTrace);
      }
    }
  }

  String? levelPrefix(LogLevel level) {
    return _levelPrefixes[level];
  }

  AnsiColor? levelColor(LogLevel level) {
    return _levelColors[level];
  }
}