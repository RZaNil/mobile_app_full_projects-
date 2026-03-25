import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoutineClassItem {
  static const List<String> days = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  const RoutineClassItem({
    required this.id,
    required this.day,
    required this.courseCode,
    required this.courseTitle,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String day;
  final String courseCode;
  final String courseTitle;
  final String room;
  final String startTime;
  final String endTime;
  final String color;
  final DateTime createdAt;

  Color get colorValue {
    final String hex = color.replaceAll('#', '').trim();
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF0A1F44);
  }

  RoutineClassItem copyWith({
    String? id,
    String? day,
    String? courseCode,
    String? courseTitle,
    String? room,
    String? startTime,
    String? endTime,
    String? color,
    DateTime? createdAt,
  }) {
    return RoutineClassItem(
      id: id ?? this.id,
      day: day ?? this.day,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      room: room ?? this.room,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RoutineClassItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return RoutineClassItem(
      id: doc.id,
      day: data['day']?.toString() ?? 'Mon',
      courseCode: data['courseCode']?.toString() ?? '',
      courseTitle: data['courseTitle']?.toString() ?? '',
      room: data['room']?.toString() ?? '',
      startTime: data['startTime']?.toString() ?? '',
      endTime: data['endTime']?.toString() ?? '',
      color: data['color']?.toString() ?? '#0A1F44',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'day': day,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
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
