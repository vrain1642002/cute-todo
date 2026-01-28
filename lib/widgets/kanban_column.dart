import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';
import 'kanban_task_card.dart';

class KanbanColumn extends StatefulWidget {
  final String title;
  final IconData icon;
  final TodoStatus status;
  final List<TodoModel> todos;
  final Color headerColor;
  final Color backgroundColor;
  final Color borderColor;
  final Function(TodoModel, TodoStatus, int) onTodoDropped;
  final Function(TodoModel) onTodoTap;
  final Function(TodoModel)? onTodoLongPress;
  final Function(TodoModel) onTodoDelete;
  final Function(TodoStatus)? onTodoDeleteAll;
  final ScrollController? parentScrollController;
  final Function(double)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool isReadOnly;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.todos,
    required this.headerColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTodoDropped,
    required this.onTodoTap,
    this.onTodoLongPress,
    required this.onTodoDelete,
    this.onTodoDeleteAll,
    this.parentScrollController,
    this.onDragUpdate,
    this.onDragEnd,
    this.isReadOnly = false,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth =
        kIsWeb ? 280.0 : (screenWidth * 0.75).clamp(240.0, 280.0);

    return Container(
      width: columnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor, width: 1.5),
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
    final loc = context.read<LocalizationService>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.headerColor.withValues(alpha: 0.2),
            widget.headerColor.withValues(alpha: 0.05)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.headerColor,
                      widget.headerColor.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(widget.icon, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.headerColor,
                      ),
                    ),
                    Text(
                      '${widget.todos.length} ${loc.translate(widget.todos.length == 1 ? 'task' : 'tasks')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.headerColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onTodoDeleteAll != null &&
                  widget.todos.isNotEmpty &&
                  !widget.isReadOnly)
                IconButton(
                  onPressed: () => widget.onTodoDeleteAll!(widget.status),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  iconSize: 20,
                  color: widget.headerColor.withValues(alpha: 0.7),
                  tooltip: loc.translate('delete_all'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(BuildContext context) {
    if (widget.isReadOnly) {
      return _buildTaskList(false);
    }
    return DragTarget<TodoModel>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final todo = details.data;
        final newIndex = widget.todos.length;
        widget.onTodoDropped(todo, widget.status, newIndex);
        HapticFeedback.mediumImpact();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovering
                ? widget.headerColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          child: widget.todos.isEmpty
              ? _buildEmptyState(context, isHovering)
              : _buildTaskList(isHovering),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isHovering) {
    final loc = context.read<LocalizationService>();
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
                  ? widget.headerColor
                  : AppColors.lightTextSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isHovering
                  ? loc.translate('drop_here')
                  : loc.translate('no_tasks'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isHovering
                    ? widget.headerColor
                    : AppColors.lightTextSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(bool isHovering) {
    final displayedTodos =
        _showAll ? widget.todos : widget.todos.take(5).toList();
    final hasMore = widget.todos.length > 5;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ...displayedTodos.map((todo) => _buildDraggableCard(todo)),
        if (isHovering)
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: widget.headerColor,
                  width: 2,
                  style: BorderStyle.solid),
            ),
            child: Center(
                child: Icon(Icons.add_rounded,
                    color: widget.headerColor, size: 32)),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(_showAll
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded),
              label: Text(
                  _showAll ? 'Show Less' : 'Show All (${widget.todos.length})'),
              style: TextButton.styleFrom(
                foregroundColor: widget.headerColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: widget.headerColor.withValues(alpha: 0.05),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDraggableCard(TodoModel todo) {
    final childWidget = KanbanTaskCard(
      todo: todo,
      onTap: () => widget.onTodoTap(todo),
      onLongPress:
          widget.isReadOnly ? null : () => widget.onTodoLongPress?.call(todo),
      onDelete: widget.isReadOnly ? null : () => widget.onTodoDelete(todo),
    );

    if (widget.isReadOnly) {
      return childWidget;
    }

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 280,
        child: Transform.rotate(
          angle: 0.02,
          child: KanbanTaskCard(todo: todo, isDragging: true),
        ),
      ),
    );

    final childWhenDragging =
        Opacity(opacity: 0.3, child: KanbanTaskCard(todo: todo));

    if (kIsWeb) {
      return Draggable<TodoModel>(
        data: todo,
        onDragUpdate: (details) =>
            widget.onDragUpdate?.call(details.globalPosition.dx),
        onDragEnd: (details) => widget.onDragEnd?.call(),
        feedback: feedbackWidget,
        childWhenDragging: childWhenDragging,
        child: childWidget,
      );
    } else {
      return LongPressDraggable<TodoModel>(
        data: todo,
        delay: const Duration(milliseconds: 200),
        hapticFeedbackOnStart: true,
        onDragStarted: () => HapticFeedback.lightImpact(),
        onDragUpdate: (details) =>
            widget.onDragUpdate?.call(details.globalPosition.dx),
        onDragEnd: (details) => widget.onDragEnd?.call(),
        feedback: feedbackWidget,
        childWhenDragging: childWhenDragging,
        child: childWidget,
      );
    }
  }
}
