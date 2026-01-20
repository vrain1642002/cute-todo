import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart'; // Already has debugPrint
import '../models/todo_model.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isEnabled = false;
  String _lastWords = '';

  bool get isListening => _speechToText.isListening;
  bool get isEnabled => _isEnabled;
  String get lastWords => _lastWords;

  Future<bool> init() async {
    try {
      _isEnabled = await _speechToText.initialize(
        onError: (val) => debugPrint('Voice Error: $val'),
        onStatus: (val) {
          debugPrint('Voice Status: $val');
          notifyListeners();
        },
      );
      notifyListeners();
      return _isEnabled;
    } catch (e) {
      debugPrint('Voice Init Error: $e');
      return false;
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isEnabled) {
      final initialized = await init();
      if (!initialized) return;
    }

    await _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult(result.recognizedWords);
        notifyListeners();
      },
      localeId: 'vi_VN', // Default to VI but system might override
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    notifyListeners();
  }

  TaskDraft parseTask(String text) {
    String lower = text.toLowerCase();

    // Default values
    TodoPriority priority = TodoPriority.medium;
    DateTime? dueDate;

    // 1. Detect Priority
    if (lower.contains('urgent') ||
        lower.contains('important') ||
        lower.contains('high priority') ||
        lower.contains('khẩn cấp') ||
        lower.contains('quan trọng')) {
      priority = TodoPriority.high;
    } else if (lower.contains('low priority') || lower.contains('thấp')) {
      priority = TodoPriority.low;
    }

    // 2. Detect Date (Simple)
    final now = DateTime.now();
    if (lower.contains('today') || lower.contains('hôm nay')) {
      dueDate = now;
    } else if (lower.contains('tomorrow') || lower.contains('ngày mai')) {
      dueDate = now.add(const Duration(days: 1));
    } else if (lower.contains('next week') || lower.contains('tuần sau')) {
      dueDate = now.add(const Duration(days: 7));
    }

    // 3. Clean Title (Remove keywords is hard without advanced NLP, so keep full text for now or simple replace)
    // For now, return full text as title to avoid over-cleaning
    String title = text;

    return TaskDraft(title: title, priority: priority, dueDate: dueDate);
  }
}

class TaskDraft {
  final String title;
  final TodoPriority priority;
  final DateTime? dueDate;

  TaskDraft({
    required this.title,
    required this.priority,
    this.dueDate,
  });
}
