// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

// ignore_for_file: avoid_print

import 'dart:developer' as developer;
import 'dart:core' as core;

import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

// TODO: That's a temporary solution, we should use a proper logger.
class Log {
  /// Prints the provided [message] into the console.
  static void print(core.String message, [core.String? tag]) =>
      PlatformUtils.isWeb
          ? core.print('[$tag]: $message')
          : developer.log(message, name: tag ?? '');

  /// Prints the provided [object] into the console as an error.
  static void error(core.Object? object) =>
      PlatformUtils.isWeb ? WebUtils.consoleError(object) : core.print(object);
}
