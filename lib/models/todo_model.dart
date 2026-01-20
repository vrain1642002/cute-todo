import 'package:cloud_firestore/cloud_firestore.dart';

enum TodoPriority { low, medium, high }

enum TodoStatus { todo, inProgress, completed }

// Energy level for mood-based task filtering
enum EnergyLevel {
  any, // Default - no specific energy needed
  lowEnergy, // Light tasks when tired
  highFocus, // Deep work requiring concentration
  creative, // Tasks needing inspiration
}

// Task categories for RPG stats
enum TaskCategory {
  general, // Default
  study, // 📚 Intelligence
  exercise, // 💪 Strength
  housework, // 🧹 Diligence
  creative, // 🎨 Creativity
  social, // 💬 Charisma
  work, // 💼 Career
  selfCare, // 💆 Wellness
}

class TodoModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TaskCategory category;
  final TodoPriority priority;
  final EnergyLevel energyLevel;
  final DateTime? dueDate;
  final TodoStatus status;
  final List<String> tags;
  final List<Subtask> subtasks;
  final int xpReward;
  final int orderIndex;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Self-destructing task fields
  final bool autoDelete;
  final DateTime? expiresAt;

  TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = TaskCategory.general,
    this.priority = TodoPriority.medium,
    this.energyLevel = EnergyLevel.any,
    this.dueDate,
    this.status = TodoStatus.todo,
    this.tags = const [],
    this.subtasks = const [],
    int? xpReward,
    this.orderIndex = 0,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.autoDelete = false,
    this.expiresAt,
  })  : xpReward = xpReward ?? _calculateXpReward(priority),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static int _calculateXpReward(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return 10;
      case TodoPriority.medium:
        return 25;
      case TodoPriority.high:
        return 50;
    }
  }

  // Convert from Firestore
  factory TodoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle legacy 'pending' status mapping to 'todo'
    String statusStr = data['status'] ?? 'todo';
    if (statusStr == 'pending') statusStr = 'todo';

    return TodoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: TaskCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TaskCategory.general,
      ),
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TodoPriority.medium,
      ),
      energyLevel: EnergyLevel.values.firstWhere(
        (e) => e.name == data['energyLevel'],
        orElse: () => EnergyLevel.any,
      ),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      status: TodoStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => TodoStatus.todo,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      subtasks: (data['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromMap(e))
              .toList() ??
          [],
      xpReward: data['xpReward'] ?? 25,
      orderIndex: data['orderIndex'] ?? 0,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      autoDelete: data['autoDelete'] ?? false,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'energyLevel': energyLevel.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status.name,
      'tags': tags,
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'xpReward': xpReward,
      'orderIndex': orderIndex,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'autoDelete': autoDelete,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Check if overdue
  bool get isOverdue {
    if (dueDate == null || status == TodoStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Get completion percentage of subtasks
  double get subtaskProgress {
    if (subtasks.isEmpty) return 0.0;
    final completed = subtasks.where((s) => s.completed).length;
    return completed / subtasks.length;
  }

  TodoModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskCategory? category,
    TodoPriority? priority,
    EnergyLevel? energyLevel,
    DateTime? dueDate,
    bool clearDueDate = false,
    TodoStatus? status,
    List<String>? tags,
    List<Subtask>? subtasks,
    int? xpReward,
    int? orderIndex,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? autoDelete,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      energyLevel: energyLevel ?? this.energyLevel,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      xpReward: xpReward ?? this.xpReward,
      orderIndex: orderIndex ?? this.orderIndex,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      autoDelete: autoDelete ?? this.autoDelete,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }
}

class Subtask {
  final String title;
  final bool completed;

  Subtask({
    required this.title,
    this.completed = false,
  });

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      title: map['title'] ?? '',
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  Subtask copyWith({
    String? title,
    bool? completed,
  }) {
    return Subtask(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
