import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/constants/colors.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  final ScrollController scrollController;
  final Function(TodoModel, TodoStatus, int) onTodoDropped;
  final Function(String) onTodoDelete;
  final Function(double) onDragUpdate;
  final VoidCallback onDragEnd;
  final Function(TodoModel)? onTodoTap;

  const KanbanBoard({
    super.key,
    required this.scrollController,
    required this.onTodoDropped,
    required this.onTodoDelete,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onTodoTap,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<TodoModel>>(
      stream: firestoreService.getAllUserTodos(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lightPrimary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading tasks',
                  style: TextStyle(color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                      fontSize: 12, color: AppColors.lightTextSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allTodos = snapshot.data ?? [];
        final todoTasks =
            allTodos.where((t) => t.status == TodoStatus.todo).toList();
        final inProgressTasks =
            allTodos.where((t) => t.status == TodoStatus.inProgress).toList();
        final doneTasks =
            allTodos.where((t) => t.status == TodoStatus.completed).toList();

        return SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KanbanColumn(
                title: 'To Do',
                emoji: '📋',
                status: TodoStatus.todo,
                todos: todoTasks,
                headerColor: AppColors.columnTodo,
                backgroundColor: AppColors.columnTodoBg,
                borderColor: AppColors.columnTodoBorder,
                onTodoDropped: onTodoDropped,
                onTodoTap: onTodoTap ?? (todo) {},
                onTodoDelete: (todo) => onTodoDelete(todo.id),
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
              ),
              KanbanColumn(
                title: 'In Progress',
                emoji: '🚀',
                status: TodoStatus.inProgress,
                todos: inProgressTasks,
                headerColor: AppColors.columnInProgress,
                backgroundColor: AppColors.columnInProgressBg,
                borderColor: AppColors.columnInProgressBorder,
                onTodoDropped: onTodoDropped,
                onTodoTap: onTodoTap ?? (todo) {},
                onTodoDelete: (todo) => onTodoDelete(todo.id),
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
              ),
              KanbanColumn(
                title: 'Done',
                emoji: '✅',
                status: TodoStatus.completed,
                todos: doneTasks,
                headerColor: AppColors.columnDone,
                backgroundColor: AppColors.columnDoneBg,
                borderColor: AppColors.columnDoneBorder,
                onTodoDropped: onTodoDropped,
                onTodoTap: onTodoTap ?? (todo) {},
                onTodoDelete: (todo) => onTodoDelete(todo.id),
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
              ),
            ],
          ),
        );
      },
    );
  }
}
