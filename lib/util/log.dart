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

/// Class for performing logging at different levels.
class Log {
  /// Write a fatal [message] with [tag] to the log.
  static void fatal(String message, [String? tag]) {
    me.Log.fatal('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Write an error [message] with [tag] to the log.
  static void error(String message, [String? tag]) {
    me.Log.error('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Write a warning [message] with [tag] to the log.
  static void warning(String message, [String? tag]) {
    me.Log.warning('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Write an information [message] with [tag] to the log.
  static void info(String message, [String? tag]) {
    me.Log.info('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Write a debug [message] with [tag] to the log.
  static void debug(String message, [String? tag]) {
    me.Log.debug('${tag != null ? '[$tag]' : ''} $message');
  }

  /// Write a trace [message] with [tag] to the log.
  static void trace(String message, [String? tag]) {
    me.Log.trace('${tag != null ? '[$tag]' : ''} $message');
  }
}
