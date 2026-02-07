import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/localization_service.dart';
import '../core/constants/colors.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatefulWidget {
  final ScrollController scrollController;
  final Function(TodoModel, TodoStatus, int) onTodoDropped;
  final Function(String) onTodoDelete;
  final Function(double) onDragUpdate;
  final VoidCallback onDragEnd;
  final Function(TodoModel)? onTodoTap;
  final Function(TodoModel)? onTodoLongPress;
  final Function(TodoStatus) onTodoDeleteAll;

  const KanbanBoard({
    super.key,
    required this.scrollController,
    required this.onTodoDropped,
    required this.onTodoDelete,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTodoDeleteAll,
    this.onTodoTap,
    this.onTodoLongPress,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  List<TodoModel> _todos = [];
  List<TodoModel> _todoTasks = [];
  List<TodoModel> _inProgressTasks = [];
  List<TodoModel> _doneTasks = [];

  bool _isInitialLoad = true;
  StreamSubscription<List<TodoModel>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribeToTodos();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToTodos() {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    _subscription = firestoreService
        .getAllUserTodos(authService.currentUser!.uid)
        .listen((todos) {
      if (mounted) {
        _updateCategorizedTasks(todos);
      }
    });
  }

  void _updateCategorizedTasks(List<TodoModel> todos) {
    // Sort once for efficiency
    final sorted = List<TodoModel>.from(todos)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _todos = sorted;
      _todoTasks = _todos.where((t) => t.status == TodoStatus.todo).toList();
      _inProgressTasks =
          _todos.where((t) => t.status == TodoStatus.inProgress).toList();
      _doneTasks =
          _todos.where((t) => t.status == TodoStatus.completed).toList();
      _isInitialLoad = false;
    });
  }

  /// Optimistic UI update: immediately update local state
  void _handleLocalDrop(TodoModel todo, TodoStatus newStatus, int newIndex) {
    // Create updated todo
    final updatedTodo = todo.copyWith(
      status: newStatus,
      completedAt: newStatus == TodoStatus.completed ? DateTime.now() : null,
      clearCompletedAt: newStatus != TodoStatus.completed,
      orderIndex: newIndex,
    );

    // Update local state immediately
    final newTodos = List<TodoModel>.from(_todos);
    newTodos.removeWhere((t) => t.id == todo.id);
    newTodos.add(updatedTodo);
    _updateCategorizedTasks(newTodos);

    // Fire actual update
    widget.onTodoDropped(todo, newStatus, newIndex);
  }

  Future<void> _confirmDeleteAll(TodoStatus status) async {
    final loc = context.read<LocalizationService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.translate('delete_all_tasks_title')),
        content: Text(loc.translate('delete_all_tasks_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(loc.translate('delete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onTodoDeleteAll(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lightPrimary),
      );
    }

    final loc = context.read<LocalizationService>();

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KanbanColumn(
            title: loc.translate('todo'),
            headerIcon: const Icon(Icons.assignment_rounded,
                size: 18, color: Colors.white),
            status: TodoStatus.todo,
            todos: _todoTasks,
            headerColor: AppColors.columnTodo,
            backgroundColor: AppColors.columnTodoBg,
            borderColor: AppColors.columnTodoBorder,
            onTodoDropped: _handleLocalDrop,
            onTodoTap: widget.onTodoTap ?? (todo) {},
            onTodoLongPress: widget.onTodoLongPress,
            onTodoDelete: (todo) => widget.onTodoDelete(todo.id),
            onTodoDeleteAll: _confirmDeleteAll,
            onDragUpdate: widget.onDragUpdate,
            onDragEnd: widget.onDragEnd,
          ),
          KanbanColumn(
            title: loc.translate('in_progress'),
            headerIcon: const Icon(Icons.rocket_launch_rounded,
                size: 18, color: Colors.white),
            status: TodoStatus.inProgress,
            todos: _inProgressTasks,
            headerColor: AppColors.columnInProgress,
            backgroundColor: AppColors.columnInProgressBg,
            borderColor: AppColors.columnInProgressBorder,
            onTodoDropped: _handleLocalDrop,
            onTodoTap: widget.onTodoTap ?? (todo) {},
            onTodoLongPress: widget.onTodoLongPress,
            onTodoDelete: (todo) => widget.onTodoDelete(todo.id),
            onTodoDeleteAll: _confirmDeleteAll,
            onDragUpdate: widget.onDragUpdate,
            onDragEnd: widget.onDragEnd,
          ),
          KanbanColumn(
            title: loc.translate('done'),
            headerIcon: const Icon(Icons.check_circle_rounded,
                size: 18, color: Colors.white),
            status: TodoStatus.completed,
            todos: _doneTasks,
            headerColor: AppColors.columnDone,
            backgroundColor: AppColors.columnDoneBg,
            borderColor: AppColors.columnDoneBorder,
            onTodoDropped: _handleLocalDrop,
            onTodoTap: widget.onTodoTap ?? (todo) {},
            onTodoLongPress: widget.onTodoLongPress,
            onTodoDelete: (todo) => widget.onTodoDelete(todo.id),
            onTodoDeleteAll: _confirmDeleteAll,
            onDragUpdate: widget.onDragUpdate,
            onDragEnd: widget.onDragEnd,
          ),
        ],
      ),
    );
  }
}
