// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:log_me/log_me.dart' as me;
import 'package:sentry_flutter/sentry_flutter.dart';

import '/config.dart';
import 'new_type.dart';

/// Utility logging messages to console.
class Log {
  /// Prints the fatal [message] with [tag] to the [me.Log].
  static void fatal(String message, [String? tag]) {
    me.Log.fatal('${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.fatal);
  }

  /// Prints the error [message] with [tag] to the [me.Log].
  static void error(String message, [String? tag]) {
    me.Log.error('${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.error);
  }

  /// Prints the warning [message] with [tag] to the [me.Log].
  static void warning(String message, [String? tag]) {
    me.Log.warning('${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.warning);
  }

  /// Prints the information [message] with [tag] to the [me.Log].
  static void info(String message, [String? tag]) {
    me.Log.info('${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.info);
  }

  /// Prints the debug [message] with [tag] to the [me.Log].
  static void debug(String message, [String? tag]) {
    me.Log.debug('${tag != null ? '[$tag]' : ''} $message');
    _breadcrumb(message, tag, SentryLevel.debug);
  }

  /// Prints the trace [message] with [tag] to the [me.Log].
  static void trace(String message, [String? tag]) {
    me.Log.trace(message, tag);
    _breadcrumb(message, tag, SentryLevel.debug);
  }

  /// Reports a [Breadcrumb] with the provided details to the [Sentry], if
  /// enabled.
  static Future<void> _breadcrumb(
    String message,
    String? tag,
    SentryLevel level,
  ) async {
    if (!kDebugMode && Config.sentryDsn.isNotEmpty) {
      try {
        await Sentry.addBreadcrumb(
          Breadcrumb.console(
            message: '[$tag] $message',
            level: SentryLevel.debug,
          ),
        );
      } catch (_) {
        // No-op.
      }
    }
  }
}

/// Extension adding obscured getter to [NewType]s.
extension ObscuredNewTypeExtension on NewType {
  /// Returns this value as a obscured string.
  ///
  /// Intended to be used to obscure sensitive information in [Log]s:
  /// ```dart
  /// // - prints `[Type] signIn(password: ***)`, when non-`null`;
  /// // - prints `[Type] signIn(password: null)`, when `null`;
  /// Log.debug('signIn(password: ${password?.obscured})', '$runtimeType');
  /// ```
  String get obscured => '***';
}
