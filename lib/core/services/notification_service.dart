// lib/core/services/notification_service.dart
//
// Thin wrapper around flutter_local_notifications.
// Handles permission requests and shows in-app notifications.
// Call NotificationService.init() once in main() before runApp().

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelNewOrder = AndroidNotificationDetails(
    'barq_new_order',
    'New Orders',
    channelDescription: 'Alerts when a new delivery is assigned to you.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // ── Initialise once at app start ─────────────────────────────────────────
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  // ── New order assigned to this driver ───────────────────────────────────
  static Future<void> showNewOrder(String storeName) async {
    await _plugin.show(
      1001,
      'New Delivery',
      'Pickup order from $storeName',
      const NotificationDetails(android: _channelNewOrder, iOS: _iosDetails),
    );
  }
}
