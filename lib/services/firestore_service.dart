import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../models/support_action_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== TODOS ====================

  // Create todo
  Future<String> createTodo(TodoModel todo) async {
    try {
      final docRef =
          await _firestore.collection('todos').add(todo.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating todo: $e');
      rethrow;
    }
  }

  // Update todo
  Future<void> updateTodo(TodoModel todo) async {
    try {
      final data = todo.toFirestore();
      // Reset notification flag so it can trigger again for the new date
      data['notificationSent'] = false;

      await _firestore.collection('todos').doc(todo.id).update(data);
    } catch (e) {
      debugPrint('Error updating todo: $e');
      rethrow;
    }
  }

  // Delete todo
  Future<void> deleteTodo(String todoId) async {
    try {
      await _firestore.collection('todos').doc(todoId).delete();
    } catch (e) {
      debugPrint('Error deleting todo: $e');
      rethrow;
    }
  }

  // Get single todo
  Future<TodoModel?> getTodo(String todoId) async {
    try {
      final doc = await _firestore.collection('todos').doc(todoId).get();
      if (doc.exists) {
        return TodoModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting todo: $e');
      return null;
    }
  }

  // Get all user todos stream (for Kanban board)
  Stream<List<TodoModel>> getAllUserTodos(String userId) {
    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .orderBy('orderIndex', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Get user todos stream by status
  Stream<List<TodoModel>> getUserTodos(String userId, {TodoStatus? status}) {
    Query query =
        _firestore.collection('todos').where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('orderIndex', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Update todo status (for drag-drop)
  Future<void> updateTodoStatus(
      String todoId, TodoStatus newStatus, int newOrderIndex) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'orderIndex': newOrderIndex,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == TodoStatus.completed) {
        updates['completedAt'] = Timestamp.now();
      } else {
        updates['completedAt'] = null;
      }

      await _firestore.collection('todos').doc(todoId).update(updates);
    } catch (e) {
      debugPrint('Error updating todo status: $e');
      rethrow;
    }
  }

  // Batch update todo orders (for reordering within column)
  Future<void> batchUpdateTodoOrders(List<TodoModel> todos) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < todos.length; i++) {
        final docRef = _firestore.collection('todos').doc(todos[i].id);
        batch.update(docRef, {
          'orderIndex': i,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error batch updating todo orders: $e');
      rethrow;
    }
  }

  // Get todos by category
  Stream<List<TodoModel>> getTodosByCategory(String userId, String category) {
    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('orderIndex', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Get unique categories for user
  Future<List<String>> getUserCategories(String userId) async {
    try {
      final todosSnapshot = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .get();

      final categories = <String>{};
      for (final doc in todosSnapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  // ==================== SOCIAL ====================

  /// Search for a user by their full UID (Friend ID)
  Future<UserModel?> searchUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  /// Send a friend request
  Future<void> sendFriendRequest(String fromId, String toId) async {
    try {
      await _firestore.collection('users').doc(toId).update({
        'friendRequests': FieldValue.arrayUnion([fromId])
      });
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Add to each other's friends list
      batch.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayUnion([friendId]),
        'friendRequests': FieldValue.arrayRemove([friendId])
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayUnion([userId])
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String userId, String friendId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'friendRequests': FieldValue.arrayRemove([friendId])
      });
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      rethrow;
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_firestore.collection('users').doc(userId), {
        'friends': FieldValue.arrayRemove([friendId])
      });
      batch.update(_firestore.collection('users').doc(friendId), {
        'friends': FieldValue.arrayRemove([userId])
      });
      await batch.commit();
    } catch (e) {
      debugPrint('Error removing friend: $e');
      rethrow;
    }
  }

  /// Update user's current emotion/emoji status
  Future<void> updateUserEmoji(String userId, String? emoji) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentEmoji': emoji,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating emoji: $e');
    }
  }

  /// Update user's status message
  Future<void> updateStatusMessage(String userId, String? message) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'statusMessage': message,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating status message: $e');
    }
  }

  /// Get stream of friend models
  Stream<List<UserModel>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds.take(30).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  /// Get stream of friend request models
  Stream<List<UserModel>> getFriendRequestsStream(List<String> requestIds) {
    if (requestIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: requestIds.take(30).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // ==================== REAL-TIME SUPPORT ====================

  /// Send a support action to another user
  Future<void> sendSupportAction({
    required String fromUserId,
    required String fromUserName,
    String? fromUserPhotoUrl,
    required String toUserId,
    required String actionType,
  }) async {
    try {
      // Add to recipient's supports subcollection
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('receivedSupports')
          .add({
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromUserPhotoUrl': fromUserPhotoUrl,
        'actionType': actionType,
        'timestamp': Timestamp.now(),
        'seen': false,
      });

      // Increment unseen count on the recipient
      await _firestore.collection('users').doc(toUserId).update({
        'unseenSupportCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error sending support: $e');
      rethrow;
    }
  }

  /// Get stream of received supports for a user
  Stream<List<SupportAction>> getReceivedSupportsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('receivedSupports')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportAction.fromFirestore(doc))
          .toList();
    });
  }

  /// Mark a support action as seen
  Future<void> markSupportAsSeen(String userId, String supportId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedSupports')
          .doc(supportId)
          .update({'seen': true});
    } catch (e) {
      debugPrint('Error marking support as seen: $e');
    }
  }

  /// Clear all unseen support count
  Future<void> clearUnseenSupportCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'unseenSupportCount': 0,
      });

      // Mark all supports as seen
      final supports = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receivedSupports')
          .where('seen', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in supports.docs) {
        batch.update(doc.reference, {'seen': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing unseen count: $e');
    }
  }

  /// Record a visit to a user's house
  Future<void> recordVisit({
    required String visitorId,
    required String visitorName,
    String? visitorPhotoUrl,
    required String hostId,
  }) async {
    try {
      await _firestore.collection('users').doc(hostId).update({
        'lastVisitedBy': {
          'visitorId': visitorId,
          'visitorName': visitorName,
          'visitorPhotoUrl': visitorPhotoUrl,
          'timestamp': Timestamp.now(),
        },
      });
    } catch (e) {
      debugPrint('Error recording visit: $e');
    }
  }

  /// Get real-time stream of a single user
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }
}
