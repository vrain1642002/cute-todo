import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class BackendService {
  static const String _baseUrl = 'https://cute-todo-backend.vercel.app/api';

  static Future<void> sendTaskNotification({
    String? fcmToken,
    String? email,
    required String title,
    required String body,
    String? userName,
    String? taskTitle,
    String? dueTime,
    int? minutesLeft,
    String languageCode = 'vi',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/send-notification');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': fcmToken,
              'email': email,
              'title': title,
              'body': body,
              'userName': userName,
              'taskTitle': taskTitle,
              'dueTime': dueTime,
              'minutesLeft': minutesLeft,
              'languageCode': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('Backend notification sent successfully');
      } else {
        debugPrint('Backend notification failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling backend: $e');
    }
  }
}
