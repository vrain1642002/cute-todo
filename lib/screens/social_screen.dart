import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants/colors.dart';
import 'friend_house_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  UserModel? _foundUser;
  String? _searchError;

  final List<String> _emojis = [
    '😊',
    '😴',
    '🔥',
    '📚',
    '🍕',
    '🎮',
    '🎨',
    '🐱',
    '🐶',
    '💖',
    '✨'
  ];

  Future<void> _searchUser() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundUser = null;
      _searchError = null;
    });

    try {
      final firestoreService = context.read<FirestoreService>();
      final currentUser = context.read<AuthService>().currentUser;

      if (_searchController.text == currentUser?.uid) {
        setState(() {
          _searchError = "You cannot add yourself!";
          _isSearching = false;
        });
        return;
      }

      final user =
          await firestoreService.searchUserById(_searchController.text);
      setState(() {
        _foundUser = user;
        if (user == null) _searchError = "User not found";
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = "Error searching user";
        _isSearching = false;
      });
    }
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social & Friends',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<UserModel?>(
        future: authService.getUserData(authService.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // My ID Section
                _buildSectionHeader('My Friend ID'),
                _buildMyIdCard(user.uid),

                const SizedBox(height: 30),

                // Emotion Picker
                _buildSectionHeader('Current Vibe'),
                _buildEmotionPicker(user),

                const SizedBox(height: 30),

                // Search Section
                _buildSectionHeader('Find Friends'),
                _buildSearchField(),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_foundUser != null) _buildFoundUserCard(user, _foundUser!),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(_searchError!,
                        style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: 30),

                // Friend Requests
                if (user.friendRequests.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Friend Requests (${user.friendRequests.length})'),
                  _buildFriendRequestsList(user, firestoreService),
                  const SizedBox(height: 30),
                ],

                // Friends List
                _buildSectionHeader('My Friends (${user.friends.length})'),
                _buildFriendsList(user, firestoreService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.lightPrimary),
      ),
    );
  }

  Widget _buildMyIdCard(String uid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              uid,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.copy, size: 20, color: AppColors.lightPrimary),
            onPressed: () => _copyId(uid),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionPicker(UserModel user) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          final isSelected = user.currentEmoji == emoji;
          return GestureDetector(
            onTap: () => context
                .read<FirestoreService>()
                .updateUserEmoji(user.uid, emoji),
            child: Container(
              width: 50,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lightPrimary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.lightPrimary.withValues(alpha: 0.3)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color:
                                AppColors.lightPrimary.withValues(alpha: 0.3),
                            blurRadius: 8)
                      ]
                    : [],
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Paste Friend ID here...',
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: _searchUser,
          mini: true,
          backgroundColor: AppColors.lightPrimary,
          child: const Icon(Icons.search, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFoundUserCard(UserModel me, UserModel found) {
    final isAlreadyFriend = me.friends.contains(found.uid);
    final hasSentRequest = found.friendRequests.contains(me.uid);

    return Card(
      margin: const EdgeInsets.only(top: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              found.photoURL != null ? NetworkImage(found.photoURL!) : null,
          child: found.photoURL == null ? Text(found.displayName[0]) : null,
        ),
        title: Text(found.displayName),
        subtitle: Text(found.currentEmoji ?? 'No status'),
        trailing: isAlreadyFriend
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: hasSentRequest
                    ? null
                    : () => context
                        .read<FirestoreService>()
                        .sendFriendRequest(me.uid, found.uid),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasSentRequest ? Colors.grey : AppColors.lightPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(hasSentRequest ? 'Pending' : 'Add Friend',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
      ),
    );
  }

  Widget _buildFriendsList(UserModel me, FirestoreService service) {
    return StreamBuilder<List<UserModel>>(
      stream: service.getFriendsStream(me.friends),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final friends = snapshot.data!;

        if (friends.isEmpty)
          return const Text('No friends yet. Add some!',
              style: TextStyle(color: Colors.grey));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final f = friends[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          f.photoURL != null ? NetworkImage(f.photoURL!) : null,
                      child: f.photoURL == null ? Text(f.displayName[0]) : null,
                    ),
                    if (f.currentEmoji != null)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Text(f.currentEmoji!,
                            style: const TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
                title: Text(f.displayName),
                subtitle: Text('LV. ${f.level}'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FriendHouseScreen(friend: f)));
                },
                trailing: const Icon(Icons.chevron_right),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .slideX();
          },
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
          children: requests
              .map((req) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(req.displayName[0])),
                      title: Text(req.displayName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () =>
                                service.acceptFriendRequest(me.uid, req.uid),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                service.declineFriendRequest(me.uid, req.uid),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
