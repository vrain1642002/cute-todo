import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_model.dart';

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
      print('Error creating todo: $e');
      rethrow;
    }
  }

  // Update todo
  Future<void> updateTodo(TodoModel todo) async {
    try {
      await _firestore
          .collection('todos')
          .doc(todo.id)
          .update(todo.toFirestore());
    } catch (e) {
      print('Error updating todo: $e');
      rethrow;
    }
  }

  // Delete todo
  Future<void> deleteTodo(String todoId) async {
    try {
      await _firestore.collection('todos').doc(todoId).delete();
    } catch (e) {
      print('Error deleting todo: $e');
      rethrow;
    }
  }

  // Get user todos stream
  Stream<List<TodoModel>> getUserTodos(String userId, {TodoStatus? status}) {
    Query query = _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Get todos by category
  Stream<List<TodoModel>> getTodosByCategory(String userId, String category) {
    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Get todos due today
  Stream<List<TodoModel>> getTodosDueToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TodoStatus.pending.name)
        .where('dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Get overdue todos
  Stream<List<TodoModel>> getOverdueTodos(String userId) {
    final now = DateTime.now();

    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TodoStatus.pending.name)
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Toggle todo status
  Future<void> toggleTodoStatus(String todoId, TodoStatus newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': Timestamp.now(),
      };

      if (newStatus == TodoStatus.completed) {
        updates['completedAt'] = Timestamp.now();
      } else {
        updates['completedAt'] = null;
      }

      await _firestore.collection('todos').doc(todoId).update(updates);
    } catch (e) {
      print('Error toggling todo status: $e');
      rethrow;
    }
  }

  // Get completion stats
  Future<Map<String, int>> getCompletionStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final completedToday = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: TodoStatus.completed.name)
          .where('completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      final totalCompleted = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: TodoStatus.completed.name)
          .get();

      final totalPending = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: TodoStatus.pending.name)
          .get();

      return {
        'completedToday': completedToday.docs.length,
        'totalCompleted': totalCompleted.docs.length,
        'totalPending': totalPending.docs.length,
      };
    } catch (e) {
      print('Error getting completion stats: $e');
      return {'completedToday': 0, 'totalCompleted': 0, 'totalPending': 0};
    }
  }

  // Get unique categories for user
  Future<List<String>> getUserCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }
}
