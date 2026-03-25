import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  static const String userRole = 'user';
  static const String adminRole = 'admin';
  static const String superAdminRole = 'super_admin';

  const StudentProfile({
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.batchYear,
    required this.photoUrl,
    required this.role,
    required this.joinedAt,
  });

  final String name;
  final String email;
  final String studentId;
  final String department;
  final String batchYear;
  final String photoUrl;
  final String role;
  final DateTime joinedAt;

  static final RegExp _emailRegex = RegExp(
    r'^[\d\-]+@std\.ewubd\.edu$',
    caseSensitive: false,
  );

  static StudentProfile fromEmail({
    required String email,
    String? name,
    String? photoUrl,
    DateTime? joinedAt,
  }) {
    final String normalizedEmail = email.trim().toLowerCase();
    final String studentId = extractStudentId(normalizedEmail) ?? '';
    return StudentProfile(
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'EWU Student',
      email: normalizedEmail,
      studentId: studentId,
      department: detectDepartment(studentId),
      batchYear: detectBatchYear(studentId),
      photoUrl: photoUrl ?? '',
      role: userRole,
      joinedAt: joinedAt ?? DateTime.now(),
    );
  }

  static String? extractStudentId(String email) {
    final Match? match = RegExp(
      r'^([\d\-]+)@std\.ewubd\.edu$',
      caseSensitive: false,
    ).firstMatch(email.trim());
    return match?.group(1);
  }

  static bool isValidEwuEmail(String email) {
    return _emailRegex.hasMatch(email.trim().toLowerCase());
  }

  static String detectDepartment(String studentId) {
    if (studentId.isEmpty) {
      return 'Unknown';
    }

    final List<String> parts = studentId.split('-');
    final String code = parts.length >= 3 ? parts[2] : '';
    const Map<String, String> mapping = <String, String>{
      '60': 'CSE',
      '61': 'ECE',
      '62': 'EEE',
      '10': 'BBA',
      '20': 'Economics',
      '30': 'English',
      '40': 'Law',
      '50': 'Pharmacy',
      '70': 'Civil',
      '11': 'MBA',
    };
    return mapping[code] ?? 'Unknown';
  }

  static String detectBatchYear(String studentId) {
    final Match? match = RegExp(r'^(\d{4})').firstMatch(studentId);
    return match?.group(1) ?? 'Unknown';
  }

  static String normalizeRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case adminRole:
        return adminRole;
      case superAdminRole:
        return superAdminRole;
      default:
        return userRole;
    }
  }

  String get firstName {
    if (name.trim().isNotEmpty && name.trim() != 'EWU Student') {
      return name.trim().split(RegExp(r'\s+')).first;
    }
    return studentId.isNotEmpty ? studentId : email.split('@').first;
  }

  bool get isSuperAdmin => role == superAdminRole;
  bool get isAdmin => role == adminRole;
  bool get canModerateContent => isSuperAdmin || isAdmin;
  bool get canAccessAdminPanel => canModerateContent;

  StudentProfile copyWith({
    String? name,
    String? email,
    String? studentId,
    String? department,
    String? batchYear,
    String? photoUrl,
    String? role,
    DateTime? joinedAt,
  }) {
    return StudentProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      batchYear: batchYear ?? this.batchYear,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'batchYear': batchYear,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': joinedAt.toIso8601String(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name']?.toString() ?? 'EWU Student',
      email: json['email']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      department: json['department']?.toString() ?? 'Unknown',
      batchYear: json['batchYear']?.toString() ?? 'Unknown',
      photoUrl: json['photoUrl']?.toString() ?? '',
      role: normalizeRole(json['role']?.toString()),
      joinedAt: _parseDate(json['createdAt'] ?? json['joinedAt']),
    );
  }

  static String encode(StudentProfile profile) {
    return jsonEncode(profile.toJson());
  }

  static StudentProfile? decode(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return StudentProfile.fromJson(decoded);
      }
      if (decoded is Map) {
        return StudentProfile.fromJson(
          decoded.map(
            (dynamic key, dynamic value) =>
                MapEntry<String, dynamic>(key.toString(), value),
          ),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    final String raw = value?.toString() ?? '';
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
}
