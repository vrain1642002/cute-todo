import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/localization_service.dart';
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
                    flagCode: 'us',
                    label: 'English',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption(
                    context,
                    loc,
                    code: 'vi',
                    flagCode: 'vn',
                    label: 'Tiếng Việt',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

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
          .scale(duration: 200.ms, curve: Curves.easeOutQuart)
          .fadeIn(duration: 150.ms),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LocalizationService loc, {
    required String code,
    required String flagCode,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://flagcdn.com/w40/$flagCode.png',
                width: 24,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.flag_rounded, size: 20),
              ),
            ),
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
}
