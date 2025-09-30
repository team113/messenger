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

import 'package:flutter/services.dart';

/// Helper providing direct access to iOS-only features.
class IosUtils {
  /// [MethodChannel] to communicate with iOS via.
  static const _platform = MethodChannel('tapopa.flutter.dev/ios_utils');

  /// Returns the architecture of this device.
  static Future<String> getArchitecture() async {
    return await _platform.invokeMethod('getArchitecture');
  }

  /// Removes the delivered notification with the provided [tag].
  static Future<bool> cancelNotification(String tag) async {
    return await _platform.invokeMethod('cancelNotification', {'tag': tag});
  }

  /// Removes the delivered notifications containing the provided [thread].
  static Future<bool> cancelNotificationsContaining(String thread) async {
    return await _platform.invokeMethod('cancelNotificationsContaining', {
      'thread': thread,
    });
  }

  /// Returns the directory that is shared among both application and its
  /// services (Notification Service Extension, for example).
  static Future<String> getSharedDirectory() async {
    final String url = await _platform.invokeMethod('getSharedDirectory');
    return url.replaceFirst('file://', '');
  }

  /// Writes the provided [value] at the [key] in the shared dictionaries.
  static Future<void> writeDefaults(String key, String value) async {
    await _platform.invokeMethod('writeDefaults', {'key': key, 'value': value});
  }
}
