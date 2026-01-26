import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import 'voice_service.dart';

/// Service for AI-powered task parsing using Firebase AI
class AiService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Initialize the Firebase AI model
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Use Gemini Developer API (free on Spark plan)
      // Note: vertexAI() requires paid Blaze plan
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
      );
      _isInitialized = true;
      debugPrint('AI Service initialized');
    } catch (e) {
      debugPrint('Failed to initialize AI Service: $e');
    }
  }

  /// Parse voice/text input into a structured task
  Future<TaskDraft> parseTaskFromText(String text) async {
    if (_model == null) {
      await init();
    }

    if (_model == null) {
      // Fallback to simple parsing if AI not available
      return _simpleParseTask(text);
    }

    try {
      final prompt = '''
Analyze the following text and extract task information. Return a JSON object with these fields:
- title: A clean, concise task title (required)
- priority: "low", "medium", or "high" based on urgency keywords
- category: one of "other", "study", "code", "draw", "game"
- dueDate: date in ISO format if mentioned (e.g., "2025-01-27T14:00:00"), or null

Text: "$text"

Return ONLY valid JSON, no markdown or explanation.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      return _parseAiResponse(responseText, text);
    } catch (e) {
      debugPrint('AI parsing error: $e');
      return _simpleParseTask(text);
    }
  }

  /// Parse AI response JSON into TaskDraft
  TaskDraft _parseAiResponse(String jsonText, String originalText) {
    try {
      // Clean up response - remove markdown code blocks if present
      String cleaned = jsonText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      // Extract values using regex

      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      final priorityMatch =
          RegExp(r'"priority"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      final categoryMatch =
          RegExp(r'"category"\s*:\s*"([^"]*)"').firstMatch(cleaned);
      final dueDateMatch =
          RegExp(r'"dueDate"\s*:\s*"([^"]*)"').firstMatch(cleaned);

      String title = titleMatch?.group(1) ?? originalText;

      TodoPriority priority = TodoPriority.medium;
      if (priorityMatch != null) {
        final p = priorityMatch.group(1)?.toLowerCase();
        if (p == 'high') {
          priority = TodoPriority.high;
        } else if (p == 'low') {
          priority = TodoPriority.low;
        }
      }

      TaskCategory category = TaskCategory.other;
      if (categoryMatch != null) {
        final c = categoryMatch.group(1);
        category = TaskCategory.values.firstWhere(
          (e) => e.name == c,
          orElse: () => TaskCategory.other,
        );
      }

      DateTime? dueDate;
      if (dueDateMatch != null && dueDateMatch.group(1) != 'null') {
        try {
          dueDate = DateTime.parse(dueDateMatch.group(1)!);
        } catch (_) {}
      }

      return TaskDraft(
        title: title,
        priority: priority,
        category: category,
        dueDate: dueDate,
      );
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return _simpleParseTask(originalText);
    }
  }

  /// Simple fallback parsing without AI
  TaskDraft _simpleParseTask(String text) {
    String lower = text.toLowerCase();

    TodoPriority priority = TodoPriority.medium;
    DateTime? dueDate;
    TaskCategory category = TaskCategory.other;

    // Priority detection
    if (lower.contains('urgent') ||
        lower.contains('important') ||
        lower.contains('high priority') ||
        lower.contains('khẩn cấp') ||
        lower.contains('quan trọng') ||
        lower.contains('gấp')) {
      priority = TodoPriority.high;
    } else if (lower.contains('low priority') ||
        lower.contains('thấp') ||
        lower.contains('không gấp')) {
      priority = TodoPriority.low;
    }

    // Category detection
    if (lower.contains('học') ||
        lower.contains('study') ||
        lower.contains('bài')) {
      category = TaskCategory.study;
    } else if (lower.contains('vẽ') ||
        lower.contains('draw') ||
        lower.contains('design')) {
      category = TaskCategory.draw;
    } else if (lower.contains('code') ||
        lower.contains('lập trình') ||
        lower.contains('dev')) {
      category = TaskCategory.code;
    } else if (lower.contains('game') ||
        lower.contains('chơi') ||
        lower.contains('play')) {
      category = TaskCategory.game;
    }

    // Date detection
    final now = DateTime.now();
    if (lower.contains('today') || lower.contains('hôm nay')) {
      dueDate = now;
    } else if (lower.contains('tomorrow') || lower.contains('ngày mai')) {
      dueDate = now.add(const Duration(days: 1));
    } else if (lower.contains('next week') || lower.contains('tuần sau')) {
      dueDate = now.add(const Duration(days: 7));
    }

    return TaskDraft(
      title: text,
      priority: priority,
      category: category,
      dueDate: dueDate,
    );
  }
}
