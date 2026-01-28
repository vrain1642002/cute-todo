import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for sending emails via EmailJS
class EmailService {
  // Credentials from user
  static const String _serviceId = 'service_lx2vsyo';
  static const String _templateId = 'template_x7tbqfs';
  static const String _publicKey = 'VrD4W6V_afAXyBvag';

  static const String _emailJsUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  /// Send deadline reminder email
  Future<bool> sendDeadlineReminder({
    required String toEmail,
    required String userName,
    required String taskTitle,
    required int minutesLeft,
    required String dueTime,
    required String languageCode,
  }) async {
    try {
      // Language-aware email content
      final bool isVietnamese = languageCode == 'vi';

      final templateParams = {
        'to_email': toEmail,
        'user_name': userName.isNotEmpty ? userName : 'User',
        'task_title': taskTitle,
        'minutes_left': minutesLeft.toString(),
        'due_time': dueTime,
        'subject': isVietnamese
            ? '⏰ Nhắc nhở Deadline - $taskTitle'
            : '⏰ Task Deadline Reminder - $taskTitle',
        'greeting': isVietnamese ? 'Xin chào' : 'Hi',
        'message': isVietnamese
            ? 'Vui lòng bắt đầu công việc "$taskTitle" '
            : 'Please start working on "$taskTitle"',
        'footer': isVietnamese
            ? 'Đừng quên hoàn thành đúng hạn! 🎯'
            : "Don't forget to complete it on time! 🎯",
      };

      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': kIsWeb ? Uri.base.origin : 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email sent successfully to: $toEmail');
        return true;
      } else {
        debugPrint('❌ Email failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email error: $e');
      return false;
    }
  }

  /// Check if EmailJS is configured
  bool get isConfigured =>
      _serviceId != 'YOUR_SERVICE_ID' &&
      _templateId != 'YOUR_TEMPLATE_ID' &&
      _publicKey != 'YOUR_PUBLIC_KEY';
}
