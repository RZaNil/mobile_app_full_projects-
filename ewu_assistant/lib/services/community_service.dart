import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/community_item.dart';
import '../models/notice_item.dart';
import '../models/routine_class_item.dart';
import 'notification_service.dart';

class CommunityService {
  static const String noticesCollection = 'notices';
  static const String communityItemsCollection = 'community_items';
  static const String routinesCollection = 'routines';
  static const String routineClassesCollection = 'classes';

  final NotificationService _notificationService = NotificationService();

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is unavailable right now. Please restart the app and try again.',
      );
    }
    return FirebaseFirestore.instance;
  }

  Stream<List<NoticeItem>> getNotices() {
    if (!isAvailable) {
      return Stream<List<NoticeItem>>.value(const <NoticeItem>[]);
    }

    return _firestore
        .collection(noticesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map(NoticeItem.fromFirestore).toList();
        });
  }

  Future<void> createNotice(NoticeItem notice) async {
    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(noticesCollection);
      final DocumentReference<Map<String, dynamic>> doc = notice.id.isEmpty
          ? collection.doc()
          : collection.doc(notice.id);
      final NoticeItem savedNotice = notice.copyWith(id: doc.id);
      await doc.set(savedNotice.toMap());

      final List<String> recipientIds = await _notificationService
          .getAllUserIds(excludingUid: notice.authorUid);
      await _notificationService.createForUsers(
        userIds: recipientIds,
        type: 'notice_published',
        title: 'New official notice',
        body: savedNotice.title,
        relatedId: savedNotice.id,
        senderUid: savedNotice.authorUid,
        senderName: savedNotice.authorName,
      );
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to publish the notice right now.',
        ),
      );
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection(noticesCollection).doc(noticeId).delete();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to delete the notice right now.',
        ),
      );
    }
  }

  Stream<List<CommunityItem>> getCommunityItems() {
    if (!isAvailable) {
      return Stream<List<CommunityItem>>.value(const <CommunityItem>[]);
    }

    return _firestore
        .collection(communityItemsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map(CommunityItem.fromFirestore).toList();
        });
  }

  Future<void> createCommunityItem(CommunityItem item) async {
    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(communityItemsCollection);
      final DocumentReference<Map<String, dynamic>> doc = item.id.isEmpty
          ? collection.doc()
          : collection.doc(item.id);
      await doc.set(item.copyWith(id: doc.id).toMap());
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to publish the community item right now.',
        ),
      );
    }
  }

  Future<void> updateCommunityItem(CommunityItem item) async {
    try {
      await _firestore
          .collection(communityItemsCollection)
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to update the community item right now.',
        ),
      );
    }
  }

  Future<void> deleteCommunityItem(String itemId) async {
    try {
      await _firestore
          .collection(communityItemsCollection)
          .doc(itemId)
          .delete();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to delete the community item right now.',
        ),
      );
    }
  }

  Stream<List<RoutineClassItem>> getRoutineClasses(String uid) {
    if (!isAvailable || uid.trim().isEmpty) {
      return Stream<List<RoutineClassItem>>.value(const <RoutineClassItem>[]);
    }

    return _firestore
        .collection(routinesCollection)
        .doc(uid)
        .collection(routineClassesCollection)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<RoutineClassItem> items = snapshot.docs
              .map(RoutineClassItem.fromFirestore)
              .toList();
          items.sort((RoutineClassItem a, RoutineClassItem b) {
            final int dayCompare = RoutineClassItem.days
                .indexOf(a.day)
                .compareTo(RoutineClassItem.days.indexOf(b.day));
            if (dayCompare != 0) {
              return dayCompare;
            }
            return a.startTime.compareTo(b.startTime);
          });
          return items;
        });
  }

  Future<void> createRoutineClass(String uid, RoutineClassItem item) async {
    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(routinesCollection)
          .doc(uid)
          .collection(routineClassesCollection);
      final DocumentReference<Map<String, dynamic>> doc = item.id.isEmpty
          ? collection.doc()
          : collection.doc(item.id);
      await doc.set(item.copyWith(id: doc.id).toMap());
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to save the class right now.',
        ),
      );
    }
  }

  Future<void> updateRoutineClass(String uid, RoutineClassItem item) async {
    try {
      await _firestore
          .collection(routinesCollection)
          .doc(uid)
          .collection(routineClassesCollection)
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to update the class right now.',
        ),
      );
    }
  }

  Future<void> deleteRoutineClass(String uid, String classId) async {
    try {
      await _firestore
          .collection(routinesCollection)
          .doc(uid)
          .collection(routineClassesCollection)
          .doc(classId)
          .delete();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to delete the class right now.',
        ),
      );
    }
  }

  String _mapFirestoreError(
    FirebaseException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to complete that action.';
      case 'unavailable':
        return 'The campus service is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'That item is no longer available.';
      default:
        return fallback;
    }
  }
}
