// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Show a browser notification (Web only)
Future<void> showWebNotification(String title, String body) async {
  try {
    // Request permission if not granted
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }

    if (html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        icon: '/icons/Icon-192.png',
        tag: 'cute_todo_deadline',
      );
    }
  } catch (e) {
    debugPrint('Error showing web notification: $e');
  }
}

/// Request notification permission (call on app init)
Future<void> requestWebNotificationPermission() async {
  try {
    if (html.Notification.permission == 'default') {
      await html.Notification.requestPermission();
    }
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
  }
}
