import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/todo_model.dart';
import '../services/firestore_service.dart';
import '../core/constants/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FriendHouseScreen extends StatefulWidget {
  final UserModel friend;

  const FriendHouseScreen({super.key, required this.friend});

  @override
  State<FriendHouseScreen> createState() => _FriendHouseScreenState();
}

class _FriendHouseScreenState extends State<FriendHouseScreen> {
  int _interactions = 0;

  void _sendSupport() {
    setState(() => _interactions++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent motivation to ${widget.friend.displayName}! ✨'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightPrimary.withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.lightPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text("${widget.friend.displayName}'s House",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  background: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: widget.friend.photoURL != null
                              ? NetworkImage(widget.friend.photoURL!)
                              : null,
                          child: widget.friend.photoURL == null
                              ? Text(widget.friend.displayName[0],
                                  style: const TextStyle(fontSize: 32))
                              : null,
                        ),
                        const SizedBox(height: 8),
                        if (widget.friend.currentEmoji != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.friend.currentEmoji!,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 4),
                                Text(
                                    widget.friend.statusMessage ??
                                        'Feeling good!',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Social Interactions Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                          Icons.favorite, 'Love', Colors.red, _sendSupport),
                      _buildActionButton(Icons.celebration, 'Encourage',
                          Colors.orange, _sendSupport),
                      _buildActionButton(
                          Icons.pets, 'Pet Mascot', Colors.brown, _sendSupport),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Current Goals',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),

              // Friend's Todos
              StreamBuilder<List<TodoModel>>(
                stream: firestoreService.getAllUserTodos(widget.friend.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  final todos = snapshot.data!;

                  if (todos.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: Text('This house is empty... no tasks yet!',
                                style: TextStyle(color: Colors.grey))),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final todo = todos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: Icon(
                                todo.status == TodoStatus.completed
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: todo.status == TodoStatus.completed
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(todo.title,
                                  style: TextStyle(
                                    decoration:
                                        todo.status == TodoStatus.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                  )),
                              subtitle: Text(todo.category.name),
                              trailing: todo.priority == TodoPriority.high
                                  ? const Icon(Icons.flash_on,
                                      color: Colors.orange, size: 20)
                                  : null,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 50 * index))
                              .scale();
                        },
                        childCount: todos.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          //互动特效
          if (_interactions > 0)
            ...List.generate(
                _interactions,
                (index) => Positioned(
                      bottom: 100,
                      left: (index * 40) % MediaQuery.of(context).size.width,
                      child: const Icon(Icons.favorite,
                              color: Colors.pink, size: 40)
                          .animate()
                          .moveY(begin: 0, end: -500, duration: 2.seconds)
                          .fadeOut(),
                    )),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
