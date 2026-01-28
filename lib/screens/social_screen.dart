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
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.lightPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightPrimary,
                AppColors.lightPrimary.withValues(alpha: 0.8),
                const Color(0xFFE8B4F8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                children: [
                  // Profile Section
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: user.photoURL == null
                                  ? Text(
                                      user.displayName.isNotEmpty
                                          ? user.displayName[0]
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 28, color: Colors.white),
                                    )
                                  : null,
                            ),
                          ),
                          if (user.currentEmoji != null)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(user.currentEmoji!,
                                    style: const TextStyle(fontSize: 18)),
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
                              user.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatBadge(Icons.people,
                                    '${user.friends.length} friends'),
                                const SizedBox(width: 8),
                                _buildStatBadge(
                                    Icons.flash_on, 'LV.${user.level}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Friend ID Card
                  _buildFriendIdCard(user.uid),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt_rounded),
                const SizedBox(width: 8),
                Text('Friends (${user.friends.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active_rounded),
                const SizedBox(width: 8),
                const Text('Activity'),
                if (user.unseenSupportCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${user.unseenSupportCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendIdCard(String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              uid,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            onPressed: () => _copyId(uid),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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
            const Icon(Icons.mood, color: AppColors.lightPrimary),
            const SizedBox(width: 8),
            const Text(
              "What's your vibe today?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.lightPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _emojis.length,
            itemBuilder: (context, index) {
              final item = _emojis[index];
              final isSelected = user.currentEmoji == item['emoji'];

              return GestureDetector(
                onTap: () => service.updateUserEmoji(user.uid, item['emoji']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.lightPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.lightPrimary
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.lightPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['emoji']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(begin: 0.2, end: 0);
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
            const Icon(Icons.search, color: AppColors.lightPrimary),
            const SizedBox(width: 8),
            const Text(
              'Find Friends by ID',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.lightPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Paste a Friend ID here...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.tag, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.lightPrimary,
              child: InkWell(
                onTap: _searchUser,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: _isSearching
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white),
                ),
              ),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('👋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  'No friends yet!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your Friend ID to connect',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: friends.asMap().entries.map((entry) {
            final index = entry.key;
            final friend = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendHouseScreen(friend: friend),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: friend.photoURL != null
                                ? NetworkImage(friend.photoURL!)
                                : null,
                            child: friend.photoURL == null
                                ? Text(friend.displayName[0],
                                    style: const TextStyle(fontSize: 20))
                                : null,
                          ),
                          if (friend.currentEmoji != null)
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Text(friend.currentEmoji!,
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
                              friend.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Level ${friend.level} • ${friend.streak} day streak 🔥',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: AppColors.lightPrimary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: 80 * index))
                .fadeIn()
                .slideX(begin: 0.1, end: 0);
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
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: req.photoURL != null
                          ? NetworkImage(req.photoURL!)
                          : null,
                      child: req.photoURL == null
                          ? Text(req.displayName[0])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Wants to be your friend!',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              service.acceptFriendRequest(me.uid, req.uid),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 32),
                        ),
                        IconButton(
                          onPressed: () =>
                              service.declineFriendRequest(me.uid, req.uid),
                          icon: Icon(Icons.cancel,
                              color: Colors.red[300], size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[100]!,
            Colors.purple[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: visit.visitorPhotoUrl != null
                ? NetworkImage(visit.visitorPhotoUrl!)
                : null,
            child: visit.visitorPhotoUrl == null
                ? Text(visit.visitorName[0])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${visit.visitorName} visited your house!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatTime(visit.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Text('🏠', style: TextStyle(fontSize: 28)),
        ],
      ),
    ).animate().fadeIn().shimmer(delay: 500.ms, duration: 1500.ms);
  }

  Widget _buildSupportCard(SupportAction support, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: support.fromUserPhotoUrl != null
                  ? NetworkImage(support.fromUserPhotoUrl!)
                  : null,
              child: support.fromUserPhotoUrl == null
                  ? Text(support.fromUserName[0])
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: support.fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${support.actionDisplayName}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(support.timestamp),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              support.actionEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn()
        .slideX(begin: 0.1);
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
