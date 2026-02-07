import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/user_model.dart';
import '../models/todo_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../core/constants/colors.dart';
import '../widgets/pet_widget.dart';
import '../widgets/task_detail_sheet.dart';
import '../widgets/kanban_column.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FriendHouseScreen extends StatefulWidget {
  final UserModel friend;

  const FriendHouseScreen({super.key, required this.friend});

  @override
  State<FriendHouseScreen> createState() => _FriendHouseScreenState();
}

class _FriendHouseScreenState extends State<FriendHouseScreen> {
  late ConfettiController _confettiController;
  bool _hasRecordedVisit = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _recordVisit();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _recordVisit() {
    if (_hasRecordedVisit) return;
    _hasRecordedVisit = true;

    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      firestoreService.recordVisit(
        visitorId: currentUser.uid,
        visitorName: currentUser.displayName ?? 'Someone',
        visitorPhotoUrl: currentUser.photoURL,
        hostId: widget.friend.uid,
      );
    }
  }

  void _sendSupport(String actionType) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final currentUser = authService.currentUser;

    if (currentUser != null) {
      firestoreService.sendSupportAction(
        fromUserId: currentUser.uid,
        fromUserName: currentUser.displayName ?? 'A friend',
        fromUserPhotoUrl: currentUser.photoURL,
        toUserId: widget.friend.uid,
        actionType: actionType,
      );

      _confettiController.play();

      String emoji;
      String message;
      switch (actionType) {
        case 'love':
          emoji = '❤️';
          message = 'You sent love!';
          break;
        case 'encourage':
          emoji = '🎉';
          message = 'You cheered them on!';
          break;
        case 'pet':
          emoji = '🐾';
          message = 'You pet their mascot!';
          break;
        default:
          emoji = '✨';
          message = 'Support sent!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTaskDetail(TodoModel todo) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailSheet(
        todo: todo,
        isReadOnlyOverride: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final themeService = context.watch<ThemeService>();
    final palette = themeService.currentPalette;
    final loc = context.read<LocalizationService>();

    return StreamBuilder<UserModel?>(
      stream: firestoreService.getUserStream(widget.friend.uid),
      builder: (context, userSnapshot) {
        final friend = userSnapshot.data ?? widget.friend;

        return Scaffold(
          body: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: palette.backgroundGradient,
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(friend, palette, loc),

                    // XP Bar & Pet Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildXpBar(friend)),
                          const SizedBox(width: 12),
                          _buildPetArea(friend),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Support buttons row
                    _buildSupportButtons(),

                    // Kanban Board - Using REAL KanbanColumn for 100% visual parity
                    Expanded(
                      child: StreamBuilder<List<TodoModel>>(
                        stream: firestoreService.getAllUserTodos(friend.uid),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.lightPrimary,
                              ),
                            );
                          }

                          final allTodos = snapshot.data!;
                          final todoTasks = allTodos
                              .where((t) => t.status == TodoStatus.todo)
                              .toList();
                          final inProgressTasks = allTodos
                              .where((t) => t.status == TodoStatus.inProgress)
                              .toList();
                          final doneTasks = allTodos
                              .where((t) => t.status == TodoStatus.completed)
                              .toList();

                          return SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                KanbanColumn(
                                  title: loc.translate('todo'),
                                  headerIcon: const Icon(
                                      Icons.assignment_rounded,
                                      size: 18,
                                      color: Colors.white),
                                  status: TodoStatus.todo,
                                  todos: todoTasks,
                                  headerColor: AppColors.columnTodo,
                                  backgroundColor: AppColors.columnTodoBg,
                                  borderColor: AppColors.columnTodoBorder,
                                  onTodoDropped: (_, __, ___) {},
                                  onTodoTap: _showTaskDetail,
                                  onTodoDelete: (_) {},
                                  isReadOnly: true,
                                ),
                                KanbanColumn(
                                  title: loc.translate('in_progress'),
                                  headerIcon: const Icon(
                                      Icons.rocket_launch_rounded,
                                      size: 18,
                                      color: Colors.white),
                                  status: TodoStatus.inProgress,
                                  todos: inProgressTasks,
                                  headerColor: AppColors.columnInProgress,
                                  backgroundColor: AppColors.columnInProgressBg,
                                  borderColor: AppColors.columnInProgressBorder,
                                  onTodoDropped: (_, __, ___) {},
                                  onTodoTap: _showTaskDetail,
                                  onTodoDelete: (_) {},
                                  isReadOnly: true,
                                ),
                                KanbanColumn(
                                  title: loc.translate('done'),
                                  headerIcon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: Colors.white),
                                  status: TodoStatus.completed,
                                  todos: doneTasks,
                                  headerColor: AppColors.columnDone,
                                  backgroundColor: AppColors.columnDoneBg,
                                  borderColor: AppColors.columnDoneBorder,
                                  onTodoDropped: (_, __, ___) {},
                                  onTodoTap: _showTaskDetail,
                                  onTodoDelete: (_) {},
                                  isReadOnly: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                  ],
                  numberOfParticles: 30,
                  gravity: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      UserModel user, ThemePalette palette, LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: palette.surface,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
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
                      user.photoURL != null && user.photoURL!.isNotEmpty
                          ? NetworkImage(user.photoURL!)
                          : null,
                  backgroundColor: palette.primary.withValues(alpha: 0.2),
                  child: (user.photoURL == null || user.photoURL!.isEmpty)
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
              if (user.currentEmoji != null)
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(user.currentEmoji!,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${user.displayName}'s House 🏠",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
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
        ],
      ),
    );
  }

  Widget _buildStatChip(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildXpBar(UserModel user) {
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
                    '${user.xp} / ${user.xpNeeded} XP',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('LV. ${user.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.lightPrimary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: user.progressPercentage,
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

  Widget _buildPetArea(UserModel user) {
    if (user.pet == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥚', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text('No Pet Yet',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightPrimary)),
          ],
        ),
      );
    }
    return PetWidget(pet: user.pet!, isMini: true);
  }

  Widget _buildSupportButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSupportButton('love', '❤️', 'Love', Colors.red),
          const SizedBox(width: 16),
          _buildSupportButton('encourage', '🎉', 'Cheer', Colors.orange),
          const SizedBox(width: 16),
          _buildSupportButton('pet', '🐾', 'Pet', Colors.brown),
        ],
      ),
    );
  }

  Widget _buildSupportButton(
      String action, String emoji, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendSupport(action),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
