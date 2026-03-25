import 'package:cloud_firestore/cloud_firestore.dart';

class WorkplacePost {
  const WorkplacePost({
    required this.id,
    required this.title,
    required this.organization,
    required this.description,
    required this.location,
    required this.contactInfo,
    required this.authorUid,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String organization;
  final String description;
  final String location;
  final String contactInfo;
  final String authorUid;
  final DateTime createdAt;

  WorkplacePost copyWith({
    String? id,
    String? title,
    String? organization,
    String? description,
    String? location,
    String? contactInfo,
    String? authorUid,
    DateTime? createdAt,
  }) {
    return WorkplacePost(
      id: id ?? this.id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      description: description ?? this.description,
      location: location ?? this.location,
      contactInfo: contactInfo ?? this.contactInfo,
      authorUid: authorUid ?? this.authorUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WorkplacePost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return WorkplacePost(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      organization: data['organization']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      contactInfo: data['contactInfo']?.toString() ?? '',
      authorUid: data['authorUid']?.toString() ?? '',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'organization': organization,
      'description': description,
      'location': location,
      'contactInfo': contactInfo,
      'authorUid': authorUid,
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
