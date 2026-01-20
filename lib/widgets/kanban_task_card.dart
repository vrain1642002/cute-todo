import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';

class KanbanTaskCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDragging;

  const KanbanTaskCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onDelete,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDragging
            ? AppColors.lightPrimary.withValues(alpha: 0.1)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDragging ? AppColors.lightPrimary : AppColors.cardBorder,
          width: isDragging ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? AppColors.lightPrimary.withValues(alpha: 0.3)
                : AppColors.cardShadow,
            blurRadius: isDragging ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority indicator and delete button row
                Row(
                  children: [
                    _buildPriorityBadge(),
                    const Spacer(),
                    _buildXPBadge(),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.close_rounded),
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppColors.lightTextSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: todo.status == TodoStatus.completed
                        ? AppColors.lightTextSecondary
                        : AppColors.lightText,
                    decoration: todo.status == TodoStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    todo.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Bottom row with due date, category and energy
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (todo.dueDate != null) _buildDueDateChip(),
                    if (todo.category != TaskCategory.general)
                      _buildCategoryChip(),
                    if (todo.energyLevel != EnergyLevel.any) _buildEnergyChip(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    Color color;
    String emoji;
    String label;

    switch (todo.priority) {
      case TodoPriority.high:
        color = AppColors.priorityHigh;
        emoji = '🔥';
        label = 'High';
        break;
      case TodoPriority.medium:
        color = AppColors.priorityMedium;
        emoji = '⚡';
        label = 'Medium';
        break;
      case TodoPriority.low:
        color = AppColors.priorityLow;
        emoji = '🌱';
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '+${todo.xpReward}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip() {
    final isOverdue = todo.isOverdue;
    final color = isOverdue ? AppColors.error : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue
                ? Icons.warning_amber_rounded
                : Icons.calendar_today_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d').format(todo.dueDate!),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip() {
    final categoryInfo = _getCategoryInfo(todo.category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(categoryInfo.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            categoryInfo.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: categoryInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyChip() {
    final energyInfo = _getEnergyInfo(todo.energyLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: energyInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: energyInfo.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(energyInfo.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            energyInfo.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: energyInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  ({String emoji, String label, Color color}) _getCategoryInfo(
      TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return (emoji: '📚', label: 'Study', color: Colors.blue);
      case TaskCategory.exercise:
        return (emoji: '💪', label: 'Exercise', color: Colors.orange);
      case TaskCategory.housework:
        return (emoji: '🧹', label: 'Housework', color: Colors.green);
      case TaskCategory.creative:
        return (emoji: '🎨', label: 'Creative', color: Colors.purple);
      case TaskCategory.social:
        return (emoji: '💬', label: 'Social', color: Colors.pink);
      case TaskCategory.work:
        return (emoji: '💼', label: 'Work', color: Colors.indigo);
      case TaskCategory.selfCare:
        return (emoji: '💆', label: 'Self Care', color: Colors.teal);
      case TaskCategory.general:
        return (emoji: '📁', label: 'General', color: AppColors.lightAccent);
    }
  }

  ({String emoji, String label, Color color}) _getEnergyInfo(
      EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.lowEnergy:
        return (emoji: '😴', label: 'Low Energy', color: Colors.blueGrey);
      case EnergyLevel.highFocus:
        return (emoji: '🎯', label: 'Focus', color: Colors.red);
      case EnergyLevel.creative:
        return (emoji: '🌟', label: 'Creative', color: Colors.amber);
      case EnergyLevel.any:
        return (emoji: '✨', label: 'Any', color: Colors.grey);
    }
  }
}
