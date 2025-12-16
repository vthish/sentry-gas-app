
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();


  static Future<void> initialize() async {


    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');


    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );


    await _notificationsPlugin.initialize(initSettings);
  }


  static Future<void> requestPermissions() async {

    await Permission.notification.request();
  }


  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sentry_gas_channel', // Channel ID
      'Sentry Gas Alerts',  // Channel Name
      channelDescription: 'Notifications for gas leaks and low levels',
      importance: Importance.max, // High importance for alerts
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);


    await _notificationsPlugin.show(id, title, body, platformDetails);
  }
}
