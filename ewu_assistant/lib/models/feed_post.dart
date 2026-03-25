import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.authorStudentId,
    required this.authorPhotoUrl,
    required this.authorRole,
    required this.category,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
    required this.replyCount,
  });

  final String id;
  final String authorName;
  final String authorEmail;
  final String authorStudentId;
  final String authorPhotoUrl;
  final String authorRole;
  final String category;
  final String title;
  final String body;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
  final int replyCount;

  static const List<String> categories = <String>[
    'General',
    'Academic',
    'Events',
    'Clubs',
    'Lost & Found',
    'Help',
  ];

  static const Map<String, IconData> categoryIcons = <String, IconData>{
    'General': Icons.campaign_outlined,
    'Academic': Icons.school_outlined,
    'Events': Icons.event_outlined,
    'Clubs': Icons.groups_2_outlined,
    'Lost & Found': Icons.search_outlined,
    'Help': Icons.help_outline,
  };

  String get displayHandle {
    final String base = authorStudentId.isNotEmpty
        ? authorStudentId
        : authorEmail.split('@').first;
    return '@${base.toLowerCase()}';
  }

  FeedPost copyWith({
    String? id,
    String? authorName,
    String? authorEmail,
    String? authorStudentId,
    String? authorPhotoUrl,
    String? authorRole,
    String? category,
    String? title,
    String? body,
    DateTime? timestamp,
    int? likes,
    List<String>? likedBy,
    int? replyCount,
  }) {
    return FeedPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      authorRole: authorRole ?? this.authorRole,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  factory FeedPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final List<String> likedBy = List<String>.from(
      data['likedBy'] as List? ?? const <String>[],
    );
    return FeedPost(
      id: doc.id,
      authorName: data['authorName']?.toString() ?? 'EWU Student',
      authorEmail: data['authorEmail']?.toString() ?? '',
      authorStudentId: data['authorStudentId']?.toString() ?? '',
      authorPhotoUrl: data['authorPhotoUrl']?.toString() ?? '',
      authorRole: data['authorRole']?.toString() ?? 'user',
      category: data['category']?.toString() ?? 'General',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      likes: (data['likes'] as num?)?.toInt() ?? likedBy.length,
      likedBy: likedBy,
      replyCount: (data['replyCount'] as num?)?.toInt() ?? 0,
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
      'category': category,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'likedBy': likedBy,
      'replyCount': replyCount,
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

class PostReply {
  const PostReply({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.authorStudentId,
    required this.authorPhotoUrl,
    required this.body,
    required this.timestamp,
  });

  final String id;
  final String authorName;
  final String authorEmail;
  final String authorStudentId;
  final String authorPhotoUrl;
  final String body;
  final DateTime timestamp;

  PostReply copyWith({
    String? id,
    String? authorName,
    String? authorEmail,
    String? authorStudentId,
    String? authorPhotoUrl,
    String? body,
    DateTime? timestamp,
  }) {
    return PostReply(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorEmail: authorEmail ?? this.authorEmail,
      authorStudentId: authorStudentId ?? this.authorStudentId,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory PostReply.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return PostReply(
      id: doc.id,
      authorName: data['authorName']?.toString() ?? 'EWU Student',
      authorEmail: data['authorEmail']?.toString() ?? '',
      authorStudentId: data['authorStudentId']?.toString() ?? '',
      authorPhotoUrl: data['authorPhotoUrl']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      timestamp: FeedPost._parseTimestamp(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'authorStudentId': authorStudentId,
      'authorPhotoUrl': authorPhotoUrl,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
