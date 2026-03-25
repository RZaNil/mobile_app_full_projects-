import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeItem {
  const NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.authorUid,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;

  NoticeItem copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? authorUid,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
  }) {
    return NoticeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NoticeItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return NoticeItem(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      authorUid: data['authorUid']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'EWU Admin',
      authorRole: data['authorRole']?.toString() ?? 'user',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': Timestamp.fromDate(createdAt),
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
