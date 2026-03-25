import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.toUid,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.relatedId,
    required this.senderUid,
    required this.senderName,
  });

  final String id;
  final String toUid;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String relatedId;
  final String senderUid;
  final String senderName;

  AppNotificationItem copyWith({
    String? id,
    String? toUid,
    String? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
    String? senderUid,
    String? senderName,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      toUid: toUid ?? this.toUid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
    );
  }

  factory AppNotificationItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return AppNotificationItem(
      id: doc.id,
      toUid: data['toUid']?.toString() ?? '',
      type: data['type']?.toString() ?? 'general',
      title: data['title']?.toString() ?? 'EWU Assistant',
      body: data['body']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
      isRead: data['isRead'] == true,
      relatedId: data['relatedId']?.toString() ?? '',
      senderUid: data['senderUid']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'toUid': toUid,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedId': relatedId,
      'senderUid': senderUid,
      'senderName': senderName,
    };
  }

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
