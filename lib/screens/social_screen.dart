import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/support_action_model.dart';
import '../core/constants/colors.dart';
import 'friend_house_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  UserModel? _foundUser;
  String? _searchError;
  late TabController _tabController;

  final List<Map<String, String>> _emojis = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😴', 'label': 'Sleepy'},
    {'emoji': '🔥', 'label': 'Focused'},
    {'emoji': '📚', 'label': 'Studying'},
    {'emoji': '🍕', 'label': 'Eating'},
    {'emoji': '🎮', 'label': 'Gaming'},
    {'emoji': '🎨', 'label': 'Creative'},
    {'emoji': '💪', 'label': 'Working Out'},
    {'emoji': '🎵', 'label': 'Listening'},
    {'emoji': '💖', 'label': 'In Love'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _searchError = null;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      final currentUser = context.read<AuthService>().currentUser;

      if (query == currentUser?.uid) {
        setState(() {
          _searchError = "You can't add yourself! 😅";
          _isSearching = false;
        });
        return;
      }

      final user = await firestoreService.searchUserById(query);
      setState(() {
        _foundUser = user;
        if (user == null) _searchError = "No user found with this ID 🔍";
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = "Something went wrong 😢";
        _isSearching = false;
      });
    }
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Friend ID copied! Share it with your friends ✨'),
          ],
        ),
        backgroundColor: AppColors.lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<UserModel?>(
        stream:
            firestoreService.getUserStream(authService.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final user = snapshot.data!;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(user),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(user, firestoreService),
                _buildActivityTab(user, firestoreService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 310,
      pinned: true,
      backgroundColor: AppColors.lightPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: Stack(
            children: [
              // Vibrant Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.lightPrimary,
                      AppColors.lightPrimary.withValues(alpha: 0.9),
                      const Color(0xFFE8B4F8),
                      const Color(0xFFC084FC),
                    ],
                  ),
                ),
              ),

              // Decorative Blobs
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 3.seconds,
                  ),
              Positioned(
                bottom: 40,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                    begin: 0,
                    end: -20,
                    duration: 4.seconds,
                  ),

              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    children: [
                      // Profile Section
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Breathing Glow Effect
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              )
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.1, 1.1),
                                    duration: 2.seconds,
                                  )
                                  .fadeIn(duration: 2.seconds),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundImage: user.photoURL != null &&
                                          user.photoURL!.isNotEmpty
                                      ? NetworkImage(user.photoURL!)
                                      : null,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  child: user.photoURL == null ||
                                          user.photoURL!.isEmpty
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName[0]
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 28,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                              ),
                              if (user.currentEmoji != null)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(user.currentEmoji!,
                                        style: const TextStyle(fontSize: 18)),
                                  ).animate().scale(delay: 400.ms),
                                ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatBadge(Icons.people_rounded,
                                        '${user.friends.length} Friends'),
                                    const SizedBox(width: 10),
                                    _buildStatBadge(Icons.auto_awesome_rounded,
                                        'LV.${user.level}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                      const SizedBox(height: 28),

                      // Friend ID Card with Glassmorphism
                      _buildFriendIdCard(user.uid),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          child: TabBar(
            padding: const EdgeInsets.symmetric(vertical: 4),
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            unselectedLabelColor: Colors.white70,
            labelColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Friends (${user.friends.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text('Activity'),
                    if (user.unseenSupportCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${user.unseenSupportCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shake(hz: 2),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendIdCard(String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Friend ID',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uid,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _copyId(uid),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.copy_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildFriendsTab(UserModel user, FirestoreService service) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vibe Picker
        _buildVibeSection(user, service),
        const SizedBox(height: 24),

        // Search Section
        _buildSearchSection(user),

        // Friend Requests
        if (user.friendRequests.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Friend Requests', Icons.person_add_alt_1_rounded,
              user.friendRequests.length),
          const SizedBox(height: 12),
          _buildFriendRequestsList(user, service),
        ],

        // Friends List
        const SizedBox(height: 24),
        _buildSectionTitle(
            'My Friends', Icons.people_alt_rounded, user.friends.length),
        const SizedBox(height: 12),
        _buildFriendsList(user, service),
      ],
    );
  }

  Widget _buildVibeSection(UserModel user, FirestoreService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mood_rounded,
                  color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "How are you feeling?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final item = _emojis[index];
              final isSelected = user.currentEmoji == item['emoji'];

              return GestureDetector(
                onTap: () => service.updateUserEmoji(user.uid, item['emoji']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  width: 75,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.lightPrimary, Color(0xFFC084FC)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          isSelected ? Colors.transparent : Colors.grey[100]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.lightPrimary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['emoji']!,
                        style: const TextStyle(fontSize: 32),
                      ).animate(target: isSelected ? 1 : 0).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                          ),
                      const SizedBox(height: 6),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(begin: 0.1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.lightPrimary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lightPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.lightPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(UserModel me) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_search_rounded,
                  color: AppColors.lightPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Find New Friends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter Friend ID...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: AppColors.lightPrimary.withValues(alpha: 0.5),
                        size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.lightPrimary,
              elevation: 4,
              shadowColor: AppColors.lightPrimary.withValues(alpha: 0.4),
              child: InkWell(
                onTap: _searchUser,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 54,
                  width: 54,
                  alignment: Alignment.center,
                  child: _isSearching
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.search_rounded,
                          color: Colors.white, size: 26),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                  delay: 2.seconds,
                  duration: 2.seconds,
                  color: Colors.white24,
                ),
          ],
        ),

        // Search Result
        if (_foundUser != null) _buildFoundUserCard(me, _foundUser!),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Text(
                    _searchError!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFoundUserCard(UserModel me, UserModel found) {
    final isAlreadyFriend = me.friends.contains(found.uid);
    final hasSentRequest = found.friendRequests.contains(me.uid);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: found.photoURL != null
                      ? NetworkImage(found.photoURL!)
                      : null,
                  child: found.photoURL == null
                      ? Text(found.displayName[0],
                          style: const TextStyle(fontSize: 24))
                      : null,
                ),
                if (found.currentEmoji != null)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Text(found.currentEmoji!,
                          style: const TextStyle(fontSize: 14)),
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
                    found.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${found.level}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isAlreadyFriend)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 18),
                    const SizedBox(width: 4),
                    Text('Friends',
                        style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: hasSentRequest
                    ? null
                    : () => context
                        .read<FirestoreService>()
                        .sendFriendRequest(me.uid, found.uid),
                icon: Icon(hasSentRequest ? Icons.schedule : Icons.person_add),
                label: Text(hasSentRequest ? 'Pending' : 'Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSentRequest
                      ? Colors.grey[300]
                      : AppColors.lightPrimary,
                  foregroundColor:
                      hasSentRequest ? Colors.grey[600] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildFriendsList(UserModel me, FirestoreService service) {
    return StreamBuilder<List<UserModel>>(
      stream: service.getFriendsStream(me.friends),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data!;

        if (friends.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[100]!, width: 2),
            ),
            child: Column(
              children: [
                const Text('✨', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'Start your journey!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add friends to visit their houses and support each other',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn().scale();
        }

        return Column(
          children: friends.asMap().entries.map((entry) {
            final index = entry.key;
            final friend = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.grey[50]!, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendHouseScreen(friend: friend),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.lightPrimary
                                        .withValues(alpha: 0.2),
                                    width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundImage: friend.photoURL != null &&
                                        friend.photoURL!.isNotEmpty
                                    ? NetworkImage(friend.photoURL!)
                                    : null,
                                backgroundColor: AppColors.lightPrimary
                                    .withValues(alpha: 0.1),
                                child: friend.photoURL == null ||
                                        friend.photoURL!.isEmpty
                                    ? Text(
                                        friend.displayName.isNotEmpty
                                            ? friend.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            color: AppColors.lightPrimary,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                            if (friend.currentEmoji != null)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black12, blurRadius: 4)
                                    ],
                                  ),
                                  child: Text(friend.currentEmoji!,
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppColors.lightText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'LV.${friend.level}',
                                      style: TextStyle(
                                          color: Colors.amber[900],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.local_fire_department_rounded,
                                      size: 14, color: Colors.orange[400]),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${friend.streak} Streak',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.lightPrimary,
                                AppColors.lightPrimary.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lightPrimary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: 100 * index))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.05, duration: 400.ms);
          }).toList(),
        );
      },
    );
  }

  Widget _buildFriendRequestsList(UserModel me, FirestoreService service) {
    return StreamBuilder<List<UserModel>>(
      stream: service.getFriendRequestsStream(me.friendRequests),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final requests = snapshot.data!;

        return Column(
          children: requests.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.orange[100]!, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: CircleAvatar(
                        backgroundImage:
                            req.photoURL != null && req.photoURL!.isNotEmpty
                                ? NetworkImage(req.photoURL!)
                                : null,
                        backgroundColor: Colors.orange[100],
                        child: req.photoURL == null || req.photoURL!.isEmpty
                            ? Text(
                                req.displayName.isNotEmpty
                                    ? req.displayName[0]
                                    : '?',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF7C2D12)),
                          ),
                          Text(
                            'New friend request! ✨',
                            style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          shadowColor: Colors.green.withValues(alpha: 0.3),
                          child: InkWell(
                            onTap: () =>
                                service.acceptFriendRequest(me.uid, req.uid),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          borderOnForeground: true,
                          child: InkWell(
                            onTap: () =>
                                service.declineFriendRequest(me.uid, req.uid),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Icon(Icons.close_rounded,
                                  color: Colors.grey[400], size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideX(begin: 0.05);
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityTab(UserModel user, FirestoreService service) {
    // Clear unseen count when viewing activity
    if (user.unseenSupportCount > 0) {
      Future.microtask(() => service.clearUnseenSupportCount(user.uid));
    }

    return StreamBuilder<List<SupportAction>>(
      stream: service.getReceivedSupportsStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final supports = snapshot.data!;

        if (supports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💫', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'No activity yet!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When friends send you love, it will appear here',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Show last visitor if any
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user.lastVisitedBy != null) ...[
              _buildVisitorCard(user.lastVisitedBy!),
              const SizedBox(height: 20),
            ],
            const Text(
              'Recent Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...supports.asMap().entries.map((entry) {
              final index = entry.key;
              final support = entry.value;
              return _buildSupportCard(support, index);
            }),
          ],
        );
      },
    );
  }

  Widget _buildVisitorCard(HouseVisit visit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF3E8FF),
            const Color(0xFFFAF5FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: visit.visitorPhotoUrl != null &&
                      visit.visitorPhotoUrl!.isNotEmpty
                  ? NetworkImage(visit.visitorPhotoUrl!)
                  : null,
              backgroundColor: Colors.purple[100],
              child: visit.visitorPhotoUrl == null ||
                      visit.visitorPhotoUrl!.isEmpty
                  ? Text(
                      visit.visitorName.isNotEmpty
                          ? visit.visitorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: Colors.purple[700],
                          fontWeight: FontWeight.bold),
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
                  'House Visitor 🏠',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${visit.visitorName} visited you!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF4B237B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(visit.timestamp),
                  style: TextStyle(color: Colors.purple[300], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.temple_hindu_rounded,
                color: Colors.purple, size: 24),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05).shimmer(
        delay: 800.ms,
        duration: 1800.ms,
        color: Colors.white.withValues(alpha: 0.3));
  }

  Widget _buildSupportCard(SupportAction support, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: support.fromUserPhotoUrl != null &&
                        support.fromUserPhotoUrl!.isNotEmpty
                    ? NetworkImage(support.fromUserPhotoUrl!)
                    : null,
                backgroundColor: AppColors.lightPrimary.withValues(alpha: 0.1),
                child: support.fromUserPhotoUrl == null ||
                        support.fromUserPhotoUrl!.isEmpty
                    ? Text(
                        support.fromUserName.isNotEmpty
                            ? support.fromUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.lightPrimary,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    support.actionEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: AppColors.lightText, fontSize: 14),
                    children: [
                      TextSpan(
                        text: support.fromUserName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text: ' ${support.actionDisplayName}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(support.timestamp),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.lightPrimary,
              size: 18,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, duration: 400.ms);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
