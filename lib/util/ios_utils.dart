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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

/// Helper providing direct access to iOS-only features.
class IosUtils {
  /// [MethodChannel] to communicate with iOS via.
  static const _platform = MethodChannel('team113.flutter.dev/ios_utils');

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
    return await _platform
        .invokeMethod('cancelNotificationsContaining', {'thread': thread});
  }

  /// Registers the provided [handler] to handle [RemoteMessage]s received in
  /// background or terminated state.
  static void registerBackgroundHandler(
    Future<void> Function(RemoteMessage) handler,
  ) {
    _platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'handleMessageBackground') {
        final RemoteMessage message = RemoteMessage(
          notification: call.arguments['aps']?['alert'] == null
              ? null
              : RemoteNotification(
                  title: call.arguments['aps']?['alert']?['title'],
                  body: call.arguments['aps']?['alert']?['body'],
                ),
          data: Map<String, dynamic>.from(call.arguments),
        );

        await handler(message);
      }
    });
  }
}
