// lib/core/services/notification_service.dart
//
// Wraps firebase_messaging + flutter_local_notifications for the driver app.
// Handles foreground & background push notifications for new deliveries,
// order-ready alerts, etc.
//
// Call NotificationService.init() once in main() before runApp().
// Call NotificationService.initFCM() after the user signs in to save the token.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level background message handler — must be top-level, not a closure.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._plugin.show(
    message.hashCode,
    message.notification?.title ?? 'Barq Driver',
    message.notification?.body ?? '',
    const NotificationDetails(
      android: NotificationService.channelNewOrder,
      iOS: NotificationService.iosDetails,
    ),
  );
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const channelNewOrder = AndroidNotificationDetails(
    'barq_new_order',
    'New Orders',
    channelDescription: 'Alerts when a new delivery is assigned to you.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  /// Set this to the GoRouter instance so notification taps can navigate.
  static GoRouter? router;

  // ── Initialise local notifications once at app start ────────────────────
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // iOS — show notification banners even when app is in foreground.
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Firebase may not be initialized yet — safe to skip.
    }
  }

  // ── Call after user is authenticated to register FCM token ──────────────
  static Future<void> initFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token == null) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);

      // Listen for token refresh.
      messaging.onTokenRefresh.listen((newToken) async {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid == null) return;
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': newToken}).eq('id', uid);
      });

      // Foreground messages → show local notification.
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        _plugin.show(
          message.hashCode,
          n.title ?? 'Barq Driver',
          n.body ?? '',
          const NotificationDetails(
              android: channelNewOrder, iOS: iosDetails),
          payload: message.data['route'] as String?,
        );
      });

      // Notification tap when app is in background (not killed).
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Notification tap when app was killed (cold start).
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleMessageTap(initial);

      debugPrint('[FCM] Driver FCM initialized, token saved');
    } catch (e) {
      debugPrint('[FCM] initFCM error: $e');
    }
  }

  // ── Handle taps on local notifications ──────────────────────────────────
  static void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty && router != null) {
      router!.go(route);
    } else {
      router?.go('/home');
    }
  }

  // ── Handle taps on FCM notifications (background/killed) ───────────────
  static void _handleMessageTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty && router != null) {
      router!.go(route);
    } else {
      router?.go('/home');
    }
  }

  // ── Show a local notification for new delivery assignment ───────────────
  static Future<void> showNewOrder(String storeName) async {
    await _plugin.show(
      1001,
      'New Delivery',
      'Pickup order from $storeName',
      const NotificationDetails(android: channelNewOrder, iOS: iosDetails),
    );
  }
}
