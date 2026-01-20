import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import '../widgets/kanban_column.dart';
import 'login_screen.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  double _scrollSpeed = 0;

  // Edge threshold for triggering auto-scroll
  static const double _scrollEdgeThreshold = 80.0;
  static const double _maxScrollSpeed = 12.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(double globalX) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate scroll speed based on proximity to edge
    // The closer to the edge, the faster the scroll
    if (globalX < _scrollEdgeThreshold) {
      // Near left edge - scroll left (negative)
      final proximity = 1.0 - (globalX / _scrollEdgeThreshold);
      _scrollSpeed = -_maxScrollSpeed * proximity;
      _startContinuousScroll();
    } else if (globalX > screenWidth - _scrollEdgeThreshold) {
      // Near right edge - scroll right (positive)
      final distanceFromEdge = screenWidth - globalX;
      final proximity = 1.0 - (distanceFromEdge / _scrollEdgeThreshold);
      _scrollSpeed = _maxScrollSpeed * proximity;
      _startContinuousScroll();
    } else {
      // Not near any edge - stop scrolling
      _stopAutoScroll();
    }
  }

  void _startContinuousScroll() {
    // Only start a new timer if one isn't already running
    if (_autoScrollTimer != null) return;

    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients && _scrollSpeed != 0) {
        final newOffset = _scrollController.offset + _scrollSpeed;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (newOffset >= 0 && newOffset <= maxScroll) {
          _scrollController.jumpTo(newOffset);
        } else if (newOffset < 0) {
          _scrollController.jumpTo(0);
        } else if (newOffset > maxScroll) {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _scrollSpeed = 0;
  }

  Future<void> _loadUserData() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null) {
      final userData = await authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showAddTodoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskBottomSheet(
        onTaskAdded: () {
          setState(() {});
        },
      ),
    );
  }

  Future<void> _handleTodoDropped(
      TodoModel todo, TodoStatus newStatus, int newIndex) async {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();

    // If moving to completed, award XP
    if (newStatus == TodoStatus.completed &&
        todo.status != TodoStatus.completed) {
      final updatedUser = await authService.addXP(
        authService.currentUser!.uid,
        todo.xpReward,
      );

      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Text('🎉 Great job! +${todo.xpReward} XP'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    await firestoreService.updateTodoStatus(todo.id, newStatus, newIndex);
  }

  Future<void> _deleteTodo(TodoModel todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Task?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.deleteTodo(todo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.lightPrimary),
        ),
      );
    }

    if (_currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildXpBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildKanbanBoard(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        backgroundColor: AppColors.lightPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightPrimary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightPrimary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: _currentUser!.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              backgroundColor: AppColors.lightPrimary.withOpacity(0.2),
              child: _currentUser!.photoURL == null
                  ? Text(
                      _currentUser!.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightPrimary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_currentUser!.displayName.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.stars_rounded,
                      label: 'Level ${_currentUser!.level}',
                      color: AppColors.lightSecondary,
                    ),
                    const SizedBox(width: 10),
                    _buildStatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${_currentUser!.streak} days',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.lightSurface,
              padding: const EdgeInsets.all(12),
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
        color: color.withOpacity(0.15),
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

  Widget _buildXpBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.lightPrimary.withOpacity(0.1),
              AppColors.lightAccent.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightPrimary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 20, color: AppColors.lightPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentUser!.xp} / ${_currentUser!.xpNeeded} XP',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_currentUser!.progressPercentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _currentUser!.progressPercentage,
                minHeight: 8,
                backgroundColor: AppColors.lightPrimary.withOpacity(0.2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.lightPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
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
          controller: _scrollController,
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
                onTodoDropped: _handleTodoDropped,
                onTodoTap: (todo) {},
                onTodoDelete: _deleteTodo,
                onDragUpdate: _handleDragUpdate,
                onDragEnd: _stopAutoScroll,
              ),
              KanbanColumn(
                title: 'In Progress',
                emoji: '🚀',
                status: TodoStatus.inProgress,
                todos: inProgressTasks,
                headerColor: AppColors.columnInProgress,
                backgroundColor: AppColors.columnInProgressBg,
                borderColor: AppColors.columnInProgressBorder,
                onTodoDropped: _handleTodoDropped,
                onTodoTap: (todo) {},
                onTodoDelete: _deleteTodo,
                onDragUpdate: _handleDragUpdate,
                onDragEnd: _stopAutoScroll,
              ),
              KanbanColumn(
                title: 'Done',
                emoji: '✅',
                status: TodoStatus.completed,
                todos: doneTasks,
                headerColor: AppColors.columnDone,
                backgroundColor: AppColors.columnDoneBg,
                borderColor: AppColors.columnDoneBorder,
                onTodoDropped: _handleTodoDropped,
                onTodoTap: (todo) {},
                onTodoDelete: _deleteTodo,
                onDragUpdate: _handleDragUpdate,
                onDragEnd: _stopAutoScroll,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Add Task Bottom Sheet
class _AddTaskBottomSheet extends StatefulWidget {
  final VoidCallback onTaskAdded;

  const _AddTaskBottomSheet({required this.onTaskAdded});

  @override
  State<_AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<_AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TodoPriority _priority = TodoPriority.medium;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    final todo = TodoModel(
      id: '',
      userId: authService.currentUser!.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      status: TodoStatus.todo,
    );

    try {
      await firestoreService.createTodo(todo);
      if (mounted) {
        Navigator.pop(context);
        widget.onTaskAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✨ Task created successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Row(
              children: [
                Icon(Icons.add_task_rounded,
                    color: AppColors.lightPrimary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Create New Task',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.lightPrimary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add some details...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.description_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.lightPrimary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Priority selector
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: TodoPriority.values.map((priority) {
                final isSelected = _priority == priority;
                Color color;
                String label;
                String emoji;

                switch (priority) {
                  case TodoPriority.low:
                    color = AppColors.priorityLow;
                    label = 'Low';
                    emoji = '🌱';
                    break;
                  case TodoPriority.medium:
                    color = AppColors.priorityMedium;
                    label = 'Medium';
                    emoji = '⚡';
                    break;
                  case TodoPriority.high:
                    color = AppColors.priorityHigh;
                    label = 'High';
                    emoji = '🔥';
                    break;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = priority),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? color
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Due date picker
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: _dueDate != null
                      ? Border.all(color: AppColors.info, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: _dueDate != null
                          ? AppColors.info
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? DateFormat('EEEE, MMMM d, y').format(_dueDate!)
                          : 'Set due date (optional)',
                      style: TextStyle(
                        fontSize: 15,
                        color: _dueDate != null
                            ? AppColors.lightText
                            : AppColors.lightTextSecondary,
                        fontWeight: _dueDate != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close,
                            size: 20, color: AppColors.lightTextSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.lightPrimary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded,
                              color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Create Task',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
