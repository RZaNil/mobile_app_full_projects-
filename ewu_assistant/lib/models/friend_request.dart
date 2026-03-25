import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestRecord {
  static const String pendingStatus = 'pending';
  static const String acceptedStatus = 'accepted';
  static const String rejectedStatus = 'rejected';

  const FriendRequestRecord({
    required this.id,
    required this.fromUid,
    required this.fromEmail,
    required this.fromName,
    required this.toUid,
    required this.toEmail,
    required this.toName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String fromEmail;
  final String fromName;
  final String toUid;
  final String toEmail;
  final String toName;
  final String status;
  final DateTime createdAt;

  bool get isPending => status == pendingStatus;
  bool get isAccepted => status == acceptedStatus;
  bool get isRejected => status == rejectedStatus;

  bool isIncomingFor(String uid) => toUid == uid;
  bool isOutgoingFor(String uid) => fromUid == uid;

  String otherUid(String currentUid) {
    return fromUid == currentUid ? toUid : fromUid;
  }

  String otherName(String currentUid) {
    return fromUid == currentUid ? toName : fromName;
  }

  factory FriendRequestRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FriendRequestRecord(
      id: doc.id,
      fromUid: data['fromUid']?.toString() ?? '',
      fromEmail: data['fromEmail']?.toString() ?? '',
      fromName: data['fromName']?.toString() ?? 'EWU Student',
      toUid: data['toUid']?.toString() ?? '',
      toEmail: data['toEmail']?.toString() ?? '',
      toName: data['toName']?.toString() ?? 'EWU Student',
      status: normalizeStatus(data['status']?.toString()),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fromUid': fromUid,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'toUid': toUid,
      'toEmail': toEmail,
      'toName': toName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static String normalizeStatus(String? status) {
    switch (status?.trim().toLowerCase()) {
      case acceptedStatus:
        return acceptedStatus;
      case rejectedStatus:
        return rejectedStatus;
      default:
        return pendingStatus;
    }
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
