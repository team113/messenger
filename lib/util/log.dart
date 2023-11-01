// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:log_me/log_me.dart' as me;

/// A class for performing logging at different levels.
class Log {
  /// Writes a fatal message to the log.
  ///
  /// [message] - the text of the fatal message.
  /// [tag] - (optional) a tag for additional message identification.
  static void fatal(String message, [String? tag]) {
    me.Log.fatal('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Writes an error message to the log.
  ///
  /// [message] - the text of the error message.
  /// [tag] - (optional) a tag for additional message identification.
  static void error(String message, [String? tag]) {
    me.Log.error('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Writes a warning message to the log.
  ///
  /// [message] - the text of the warning message.
  /// [tag] - (optional) a tag for additional message identification.
  static void warning(String message, [String? tag]) {
    me.Log.warning('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Writes an information message to the log.
  ///
  /// [message] - the text of the information message.
  /// [tag] - (optional) a tag for additional message identification.
  static void info(String message, [String? tag]) {
    me.Log.info('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Writes a debug message to the log.
  ///
  /// [message] - the text of the debug message.
  /// [tag] - (optional) a tag for additional message identification.
  static void debug(String message, [String? tag]) {
    me.Log.debug('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Writes a trace message to the log.
  ///
  /// [message] - the text of the trace message.
  /// [tag] - (optional) a tag for additional message identification.
  static void trace(String message, [String? tag]) {
    me.Log.trace('${tag != null ? '[$tag]' : ''} $message');
  }
}
