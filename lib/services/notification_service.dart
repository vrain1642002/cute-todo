import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';
import 'email_service.dart';

// Conditional import for web notifications
import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_helper.dart';

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
  String? _currentUserEmail;
  String? _currentUserName;
  final Map<String, Timer> _webTimers = {}; // Fallback for Web scheduling
  String _languageCode = 'vi'; // Default to Vietnamese
  final EmailService _emailService = EmailService();

  /// Initialize notification service
  Future<void> init() async {
    if (!kIsWeb) {
      // Initialize time zones (Mobile only)
      tz.initializeTimeZones();
    }

    // Request permission (Non-blocking)
    _messaging
        .requestPermission(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((settings) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    });

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

    // Request web notification permission (Non-blocking)
    if (kIsWeb) {
      requestWebNotificationPermission();
    }

    // Load saved language preference
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('language_code') ?? 'vi';

    debugPrint('Notification service initialized (lang: $_languageCode)');
  }

  /// Update notification language
  void setLanguage(String languageCode) {
    _languageCode = languageCode;
    debugPrint('Notification language set to: $languageCode');
  }

  /// Set user info for email notifications
  void setUserInfo({required String? email, required String? displayName}) {
    _currentUserEmail = email;
    _currentUserName = displayName;
    debugPrint('Notification user set: $email');
  }

  /// Schedule a local notification 10 minutes before deadline
  Future<void> scheduleDeadlineNotification(TodoModel todo) async {
    if (todo.dueDate == null) return;

    final now = DateTime.now();
    final scheduledDate = todo.dueDate!.subtract(const Duration(minutes: 3));

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
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      final threeMinutesLater = now.add(const Duration(minutes: 3));

      final querySnapshot = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'todo')
          // Catch tasks due between 5 mins ago and 3 mins from now
          .where('dueDate', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .where('dueDate',
              isLessThanOrEqualTo: Timestamp.fromDate(threeMinutesLater))
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
    final minutesLeft = todo.dueDate!.difference(DateTime.now()).inMinutes;

    // Language-aware notification messages
    final bool isVietnamese = _languageCode == 'vi';
    final title =
        isVietnamese ? '⏰ Deadline sắp đến!' : '⏰ Deadline approaching!';
    final body = isVietnamese
        ? '${todo.title} - còn $minutesLeft phút'
        : '${todo.title} - $minutesLeft minutes left';

    if (kIsWeb) {
      // Use browser Notification API on web
      await showWebNotification(title, body);
      debugPrint('Web notification shown for: ${todo.title}');
    }

    // Send email notification if configured
    if (_emailService.isConfigured && _currentUserEmail != null) {
      await _emailService.sendDeadlineReminder(
        toEmail: _currentUserEmail!,
        userName: _currentUserName ?? '',
        taskTitle: todo.title,
        minutesLeft: minutesLeft,
        dueTime: _formatTime(todo.dueDate!),
        languageCode: _languageCode,
      );
    }

    if (kIsWeb) return;

    // Mobile: use flutter_local_notifications
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

    await _localNotifications.show(
      todo.id.hashCode,
      title,
      body,
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
