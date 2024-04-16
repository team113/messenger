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
