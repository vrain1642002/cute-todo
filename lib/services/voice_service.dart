import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

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
        onError: (val) => print('Voice Error: $val'),
        onStatus: (val) {
          print('Voice Status: $val');
          notifyListeners();
        },
      );
      notifyListeners();
      return _isEnabled;
    } catch (e) {
      print('Voice Init Error: $e');
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
}
