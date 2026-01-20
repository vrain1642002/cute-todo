import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { cat, dog, bunny, plant }

enum PetMood { happy, neutral, sad, sleeping }

class PetModel {
  final PetType type;
  final String name;
  final int health; // 0-100
  final int happiness; // 0-100
  final int level;
  final int xp;
  final DateTime lastFed;

  PetModel({
    this.type = PetType.cat,
    this.name = 'Mochi',
    this.health = 100,
    this.happiness = 100,
    this.level = 1,
    this.xp = 0,
    required this.lastFed,
  });

  PetMood get mood {
    if (health < 30) return PetMood.sad;
    if (happiness > 80) return PetMood.happy;
    return PetMood.neutral;
  }

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      type: PetType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PetType.cat,
      ),
      name: map['name'] ?? 'Mochi',
      health: map['health'] ?? 100,
      happiness: map['happiness'] ?? 100,
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      lastFed: (map['lastFed'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'health': health,
      'happiness': happiness,
      'level': level,
      'xp': xp,
      'lastFed': Timestamp.fromDate(lastFed),
    };
  }

  PetModel copyWith({
    PetType? type,
    String? name,
    int? health,
    int? happiness,
    int? level,
    int? xp,
    DateTime? lastFed,
  }) {
    return PetModel(
      type: type ?? this.type,
      name: name ?? this.name,
      health: health ?? this.health,
      happiness: happiness ?? this.happiness,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      lastFed: lastFed ?? this.lastFed,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final int level;
  final int xp;
  final int streak;
  final DateTime createdAt;
  final UserSettings settings;
  final PetModel? pet;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.level = 1,
    this.xp = 0,
    this.streak = 0,
    required this.createdAt,
    UserSettings? settings,
    this.pet,
  }) : settings = settings ?? UserSettings();

  // Convert from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
      streak: data['streak'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      settings: data['settings'] != null
          ? UserSettings.fromMap(data['settings'])
          : UserSettings(),
      pet: data['pet'] != null ? PetModel.fromMap(data['pet']) : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'level': level,
      'xp': xp,
      'streak': streak,
      'createdAt': Timestamp.fromDate(createdAt),
      'settings': settings.toMap(),
      'pet': pet?.toMap(),
    };
  }

  // Calculate XP needed for next level
  int get xpNeeded => level * 500;

  // Calculate progress percentage
  double get progressPercentage => (xp / xpNeeded).clamp(0.0, 1.0);

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    int? level,
    int? xp,
    int? streak,
    DateTime? createdAt,
    UserSettings? settings,
    PetModel? pet,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
      pet: pet ?? this.pet,
    );
  }
}

class UserSettings {
  final String theme; // 'light' or 'dark'
  final bool notifications;
  final bool sound;

  UserSettings({
    this.theme = 'light',
    this.notifications = true,
    this.sound = true,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      theme: map['theme'] ?? 'light',
      notifications: map['notifications'] ?? true,
      sound: map['sound'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'notifications': notifications,
      'sound': sound,
    };
  }

  UserSettings copyWith({
    String? theme,
    bool? notifications,
    bool? sound,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      sound: sound ?? this.sound,
    );
  }
}
