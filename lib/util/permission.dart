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
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for requesting permissions.
class PermissionUtil {
  /// Mutex for synchronized access to permissions requesting.
  ///
  /// Ensures that only one permission is requested at the same time.
  static final Mutex _permissionMutex = Mutex();

  /// Requests the notifications permission.
  static Future<NotificationSettings> notifications() {
    return _permissionMutex.protect(() {
      return FirebaseMessaging.instance.requestPermission();
    });
  }

  /// Requests the contacts permission.
  static Future<PermissionStatus> contacts() {
    return _permissionMutex.protect(() async {
      return Permission.contacts.request();
    });
  }
}
