import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../core/constants/colors.dart';

class VoiceListeningDialog extends StatefulWidget {
  const VoiceListeningDialog({super.key});

  @override
  State<VoiceListeningDialog> createState() => _VoiceListeningDialogState();
}

class _VoiceListeningDialogState extends State<VoiceListeningDialog> {
  String _text = 'Say something...';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  Future<void> _startListening() async {
    final voiceService = context.read<VoiceService>();
    await voiceService.startListening(onResult: (text) {
      if (mounted) {
        setState(() => _text = text);
      }
    });
  }

  Future<void> _finish() async {
    if (_isProcessing) return;

    final voiceService = context.read<VoiceService>();
    voiceService.stopListening();

    if (_text == 'Say something...') {
      Navigator.of(context).pop(null);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Use AI service for intelligent parsing
      final aiService = context.read<AiService>();
      final draft = await aiService.parseTaskFromText(_text);

      if (mounted) {
        Navigator.of(context).pop(draft);
      }
    } catch (e) {
      // Fallback to simple parsing if AI fails
      debugPrint('AI parsing failed: $e, using fallback');
      final draft = voiceService.parseTask(_text);
      if (mounted) {
        Navigator.of(context).pop(draft);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch voice service to rebuild on state changes
    final voiceService = context.watch<VoiceService>();
    final isListening = voiceService.isListening;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Icon(
            isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            size: 48,
            color: isListening ? AppColors.lightPrimary : Colors.grey,
          )
              .animate(target: isListening ? 1 : 0)
              .scale(
                duration: 400.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
              )
              .then()
              .scale(
                duration: 400.ms,
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 20),
          Text(
            isListening ? 'Listening...' : 'Finished',
            style: TextStyle(
              color: isListening ? AppColors.lightPrimary : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          if (isListening)
            ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightPrimary,
                shape: const StadiumBorder(),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _finish, // Use _finish here too to parse
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Create Task',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
