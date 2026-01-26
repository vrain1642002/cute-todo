import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
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
      debugPrint('Error creating subtask: $e');
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
      debugPrint('Error updating todo: $e');
      rethrow;
    }
  }

  // Delete todo
  Future<void> deleteTodo(String todoId) async {
    try {
      await _firestore.collection('todos').doc(todoId).delete();
    } catch (e) {
      debugPrint('Error reordering todo: $e');
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

  // Get todos due today
  Stream<List<TodoModel>> getTodosDueToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('todos')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TodoStatus.todo.name)
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
        .where('status', isEqualTo: TodoStatus.todo.name)
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TodoModel.fromFirestore(doc)).toList();
    });
  }

  // Toggle todo status (legacy support)
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
      debugPrint('Error toggling subtask: $e');
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

      final totalTodo = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: TodoStatus.todo.name)
          .get();

      final totalInProgress = await _firestore
          .collection('todos')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: TodoStatus.inProgress.name)
          .get();

      return {
        'completedToday': completedToday.docs.length,
        'totalCompleted': totalCompleted.docs.length,
        'totalTodo': totalTodo.docs.length,
        'totalInProgress': totalInProgress.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting completion stats: $e');
      return {
        'completedToday': 0,
        'totalCompleted': 0,
        'totalTodo': 0,
        'totalInProgress': 0
      };
    }
  }

  // Get unique categories for user
  Future<List<String>> getUserCategories(String userId) async {
    try {
      // Categories are stored in the todos themselves
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
}
