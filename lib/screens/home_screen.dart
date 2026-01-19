import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
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
      builder: (context) => AddTodoBottomSheet(
        onTodoAdded: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildXpBar(),
            const SizedBox(height: 16),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodoList(),
                  _buildCompletedList(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: _currentUser!.photoURL != null
                ? NetworkImage(_currentUser!.photoURL!)
                : null,
            child: _currentUser!.photoURL == null
                ? Text(_currentUser!.displayName[0])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${_currentUser!.displayName.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.stars,
                        size: 16, color: AppColors.lightSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${_currentUser!.level}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentUser!.streak} day streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentUser!.xp} / ${_currentUser!.xpNeeded} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_currentUser!.progressPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _currentUser!.progressPercentage,
              minHeight: 10,
              backgroundColor: AppColors.lightSurface,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.lightPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.lightPrimary,
      unselectedLabelColor: AppColors.lightTextSecondary,
      indicatorColor: AppColors.lightPrimary,
      tabs: const [
        Tab(text: '📝 Active'),
        Tab(text: '✅ Completed'),
        Tab(text: '👤 Profile'),
      ],
    );
  }

  Widget _buildTodoList() {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<TodoModel>>(
      stream: firestoreService.getUserTodos(
        authService.currentUser!.uid,
        status: TodoStatus.pending,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt,
            title: 'No active tasks',
            subtitle: 'Tap + to create your first task!',
          );
        }

        final todos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            return TodoCard(
              todo: todos[index],
              onToggle: () async {
                await _toggleTodoStatus(todos[index]);
              },
              onDelete: () async {
                await _deleteTodo(todos[index].id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedList() {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<TodoModel>>(
      stream: firestoreService.getUserTodos(
        authService.currentUser!.uid,
        status: TodoStatus.completed,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.celebration,
            title: 'No completed tasks yet',
            subtitle: 'Complete some tasks to see them here!',
          );
        }

        final todos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            return TodoCard(
              todo: todos[index],
              onToggle: () async {
                await _toggleTodoStatus(todos[index]);
              },
              onDelete: () async {
                await _deleteTodo(todos[index].id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _currentUser!.photoURL != null
                ? NetworkImage(_currentUser!.photoURL!)
                : null,
            child: _currentUser!.photoURL == null
                ? Text(
                    _currentUser!.displayName[0],
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser!.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser!.email,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildMotivationalQuote(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.stars,
                  label: 'Level',
                  value: '${_currentUser!.level}',
                  color: AppColors.lightSecondary,
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '${_currentUser!.streak}',
                  color: AppColors.error,
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  label: 'XP',
                  value: '${_currentUser!.xp}',
                  color: AppColors.lightPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    final quotes = [
      '✨ "Every task completed is a step towards success!"',
      '🚀 "You\'re doing amazing! Keep going!"',
      '💪 "Small progress is still progress!"',
      '🌟 "Believe in yourself and all that you are!"',
      '🎯 "Focus on progress, not perfection!"',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    return Card(
      color: AppColors.lightPrimary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          quote,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.lightTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodoStatus(TodoModel todo) async {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();

    final newStatus = todo.status == TodoStatus.pending
        ? TodoStatus.completed
        : TodoStatus.pending;

    await firestoreService.toggleTodoStatus(todo.id, newStatus);

    // Award XP if completing
    if (newStatus == TodoStatus.completed) {
      final updatedUser = await authService.addXP(
        authService.currentUser!.uid,
        todo.xpReward,
      );

      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });

        // Show celebration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Great job! +${todo.xpReward} XP'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteTodo(String todoId) async {
    final firestoreService = context.read<FirestoreService>();
    await firestoreService.deleteTodo(todoId);
  }
}

// Todo Card Widget
class TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = todo.status == TodoStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.lightTextSecondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityChip(todo.priority),
                        const SizedBox(width: 8),
                        if (todo.dueDate != null)
                          _buildDueDateChip(todo.dueDate!, todo.isOverdue),
                        const Spacer(),
                        Text(
                          '+${todo.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TodoPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case TodoPriority.high:
        color = AppColors.priorityHigh;
        text = '🔴 High';
        break;
      case TodoPriority.medium:
        color = AppColors.priorityMedium;
        text = '🟡 Medium';
        break;
      case TodoPriority.low:
        color = AppColors.priorityLow;
        text = '🟢 Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDueDateChip(DateTime dueDate, bool isOverdue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.1)
            : AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('MMM d').format(dueDate),
        style: TextStyle(
          fontSize: 12,
          color: isOverdue ? AppColors.error : AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Add Todo Bottom Sheet
class AddTodoBottomSheet extends StatefulWidget {
  final VoidCallback onTodoAdded;

  const AddTodoBottomSheet({super.key, required this.onTodoAdded});

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
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
    );

    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _createTodo() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
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
    );

    try {
      await firestoreService.createTodo(todo);
      if (mounted) {
        Navigator.pop(context);
        widget.onTodoAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Task created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            const Text(
              'Create New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityButton(TodoPriority.low, '🟢 Low'),
                const SizedBox(width: 8),
                _buildPriorityButton(TodoPriority.medium, '🟡 Medium'),
                const SizedBox(width: 8),
                _buildPriorityButton(TodoPriority.high, '🔴 High'),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dueDate == null
                    ? 'Set due date'
                    : DateFormat('MMM d, yyyy').format(_dueDate!),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTodo,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(TodoPriority priority, String label) {
    final isSelected = _priority == priority;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _priority = priority),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.lightPrimary.withOpacity(0.1) : null,
          side: BorderSide(
            color: isSelected ? AppColors.lightPrimary : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
