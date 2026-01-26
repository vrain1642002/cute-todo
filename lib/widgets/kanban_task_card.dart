import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';

class KanbanTaskCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final bool isDragging;

  const KanbanTaskCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onLongPress,
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
          onLongPress: onLongPress,
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

                // Creation & Completion Dates
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.lightTextSecondary
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MM/dd').format(todo.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            AppColors.lightTextSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                    if (todo.completedAt != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle_outline_rounded,
                          size: 12,
                          color: AppColors.success.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MM/dd').format(todo.completedAt!),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom row with due date, category and energy
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (todo.dueDate != null) _buildDueDateChip(),

                    if (todo.imageUrls.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_rounded,
                                size: 14, color: AppColors.lightPrimary),
                            const SizedBox(width: 4),
                            Text(
                              '${todo.imageUrls.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (todo.category != TaskCategory.other)
                      _buildCategoryChip(),
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

  ({String emoji, String label, Color color}) _getCategoryInfo(
      TaskCategory category) {
    switch (category) {
      case TaskCategory.study:
        return (emoji: '📚', label: 'Study', color: Colors.blue);
      case TaskCategory.draw:
        return (emoji: '🎨', label: 'Draw', color: Colors.purple);
      case TaskCategory.code:
        return (emoji: '💻', label: 'Code', color: Colors.blueGrey);
      case TaskCategory.game:
        return (emoji: '🎮', label: 'Game', color: Colors.redAccent);
      case TaskCategory.other:
        return (emoji: '📦', label: 'Other', color: Colors.grey);
    }
  }
}
