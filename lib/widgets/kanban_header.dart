import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/theme_service.dart';
import '../core/constants/colors.dart';

class KanbanHeader extends StatelessWidget {
  final UserModel user;
  final ThemePalette palette;
  final VoidCallback onSignOut;
  final VoidCallback onSettingsTap;

  const KanbanHeader({
    super.key,
    required this.user,
    required this.palette,
    required this.onSignOut,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // User Avatar with Level Border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              backgroundColor: palette.primary.withValues(alpha: 0.2),
              child: user.photoURL == null
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: palette.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // User Info & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.displayName.split(' ').first}! 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.stars_rounded,
                      label: 'Level ${user.level}',
                      color: palette.secondary,
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${user.streak} days',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: palette.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings_rounded, color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
