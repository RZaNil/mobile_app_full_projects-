import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipRecord {
  const FriendshipRecord({
    required this.id,
    required this.users,
    required this.createdAt,
  });

  final String id;
  final List<String> users;
  final DateTime createdAt;

  bool involves(String uid) => users.contains(uid);

  String? otherUserId(String currentUid) {
    for (final String uid in users) {
      if (uid != currentUid) {
        return uid;
      }
    }
    return null;
  }

  factory FriendshipRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FriendshipRecord(
      id: doc.id,
      users: List<String>.from(
        data['users'] as List? ?? const <String>[],
      ).where((String value) => value.trim().isNotEmpty).toList(),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'users': users,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
