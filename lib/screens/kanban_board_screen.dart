import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart'; // Unused
// import 'package:flutter_animate/flutter_animate.dart'; // Unused
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/firestore_service.dart';
import '../services/image_upload_service.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import '../models/todo_model.dart';
import '../core/constants/colors.dart';

import '../widgets/kanban_header.dart';
import '../widgets/kanban_board.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_detail_sheet.dart';
import '../services/notification_service.dart';
import '../widgets/voice_dialog.dart';
import '../widgets/pet_widget.dart';
import '../services/voice_service.dart'; // Needed for TaskDraft
import 'login_screen.dart';
import 'social_screen.dart';

class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final ImageUploadService _imageUploadService = ImageUploadService();
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
        // Set user info for email notifications
        final notificationService = context.read<NotificationService>();
        notificationService.setUserInfo(
          email: user.email,
          displayName: userData?.displayName,
        );

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

  void _showAddTodoDialog({
    String? initialTitle,
    TodoPriority? initialPriority,
    DateTime? initialDueDate,
  }) {
    showDialog(
      context: context,
      builder: (context) => AddTaskSheet(
        initialTitle: initialTitle ?? '',
        initialPriority: initialPriority,
        initialDueDate: initialDueDate,
        onTaskAdded: () {
          setState(() {});
        },
        onTaskCreate:
            (title, description, dueDate, priority, category, imageUrls) async {
          // Create task logic
          final firestoreService = context.read<FirestoreService>();
          final authService = context.read<AuthService>();

          final newTodo = TodoModel(
            id: '', // Generated by Firestore
            userId: authService.currentUser!.uid,
            title: title,
            description: description ?? '', // Handle nullable description
            status: TodoStatus.todo,
            priority: priority,
            category: category,
            dueDate: dueDate,
            createdAt: DateTime.now(),
            imageUrls: imageUrls,
            // xpReward will be auto-calculated by TodoModel based on priority & category
          );

          final notificationService = context.read<NotificationService>();
          final docId = await firestoreService.createTodo(newTodo);

          if (!mounted) return;

          // Schedule offline notification
          if (dueDate != null) {
            await notificationService.scheduleDeadlineNotification(
              newTodo.copyWith(id: docId),
            );
          }
        },
      ),
    );
  }

  Future<void> _showVoiceDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const VoiceListeningDialog(),
    ).then((result) {
      if (result != null) {
        if (result is TaskDraft) {
          _showAddTodoDialog(
            initialTitle: result.title,
            initialPriority: result.priority,
            initialDueDate: result.dueDate,
          );
        } else if (result is String && result.isNotEmpty) {
          // Fallback for string
          _showAddTodoDialog(initialTitle: result);
        }
      }
    });
  }

  Future<void> _handleTodoDropped(
      TodoModel todo, TodoStatus newStatus, int newIndex) async {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();

    // 🚀 OPTIMIZATION: Fire database update immediately without waiting
    firestoreService.updateTodoStatus(todo.id, newStatus, newIndex);

    // If moving to completed, process rewards in background
    if (newStatus == TodoStatus.completed &&
        todo.status != TodoStatus.completed) {
      _handleCompletionRewards(todo, authService);
    }
  }

  Future<void> _handleCompletionRewards(
      TodoModel todo, AuthService authService) async {
    // Award XP
    var updatedUser = await authService.addXP(
      authService.currentUser!.uid,
      todo.xpReward,
    );

    // Pet Evolution Logic
    if (updatedUser != null && updatedUser.pet != null) {
      var pet = updatedUser.pet!;
      PetStage stage = pet.stage;
      bool evolved = false;

      // Evolve to Adult at User Level 5
      if (stage == PetStage.baby && updatedUser.level >= 5) {
        stage = PetStage.adult;
        evolved = true;
      }

      if (evolved) {
        final evolvedPet = pet.copyWith(stage: stage);
        updatedUser = updatedUser.copyWith(pet: evolvedPet);

        await authService.updateUserData(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  context.read<LocalizationService>().translate('pet_evolved')),
              backgroundColor: Colors.purpleAccent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

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
              Text(
                  '🎉 ${context.read<LocalizationService>().translate('great_job')} +${todo.xpReward} XP'),
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

  Future<void> _deleteTodo(String id) async {
    final loc = context.read<LocalizationService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text(loc.translate('delete_task_title')),
          ],
        ),
        content: Text(loc.translate('delete_task_confirm')),
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

    if (confirmed == true && mounted) {
      final firestoreService = context.read<FirestoreService>();

      // Cleanup media files
      final todo = await firestoreService.getTodo(id);
      if (todo != null && todo.imageUrls.isNotEmpty) {
        for (final url in todo.imageUrls) {
          if (url.startsWith('http')) {
            await _imageUploadService.deleteFile(url);
          }
        }
      }

      await firestoreService.deleteTodo(id);
    }
  }

  Future<void> _deleteAllTodos(TodoStatus status) async {
    final firestoreService = context.read<FirestoreService>();
    final authService = context.read<AuthService>();
    final userId = authService.currentUser!.uid;

    final todos =
        await firestoreService.getUserTodos(userId, status: status).first;
    for (var todo in todos) {
      // Cleanup media files
      if (todo.imageUrls.isNotEmpty) {
        for (final url in todo.imageUrls) {
          if (url.startsWith('http')) {
            await _imageUploadService.deleteFile(url);
          }
        }
      }
      await firestoreService.deleteTodo(todo.id);
    }
  }

  void _showTaskDetail(TodoModel todo) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailSheet(
        todo: todo,
        onTaskUpdate: (updatedTodo) async {
          final firestoreService = context.read<FirestoreService>();
          final notificationService = context.read<NotificationService>();

          await firestoreService.updateTodo(updatedTodo);

          if (!mounted) return;

          // Update notification
          // Always cancel old one first to avoid duplicates or orphaned timers
          await notificationService.cancelNotification(updatedTodo.id);

          if (updatedTodo.status == TodoStatus.todo &&
              updatedTodo.dueDate != null) {
            await notificationService.scheduleDeadlineNotification(updatedTodo);
          }
        },
      ),
    );
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

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final palette = themeService.currentPalette;

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: palette.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_currentUser != null)
                    KanbanHeader(
                      user: _currentUser!,
                      palette: palette,
                      onSignOut: _handleSignOut,
                      onSettingsTap: _showSettingsDialog,
                      onSocialTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SocialScreen()),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildXpBar()),
                        const SizedBox(width: 12),
                        _buildPetArea(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: KanbanBoard(
                      scrollController: _scrollController,
                      onTodoDropped: _handleTodoDropped,
                      onTodoDelete: _deleteTodo,
                      onTodoDeleteAll: _deleteAllTodos,
                      onTodoTap: _showTaskDetail,
                      onTodoLongPress: _showStatusChangeSheet,
                      onDragUpdate: _handleDragUpdate,
                      onDragEnd: _stopAutoScroll,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'voice_btn',
                onPressed: _showVoiceDialog,
                backgroundColor: palette.secondary,
                child: const Icon(Icons.mic_rounded, color: Colors.white),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                heroTag: 'add_btn',
                onPressed: _showAddTodoDialog,
                backgroundColor: palette.primary,
                icon: Icon(Icons.add_rounded, color: palette.surface),
                label: Text(
                  context.read<LocalizationService>().translate('add_task'),
                  style: TextStyle(
                      color: palette.surface, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusChangeSheet(TodoModel todo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusOption(
              todo,
              TodoStatus.todo,
              'To Do',
              Icons.assignment_rounded,
              AppColors.columnTodo,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              todo,
              TodoStatus.inProgress,
              'In Progress',
              Icons.rocket_launch_rounded,
              AppColors.columnInProgress,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              todo,
              TodoStatus.completed,
              'Done',
              Icons.check_circle_rounded,
              AppColors.columnDone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    TodoModel todo,
    TodoStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = todo.status == status;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          // Determine new index (append to end of list for simplicity)
          // We'll trust the board to re-sort or place it at the end
          // For a smoother UX, we could try to calculate the index,
          // but appending is a safe default for a "quick move" action.
          // However, to keep it consistent with drop, we ideally want it at the top or bottom.
          // Let's just use 0 (top) or a large number (bottom).
          // The reordering logic in KanbanBoard/Backend handles index updates.
          // For now, let's pass 0 to move to top, or we can fetch the list length if we had it.
          // Simpler: Just pass 0.
          _handleTodoDropped(todo, status, 0);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.lightText,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle_rounded, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildXpBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightPrimary.withValues(alpha: 0.1),
            AppColors.lightAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.2)),
        color: Colors.white.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 16, color: AppColors.lightPrimary),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentUser!.xp} / ${_currentUser!.xpNeeded} XP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LV. ${_currentUser!.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.lightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _currentUser!.progressPercentage,
              minHeight: 6,
              backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.lightPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetArea() {
    if (_currentUser == null) return const SizedBox.shrink();

    // If user has no pet, show Adopt button (smaller)
    if (_currentUser!.pet == null) {
      return GestureDetector(
        onTap: _adoptPet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightPrimary, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🥚', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text(
                context.read<LocalizationService>().translate('adopt'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show Pet Widget in Mini mode
    return PetWidget(
      pet: _currentUser!.pet!,
      isMini: true,
    );
  }

  Future<void> _adoptPet() async {
    if (_currentUser == null) return;
    final loc = context.read<LocalizationService>();

    // Show Choice Dialog
    final PetType? selectedType = await showDialog<PetType>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('choose_pet')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🐱', style: TextStyle(fontSize: 32)),
              title: Text(loc.translate('cat')),
              onTap: () => Navigator.pop(context, PetType.cat),
            ),
            ListTile(
              leading: const Text('🐶', style: TextStyle(fontSize: 32)),
              title: Text(loc.translate('dog')),
              onTap: () => Navigator.pop(context, PetType.dog),
            ),
          ],
        ),
      ),
    );

    if (selectedType == null) return;

    final random = Random();
    final newPet = PetModel(
      type: selectedType,
      name: selectedType == PetType.cat ? 'Mochi' : 'Buddy',
      lastFed: DateTime.now(),
      stage: PetStage.baby, // Start as Baby
      variant: random.nextInt(4), // Random variant 0-3
      evolutionProgress: 0,
    );

    final updatedUser = _currentUser!.copyWith(pet: newPet);

    // Optimistic update
    setState(() => _currentUser = updatedUser);

    if (!mounted) return;
    final authService = context.read<AuthService>();
    await authService.updateUserData(updatedUser);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}
