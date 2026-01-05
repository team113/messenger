// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

/// Helper providing direct access to Android-only features.
class AndroidUtils {
  /// [MethodChannel] to communicate with Android via.
  static const platform = MethodChannel('tapopa.flutter.dev/android_utils');

  /// Indicates whether this device has a permission to draw overlays.
  static Future<bool> canDrawOverlays() async {
    return await platform.invokeMethod('canDrawOverlays');
  }

  /// Opens overlay settings of this device.
  static Future<void> openOverlaySettings() async {
    await platform.invokeMethod('openOverlaySettings');
  }

  /// Creates a new `NotificationChannel` with the provided parameters.
  static Future<void> createNotificationChannel({
    required String id,
    required String name,
    required String sound,
    String description = '',
  }) async {
    await platform.invokeMethod('createNotificationChannel', {
      'id': id,
      'name': name,
      'sound': sound,
      'description': description,
    });
  }

  /// Removes the delivered notification with the provided [tag].
  static Future<void> cancelNotification(String tag) async {
    await platform.invokeMethod('cancelNotification', {'tag': tag});
  }

  /// Removes the delivered notification with the provided [id].
  static Future<void> cancelNotificationById(String tag, int id) async {
    await platform.invokeMethod('cancelNotificationById', {
      'id': id,
      'tag': tag,
    });
  }

  /// Removes the delivered notifications containing the provided [thread].
  static Future<bool> cancelNotificationsContaining(String thread) async {
    return await platform.invokeMethod('cancelNotificationsContaining', {
      'thread': thread,
    });
  }
}
