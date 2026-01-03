// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:log_me/log_me.dart' as me;
import 'package:sentry_flutter/sentry_flutter.dart';

import '/config.dart';
import 'new_type.dart';
import 'obs/rxlist.dart';

/// Global variable to access [LogImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
LogImpl Log = LogImpl();

/// Utility logging messages to console.
class LogImpl {
  /// List of [String]s representing the logs kept in the variable.
  final RxObsList<LogEntry> logs = RxObsList();

  /// Amount of [logs] to keep in the variable.
  ///
  /// If set to zero, then no [logs] will be kept at all in the variable.
  int maxLogs = 0;

  /// Prints the fatal [message] with [tag] to the [me.Log].
  void fatal(String message, [String? tag]) {
    _print(me.LogLevel.fatal, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.fatal);
  }

  /// Prints the error [message] with [tag] to the [me.Log].
  void error(String message, [String? tag]) {
    _print(me.LogLevel.error, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.error);
  }

  /// Prints the warning [message] with [tag] to the [me.Log].
  void warning(String message, [String? tag]) {
    _print(me.LogLevel.warning, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.warning);
  }

  /// Prints the information [message] with [tag] to the [me.Log].
  void info(String message, [String? tag]) {
    _print(me.LogLevel.info, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.info);
  }

  /// Prints the debug [message] with [tag] to the [me.Log].
  void debug(String message, [String? tag]) {
    _print(me.LogLevel.debug, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.debug);
  }

  /// Prints the trace [message] with [tag] to the [me.Log].
  void trace(String message, [String? tag]) {
    _print(me.LogLevel.trace, '${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.debug);
  }

  /// Reports the [exception] to [Sentry], if enabled.
  Future<void> report(Exception exception, {StackTrace? trace}) async {
    if (!kDebugMode && Config.sentryDsn.isNotEmpty) {
      try {
        await Sentry.captureException(exception, stackTrace: trace);
      } catch (_) {
        // No-op.
      }
    }
  }

  /// Reports a [Breadcrumb] with the provided details to the [Sentry], if
  /// enabled.
  Future<void> _breadcrumb(
    String message,
    String? tag,
    SentryLevel level,
  ) async {
    if (!kDebugMode && Config.sentryDsn.isNotEmpty) {
      try {
        await Sentry.addBreadcrumb(
          Breadcrumb.console(message: '[$tag] $message', level: level),
        );
      } catch (_) {
        // No-op.
      }
    }
  }

  /// Stores the provided [text] to the [logs].
  void _print(me.LogLevel level, String text) {
    switch (level) {
      case me.LogLevel.fatal:
        me.Log.fatal(text);
        break;

      case me.LogLevel.error:
        me.Log.error(text);
        break;

      case me.LogLevel.warning:
        me.Log.warning(text);
        break;

      case me.LogLevel.info:
        me.Log.info(text);
        break;

      case me.LogLevel.debug:
        me.Log.debug(text);
        break;

      case me.LogLevel.trace:
        me.Log.trace(text);
        break;

      case me.LogLevel.off:
      case me.LogLevel.all:
        // No-op.
        break;
    }

    if (maxLogs > 0) {
      if (level == me.LogLevel.trace) {
        return;
      }

      final DateTime at = DateTime.now().toUtc();

      // Fixes `setState() or markNeedsBuild() called during build`.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        logs.add(LogEntry(level, text, at));
        while (logs.length > maxLogs) {
          logs.removeAt(0);
        }
      });
    }
  }
}

/// Entity representing a log in the log entries.
class LogEntry {
  const LogEntry(this.level, this.text, this.at);

  /// Level of this entry.
  final me.LogLevel level;

  /// Log itself.
  final String text;

  /// [DateTime] this entry is created at.
  final DateTime at;

  @override
  String toString() => '[${at.toUtc().toStamp}] [${level.name}] $text';
}

/// Extension adding obscured getter to [NewType]s.
extension ObscuredNewTypeExtension on NewType {
  /// Returns this value as an obscured string.
  ///
  /// Intended to be used to obscure sensitive information in [Log]s:
  /// ```dart
  /// // - prints `[Type] signIn(password: ***)`, when non-`null`;
  /// // - prints `[Type] signIn(password: null)`, when `null`;
  /// Log.debug('signIn(password: ${password?.obscured})', '$runtimeType');
  /// ```
  String get obscured {
    if (Config.logObfuscated) {
      return '***';
    }

    return toString();
  }
}

/// Extension adding obscured getter to [JsonSerializable]s.
extension JsonSerializableExtension on JsonSerializable {
  /// Returns this value as an obscured string.
  String get obscured {
    if (Config.logObfuscated) {
      return '***';
    }

    return toJson().toString();
  }
}

/// Extention adding text representation in stamp view of [DateTime].
extension DateTimeToStamp on DateTime {
  /// Returns this [DateTime] formatted as a stamp.
  String get toStamp {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(4, '0')}';
  }
}
