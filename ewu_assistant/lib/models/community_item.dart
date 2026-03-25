import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityItem {
  static const String eventType = 'event';
  static const String lostFoundType = 'lost_found';
  static const String clubType = 'club';

  const CommunityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.authorUid,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String location;
  final String status;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;

  static const Map<String, IconData> typeIcons = <String, IconData>{
    eventType: Icons.event_available_outlined,
    lostFoundType: Icons.search_outlined,
    clubType: Icons.groups_2_outlined,
  };

  static const Map<String, String> typeLabels = <String, String>{
    eventType: 'Events',
    lostFoundType: 'Lost & Found',
    clubType: 'Clubs',
  };

  CommunityItem copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    String? location,
    String? status,
    String? authorUid,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
  }) {
    return CommunityItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CommunityItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return CommunityItem(
      id: doc.id,
      type: data['type']?.toString() ?? eventType,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      status: data['status']?.toString() ?? 'open',
      authorUid: data['authorUid']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'EWU Student',
      authorRole: data['authorRole']?.toString() ?? 'user',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
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
