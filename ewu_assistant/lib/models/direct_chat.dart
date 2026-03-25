import 'package:cloud_firestore/cloud_firestore.dart';

class DirectChatThread {
  const DirectChatThread({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderUid,
  });

  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderUid;

  bool includes(String uid) => participants.contains(uid);

  String? otherParticipantId(String currentUid) {
    for (final String uid in participants) {
      if (uid != currentUid) {
        return uid;
      }
    }
    return null;
  }

  factory DirectChatThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return DirectChatThread(
      id: doc.id,
      participants: List<String>.from(
        data['participants'] as List? ?? const <String>[],
      ).where((String value) => value.trim().isNotEmpty).toList(),
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageAt: _parseNullableDate(data['lastMessageAt']),
      lastSenderUid: data['lastSenderUid']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastSenderUid': lastSenderUid,
    };
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class DirectChatMessage {
  const DirectChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
    required this.seenBy,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final List<String> seenBy;

  factory DirectChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return DirectChatMessage(
      id: doc.id,
      senderUid: data['senderUid']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'EWU Student',
      text: data['text']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
      seenBy: List<String>.from(
        data['seenBy'] as List? ?? const <String>[],
      ).where((String value) => value.trim().isNotEmpty).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'seenBy': seenBy,
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
