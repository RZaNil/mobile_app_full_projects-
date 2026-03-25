import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPost {
  const GalleryPost({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.authorStudentId,
    required this.authorPhotoUrl,
    required this.authorRole,
    required this.imageUrl,
    required this.caption,
    required this.likedBy,
    required this.timestamp,
  });

  final String id;
  final String authorName;
  final String authorEmail;
  final String authorStudentId;
  final String authorPhotoUrl;
  final String authorRole;
  final String imageUrl;
  final String caption;
  final List<String> likedBy;
  final DateTime timestamp;

  int get likes => likedBy.length;

  GalleryPost copyWith({
    String? id,
    String? authorName,
    String? authorEmail,
    String? authorStudentId,
    String? authorPhotoUrl,
    String? authorRole,
    String? imageUrl,
    String? caption,
    List<String>? likedBy,
    DateTime? timestamp,
  }) {
    return GalleryPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      authorRole: authorRole ?? this.authorRole,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likedBy: likedBy ?? this.likedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory GalleryPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return GalleryPost(
      id: doc.id,
      authorName: data['authorName']?.toString() ?? 'EWU Student',
      authorEmail: data['authorEmail']?.toString() ?? '',
      authorStudentId: data['authorStudentId']?.toString() ?? '',
      authorPhotoUrl: data['authorPhotoUrl']?.toString() ?? '',
      authorRole: data['authorRole']?.toString() ?? 'user',
      imageUrl: data['imageUrl']?.toString() ?? '',
      caption: data['caption']?.toString() ?? '',
      likedBy: List<String>.from(data['likedBy'] as List? ?? const <String>[]),
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'authorStudentId': authorStudentId,
      'authorPhotoUrl': authorPhotoUrl,
      'authorRole': authorRole,
      'imageUrl': imageUrl,
      'caption': caption,
      'likedBy': likedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
