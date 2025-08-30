import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initializationSettings);
  }

  Future<void> showSimple(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(0, title, body, notificationDetails);
  }
}












