import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationModel with ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationModel() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessage(message);
    });

    _firebaseMessaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);
  }

  void handleMessage(RemoteMessage message) {
    showNotification(message);
    notifyListeners();
  }

  Future<void> showNotification(RemoteMessage message) async {
    var androidPlatformChannelSpecifics = const  AndroidNotificationDetails(
        'channel_ID', 'channel_name', 
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, message.notification?.title, message.notification?.body, platformChannelSpecifics,
        payload: 'item_id ${message.hashCode}');
  }
}
