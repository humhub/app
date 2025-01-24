import 'package:flutter/foundation.dart';
import 'package:humhub/pages/console.dart';
import 'package:loggy/loggy.dart';
import 'package:talker_flutter/talker_flutter.dart' as tl;

class GlobalLog extends LoggyPrinter {
  const GlobalLog({
    this.showColors,
  }) : super();

  final bool? showColors;

  bool get _colorize => showColors ?? false;

  static final _levelColors = {
    LogLevel.debug: AnsiColor(foregroundColor: AnsiColor.grey(0.5), italic: true),
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
    final callerFrame = record.callerFrame == null ? '-' : '(${record.callerFrame?.location})';
    final logLevel = record.level.toString().replaceAll('Level.', '').toUpperCase().padRight(8);

    final color = _colorize ? levelColor(record.level) ?? AnsiColor() : AnsiColor();
    final prefix = levelPrefix(record.level) ?? _defaultPrefix;
    tl.Talker talker = ConsolePage.talker;
    // Log to Talker
    switch (record.level) {
      case LogLevel.debug:
        talker.debug(record.message, record.error, record.stackTrace);
        break;
      case LogLevel.info:
        talker.info(record.message, record.error, record.stackTrace);
        break;
      case LogLevel.warning:
        talker.warning(record.message, record.error, record.stackTrace);
        break;
      case LogLevel.error:
        talker.error(record.message, record.error, record.stackTrace);
        break;
      default:
        talker.log(record.message);
        break;
    }

    if (kDebugMode) {
      print(color('$prefix$time $logLevel GLOBAL $callerFrame ${record.message}'));
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
