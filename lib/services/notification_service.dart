import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Conditional import for web notifications
import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_helper.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

/// Minimal notification service - only handles FCM and local display.
/// All email & deadline logic is handled by the backend.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize notification service
  Future<void> init() async {
    // Request permission
    _messaging
        .requestPermission(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((settings) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    });

    // Initialize local notifications (for displaying incoming FCM on mobile)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages - display as local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Request web notification permission
    if (kIsWeb) {
      requestWebNotificationPermission();
    }

    debugPrint(
        'NotificationService initialized (FCM only, backend handles email)');
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      if (kIsWeb) {
        showWebNotification(
          message.notification!.title ?? 'CuteTodo',
          message.notification!.body ?? '',
        );
      } else {
        _localNotifications.show(
          message.hashCode,
          message.notification!.title ?? 'CuteTodo',
          message.notification!.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'Push Notifications',
              importance: Importance.high,
            ),
          ),
        );
      }
    }
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user document
  Future<void> saveTokenToUser(String userId) async {
    final token = await getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved for user: $userId');
    }
  }
}
