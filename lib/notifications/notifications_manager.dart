import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Инициализация сервиса уведомлений
  Future<void> init() async {
    
    var initializationSettingsAndroid =
       const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showNotification(notification, android);
      }
    });
  }

  /// Показать уведомление
  Future<void> showNotification(
      RemoteNotification notification, AndroidNotification android) async {
   var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'channel_ID', 'channel_name',
    channelDescription: 'channel_description',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false);

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, notification.title, notification.body, platformChannelSpecifics,
        payload: 'item_id ${notification.hashCode}');
  }
}