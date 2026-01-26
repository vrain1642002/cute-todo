import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_model.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

/// Service for handling push notifications and deadline reminders
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _deadlineCheckTimer;
  String? _currentUserId;
  final Map<String, Timer> _webTimers = {}; // Fallback for Web scheduling

  /// Initialize notification service
  Future<void> init() async {
    if (!kIsWeb) {
      // Initialize time zones (Mobile only)
      tz.initializeTimeZones();
    }

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // Initialize local notifications
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

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    debugPrint('Notification service initialized');
  }

  /// Schedule a local notification 10 minutes before deadline
  Future<void> scheduleDeadlineNotification(TodoModel todo) async {
    if (todo.dueDate == null) return;

    final now = DateTime.now();
    final scheduledDate = todo.dueDate!.subtract(const Duration(minutes: 10));

    // If scheduled time is in the past, don't schedule
    if (scheduledDate.isBefore(now)) return;

    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'deadline_channel',
      'Deadline Reminders',
      channelDescription: 'Notifications for upcoming task deadlines',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (kIsWeb) {
      // Web Fallback: Use Timer (Requires tab to be open)
      _webTimers[todo.id]?.cancel();
      final duration = scheduledDate.difference(now);
      _webTimers[todo.id] = Timer(duration, () {
        _showDeadlineNotification(todo);
        _webTimers.remove(todo.id);
      });
      debugPrint('Scheduled Web Timer for task: ${todo.title} in $duration');
    } else {
      // Mobile: Use OS Scheduling (Works offline)
      try {
        await _localNotifications.zonedSchedule(
          todo.id.hashCode, // Use hash code as notification ID
          '⏰ Deadline sắp đến!',
          '${todo.title} - hạn chót lúc ${_formatTime(todo.dueDate!)}',
          tz.TZDateTime.from(scheduledDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint(
            'Scheduled local notification for task: ${todo.title} at $scheduledDate');
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String taskId) async {
    if (kIsWeb) {
      _webTimers[taskId]?.cancel();
      _webTimers.remove(taskId);
      debugPrint('Cancelled Web Timer for task: $taskId');
    } else {
      try {
        await _localNotifications.cancel(taskId.hashCode);
        debugPrint('Cancelled notification for task: $taskId');
      } catch (e) {
        debugPrint('Error cancelling notification: $e');
      }
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Start checking for upcoming deadlines (Keep existing method for foreground backup)
  void startDeadlineMonitoring(String userId) {
    _currentUserId = userId;

    // Check every minute for upcoming deadlines
    _deadlineCheckTimer?.cancel();
    _deadlineCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkUpcomingDeadlines(),
    );

    // Initial check
    _checkUpcomingDeadlines();
  }

  /// Check for tasks with deadlines in next 10 minutes
  Future<void> _checkUpcomingDeadlines() async {
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now();
      final tenMinutesLater = now.add(const Duration(minutes: 10));

      final querySnapshot = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'todo')
          .where('dueDate', isGreaterThan: Timestamp.fromDate(now))
          .where('dueDate',
              isLessThanOrEqualTo: Timestamp.fromDate(tenMinutesLater))
          .get();

      for (final doc in querySnapshot.docs) {
        final todo = TodoModel.fromFirestore(doc);

        final alreadyNotified = doc.data()['notificationSent'] ?? false;
        if (alreadyNotified) continue;

        await _showDeadlineNotification(todo);

        await doc.reference.update({'notificationSent': true});

        debugPrint('Notification sent for task: ${todo.title}');
      }
    } catch (e) {
      debugPrint('Error checking deadlines: $e');
    }
  }

  /// Show local notification for upcoming deadline (Foreground)
  Future<void> _showDeadlineNotification(TodoModel todo) async {
    const androidDetails = AndroidNotificationDetails(
      'deadline_channel',
      'Deadline Reminders',
      channelDescription: 'Notifications for upcoming task deadlines',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final minutesLeft = todo.dueDate!.difference(DateTime.now()).inMinutes;

    await _localNotifications.show(
      todo.id.hashCode,
      '⏰ Deadline sắp đến!',
      '${todo.title} - còn $minutesLeft phút',
      details,
    );
  }

  /// Handle foreground messages from FCM
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    // Show local notification for FCM message
    if (message.notification != null) {
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
