import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';
import 'kanban_task_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final String emoji;
  final TodoStatus status;
  final List<TodoModel> todos;
  final Color headerColor;
  final Color backgroundColor;
  final Color borderColor;
  final Function(TodoModel, TodoStatus, int) onTodoDropped;
  final Function(TodoModel) onTodoTap;
  final Function(TodoModel) onTodoDelete;
  final ScrollController? parentScrollController;
  final Function(double)? onDragUpdate;
  final VoidCallback? onDragEnd;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.emoji,
    required this.status,
    required this.todos,
    required this.headerColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTodoDropped,
    required this.onTodoTap,
    required this.onTodoDelete,
    this.parentScrollController,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    // Adjust column width based on screen size for mobile
    // Mobile: 75% of screen width, max 280px for easier drag between columns
    // Web: fixed 280px
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth =
        kIsWeb ? 280.0 : (screenWidth * 0.75).clamp(240.0, 280.0);

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildDragTarget(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            headerColor.withValues(alpha: 0.2),
            headerColor.withValues(alpha: 0.05)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: headerColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                Text(
                  '${todos.length} ${context.read<LocalizationService>().translate(todos.length == 1 ? 'task' : 'tasks')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: headerColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${todos.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(BuildContext context) {
    return DragTarget<TodoModel>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final todo = details.data;
        final newIndex = todos.length;
        onTodoDropped(todo, status, newIndex);
        // Haptic feedback when dropped
        HapticFeedback.mediumImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                isHovering ? headerColor.withValues(alpha: 0.1) : Colors.transparent,            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          child: todos.isEmpty
              ? _buildEmptyState(context, isHovering)
              : _buildTaskList(isHovering),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isHovering) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHovering ? Icons.add_circle_outline : Icons.inbox_rounded,
              size: 48,
              color: isHovering
                  ? headerColor
                  : AppColors.lightTextSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isHovering
                  ? context.read<LocalizationService>().translate('drop_here')
                  : context.read<LocalizationService>().translate('no_tasks'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isHovering
                    ? headerColor
                    : AppColors.lightTextSecondary.withValues(alpha: 0.5),
              ),
            ),
            if (!isHovering)
              Text(
                context.read<LocalizationService>().translate('drag_to_move'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.lightTextSecondary.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(bool isHovering) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: todos.length + (isHovering ? 1 : 0),
      itemBuilder: (context, index) {
        // Show drop placeholder at the end when hovering
        if (isHovering && index == todos.length) {
          return Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: headerColor,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_rounded,
                color: headerColor,
                size: 32,
              ),
            ),
          );
        }

        final todo = todos[index];
        return _buildDraggableCard(todo);
      },
    );
  }

  Widget _buildDraggableCard(TodoModel todo) {
    final feedbackWidget = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 280,
        child: Transform.rotate(
          angle: 0.02,
          child: KanbanTaskCard(
            todo: todo,
            isDragging: true,
          ),
        ),
      ),
    );

    final childWhenDragging = Opacity(
      opacity: 0.3,
      child: KanbanTaskCard(todo: todo),
    );

    final childWidget = KanbanTaskCard(
      todo: todo,
      onTap: () => onTodoTap(todo),
      onDelete: () => onTodoDelete(todo),
    );

    // Use LongPressDraggable for mobile (touch), Draggable for web (mouse)
    if (kIsWeb) {
      return Draggable<TodoModel>(
        data: todo,
        onDragUpdate: (details) {
          if (onDragUpdate != null) {
            onDragUpdate!(details.globalPosition.dx);
          }
        },
        onDragEnd: (details) {
          onDragEnd?.call();
        },
        feedback: feedbackWidget,
        childWhenDragging: childWhenDragging,
        child: childWidget,
      );
    } else {
      // Mobile: use LongPressDraggable with haptic feedback
      return LongPressDraggable<TodoModel>(
        data: todo,
        delay: const Duration(milliseconds: 200),
        hapticFeedbackOnStart: true,
        onDragStarted: () {
          HapticFeedback.lightImpact();
        },
        onDragUpdate: (details) {
          if (onDragUpdate != null) {
            onDragUpdate!(details.globalPosition.dx);
          }
        },
        onDragEnd: (details) {
          onDragEnd?.call();
        },
        feedback: feedbackWidget,
        childWhenDragging: childWhenDragging,
        child: childWidget,
      );
    }
  }
}
