// --- lib/notification_service.dart (NEW FILE) ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Initialize Notifications
  static Future<void> initialize() async {
    // Android Settings
    // Use the default app icon '@mipmap/ic_launcher'
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
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

    // Initialize the plugin
    await _notificationsPlugin.initialize(initSettings);
  }

  // 2. Request Permissions (Android 13+)
  static Future<void> requestPermissions() async {
    // This will ask the user for permission
    await Permission.notification.request();
  }

  // 3. Show a simple Notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Define Android channel details
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

    // Show the notification
    await _notificationsPlugin.show(id, title, body, platformDetails);
  }
}