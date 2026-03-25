import 'package:cloud_firestore/cloud_firestore.dart';

class NoteItem {
  const NoteItem({
    required this.id,
    required this.courseCode,
    required this.courseTag,
    required this.title,
    required this.description,
    required this.uploaderUid,
    required this.uploaderName,
    required this.fileUrl,
    required this.createdAt,
  });

  final String id;
  final String courseCode;
  final String courseTag;
  final String title;
  final String description;
  final String uploaderUid;
  final String uploaderName;
  final String fileUrl;
  final DateTime createdAt;

  NoteItem copyWith({
    String? id,
    String? courseCode,
    String? courseTag,
    String? title,
    String? description,
    String? uploaderUid,
    String? uploaderName,
    String? fileUrl,
    DateTime? createdAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseTag: courseTag ?? this.courseTag,
      title: title ?? this.title,
      description: description ?? this.description,
      uploaderUid: uploaderUid ?? this.uploaderUid,
      uploaderName: uploaderName ?? this.uploaderName,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NoteItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return NoteItem(
      id: doc.id,
      courseCode: data['courseCode']?.toString() ?? '',
      courseTag: data['courseTag']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      uploaderUid: data['uploaderUid']?.toString() ?? '',
      uploaderName: data['uploaderName']?.toString() ?? 'EWU Student',
      fileUrl: data['fileUrl']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'courseCode': courseCode,
      'courseTag': courseTag,
      'title': title,
      'description': description,
      'uploaderUid': uploaderUid,
      'uploaderName': uploaderName,
      'fileUrl': fileUrl,
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
