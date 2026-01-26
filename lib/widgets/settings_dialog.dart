import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/localization_service.dart';
import '../services/auth_service.dart';
import '../core/constants/colors.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: AppColors.lightPrimary),
                ),
                const SizedBox(width: 16),
                Text(
                  loc.translate('settings'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 32),

            // Language Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.translate('language'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption(
                    context,
                    loc,
                    code: 'en',
                    flag: '🇺🇸',
                    label: 'English',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption(
                    context,
                    loc,
                    code: 'vi',
                    flag: '🇻🇳',
                    label: 'Tiếng Việt',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Diagnostic Section
            OutlinedButton.icon(
              onPressed: () => _runConnectionTest(context),
              icon: const Icon(Icons.speed_rounded, size: 18),
              label: const Text('Test Network & Storage'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: const BorderSide(color: AppColors.info),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Version Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Version 1.2.0 (Premium Pet Update)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(target: 1)
          .scale(duration: 400.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LocalizationService loc, {
    required String code,
    required String flag,
    required String label,
  }) {
    final isSelected = loc.locale.languageCode == code;
    return GestureDetector(
      onTap: () => loc.changeLanguage(Locale(code)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.lightPrimary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runConnectionTest(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final logs = StringBuffer();
    logs.writeln('=== DIAGNOSTIC REPORT ===');
    logs.writeln('Time: ${DateTime.now()}');

    try {
      // 1. Check Auth
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      logs.writeln('\n[AUTH]');
      if (user != null) {
        logs.writeln('✅ User ID: ${user.uid}');
        logs.writeln('✅ Email: ${user.email}');
      } else {
        logs.writeln('❌ No user logged in');
      }

      // 2. Check Storage (Cloudinary)
      logs.writeln('\n[STORAGE - Cloudinary]');
      logs.writeln('Checking connection to api.cloudinary.com...');

      try {
        final response = await http
            .get(Uri.parse('https://api.cloudinary.com/'))
            .timeout(const Duration(seconds: 10));
        logs.writeln('✅ Connection Success! (Status: ${response.statusCode})');

        logs.writeln(
            '\nNote: To test a real upload, try creating a task with an image.');
      } catch (e) {
        logs.writeln('❌ Connection FAILED: $e');
      }
    } catch (e) {
      logs.writeln('\n❌ CRITICAL ERROR: $e');
    }

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diagnostic Result'),
          content: SingleChildScrollView(
            child: SelectableText(logs.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
