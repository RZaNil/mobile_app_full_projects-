import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_notification.dart';

class NotificationService {
  static const String notificationsCollection = 'notifications';
  static const String usersCollection = 'users';

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is unavailable right now. Please restart the app and try again.',
      );
    }
    return FirebaseFirestore.instance;
  }

  Stream<List<AppNotificationItem>> watchNotifications(String uid) {
    final String normalizedUid = uid.trim();
    if (!isAvailable || normalizedUid.isEmpty) {
      return Stream<List<AppNotificationItem>>.value(
        const <AppNotificationItem>[],
      );
    }

    return _firestore
        .collection(notificationsCollection)
        .where('toUid', isEqualTo: normalizedUid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<AppNotificationItem> notifications = snapshot.docs
              .map(AppNotificationItem.fromFirestore)
              .toList();
          notifications.sort((AppNotificationItem a, AppNotificationItem b) {
            return b.createdAt.compareTo(a.createdAt);
          });
          return notifications;
        });
  }

  Stream<int> watchUnreadCount(String uid) {
    return watchNotifications(uid).map((List<AppNotificationItem> items) {
      return items.where((AppNotificationItem item) => !item.isRead).length;
    });
  }

  Future<void> createNotification({
    required String toUid,
    required String type,
    required String title,
    required String body,
    String relatedId = '',
    String senderUid = '',
    String senderName = '',
  }) async {
    if (!isAvailable) {
      return;
    }

    final String normalizedUid = toUid.trim();
    if (normalizedUid.isEmpty) {
      return;
    }

    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(notificationsCollection);
      final DocumentReference<Map<String, dynamic>> doc = collection.doc();
      final AppNotificationItem item = AppNotificationItem(
        id: doc.id,
        toUid: normalizedUid,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        isRead: false,
        relatedId: relatedId,
        senderUid: senderUid,
        senderName: senderName,
      );
      await doc.set(item.toMap());
    } on FirebaseException {
      // Notifications are additive UX and should never break the primary flow.
    }
  }

  Future<void> createForUsers({
    required Iterable<String> userIds,
    required String type,
    required String title,
    required String body,
    String relatedId = '',
    String senderUid = '',
    String senderName = '',
  }) async {
    if (!isAvailable) {
      return;
    }

    final List<String> recipients = userIds
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (recipients.isEmpty) {
      return;
    }

    try {
      final WriteBatch batch = _firestore.batch();
      for (final String uid in recipients) {
        final DocumentReference<Map<String, dynamic>> doc = _firestore
            .collection(notificationsCollection)
            .doc();
        batch.set(
          doc,
          AppNotificationItem(
            id: doc.id,
            toUid: uid,
            type: type,
            title: title,
            body: body,
            createdAt: DateTime.now(),
            isRead: false,
            relatedId: relatedId,
            senderUid: senderUid,
            senderName: senderName,
          ).toMap(),
        );
      }
      await batch.commit();
    } on FirebaseException {
      // Notifications are best-effort only.
    }
  }

  Future<List<String>> getAllUserIds({String? excludingUid}) async {
    if (!isAvailable) {
      return const <String>[];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(usersCollection)
          .get();
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
          .where((String uid) => uid.isNotEmpty && uid != excludingUid)
          .toList();
    } on FirebaseException {
      return const <String>[];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (!isAvailable || notificationId.trim().isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection(notificationsCollection)
          .doc(notificationId)
          .set(<String, dynamic>{'isRead': true}, SetOptions(merge: true));
    } on FirebaseException {
      // Best-effort only.
    }
  }

  Future<void> markAllAsRead(String uid) async {
    final String normalizedUid = uid.trim();
    if (!isAvailable || normalizedUid.isEmpty) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(notificationsCollection)
          .where('toUid', isEqualTo: normalizedUid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        batch.update(doc.reference, <String, dynamic>{'isRead': true});
      }
      await batch.commit();
    } on FirebaseException {
      // Best-effort only.
    }
  }
}
