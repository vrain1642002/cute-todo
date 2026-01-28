import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a support action sent from one user to another
class SupportAction {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhotoUrl;
  final String actionType; // 'love', 'encourage', 'pet'
  final DateTime timestamp;
  final bool seen;

  SupportAction({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl,
    required this.actionType,
    required this.timestamp,
    this.seen = false,
  });

  /// Get emoji for the action type
  String get actionEmoji {
    switch (actionType) {
      case 'love':
        return '❤️';
      case 'encourage':
        return '🎉';
      case 'pet':
        return '🐾';
      default:
        return '✨';
    }
  }

  /// Get action display name
  String get actionDisplayName {
    switch (actionType) {
      case 'love':
        return 'sent love';
      case 'encourage':
        return 'cheered you on';
      case 'pet':
        return 'pet your mascot';
      default:
        return 'supported you';
    }
  }

  factory SupportAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportAction(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? 'Someone',
      fromUserPhotoUrl: data['fromUserPhotoUrl'],
      actionType: data['actionType'] ?? 'love',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seen: data['seen'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'actionType': actionType,
      'timestamp': Timestamp.fromDate(timestamp),
      'seen': seen,
    };
  }

  SupportAction copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhotoUrl,
    String? actionType,
    DateTime? timestamp,
    bool? seen,
  }) {
    return SupportAction(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhotoUrl: fromUserPhotoUrl ?? this.fromUserPhotoUrl,
      actionType: actionType ?? this.actionType,
      timestamp: timestamp ?? this.timestamp,
      seen: seen ?? this.seen,
    );
  }
}

/// Represents a visit to a user's house
class HouseVisit {
  final String visitorId;
  final String visitorName;
  final String? visitorPhotoUrl;
  final DateTime timestamp;

  HouseVisit({
    required this.visitorId,
    required this.visitorName,
    this.visitorPhotoUrl,
    required this.timestamp,
  });

  factory HouseVisit.fromMap(Map<String, dynamic> data) {
    return HouseVisit(
      visitorId: data['visitorId'] ?? '',
      visitorName: data['visitorName'] ?? 'Someone',
      visitorPhotoUrl: data['visitorPhotoUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'visitorName': visitorName,
      'visitorPhotoUrl': visitorPhotoUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
