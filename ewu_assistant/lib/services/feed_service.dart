import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/feed_post.dart';
import '../models/gallery_post.dart';

class FeedService {
  static const String campusFeedCollection = 'campus_feed';
  static const String campusGalleryCollection = 'campus_gallery';

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _firestore {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured yet. Complete the Firebase setup to use campus features.',
      );
    }
    return FirebaseFirestore.instance;
  }

  Stream<List<FeedPost>> getPosts() {
    if (!isAvailable) {
      return Stream<List<FeedPost>>.value(const <FeedPost>[]);
    }

    return _firestore
        .collection(campusFeedCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return FeedPost.fromFirestore(doc);
          }).toList(),
        );
  }

  Future<void> createPost(FeedPost post) async {
    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(campusFeedCollection);
      final DocumentReference<Map<String, dynamic>> doc = post.id.isEmpty
          ? collection.doc()
          : collection.doc(post.id);
      await doc.set(post.copyWith(id: doc.id).toMap());
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to publish the post right now.',
        ),
      );
    }
  }

  Future<void> toggleLike(String postId, String email) async {
    final String normalizedEmail = _requireSignedInEmail(email);
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection(campusFeedCollection)
        .doc(postId);

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);
        if (!snapshot.exists) {
          return;
        }

        final List<String> likedBy = List<String>.from(
          snapshot.data()?['likedBy'] as List? ?? const <String>[],
        );
        if (likedBy.contains(normalizedEmail)) {
          likedBy.remove(normalizedEmail);
        } else {
          likedBy.add(normalizedEmail);
        }

        transaction.update(ref, <String, dynamic>{
          'likedBy': likedBy,
          'likes': likedBy.length,
        });
      });
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to update the like right now.',
        ),
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final DocumentReference<Map<String, dynamic>> postRef = _firestore
          .collection(campusFeedCollection)
          .doc(postId);
      final QuerySnapshot<Map<String, dynamic>> replies = await postRef
          .collection('replies')
          .get();
      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> reply
          in replies.docs) {
        batch.delete(reply.reference);
      }
      batch.delete(postRef);
      await batch.commit();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to delete the post right now.',
        ),
      );
    }
  }

  Stream<List<PostReply>> getReplies(String postId) {
    if (!isAvailable) {
      return Stream<List<PostReply>>.value(const <PostReply>[]);
    }

    return _firestore
        .collection(campusFeedCollection)
        .doc(postId)
        .collection('replies')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return PostReply.fromFirestore(doc);
          }).toList(),
        );
  }

  Future<void> addReply(String postId, PostReply reply) async {
    try {
      final DocumentReference<Map<String, dynamic>> postRef = _firestore
          .collection(campusFeedCollection)
          .doc(postId);
      final CollectionReference<Map<String, dynamic>> repliesRef = postRef
          .collection('replies');
      final DocumentReference<Map<String, dynamic>> replyRef = reply.id.isEmpty
          ? repliesRef.doc()
          : repliesRef.doc(reply.id);

      final WriteBatch batch = _firestore.batch();
      batch.set(replyRef, reply.copyWith(id: replyRef.id).toMap());
      batch.update(postRef, <String, dynamic>{
        'replyCount': FieldValue.increment(1),
      });
      await batch.commit();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to send the reply right now.',
        ),
      );
    }
  }

  Stream<List<GalleryPost>> getGalleryPosts() {
    if (!isAvailable) {
      return Stream<List<GalleryPost>>.value(const <GalleryPost>[]);
    }

    return _firestore
        .collection(campusGalleryCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return GalleryPost.fromFirestore(doc);
          }).toList(),
        );
  }

  Future<void> createGalleryPost(GalleryPost post) async {
    try {
      final CollectionReference<Map<String, dynamic>> collection = _firestore
          .collection(campusGalleryCollection);
      final DocumentReference<Map<String, dynamic>> doc = post.id.isEmpty
          ? collection.doc()
          : collection.doc(post.id);
      await doc.set(post.copyWith(id: doc.id).toMap());
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to publish the photo right now.',
        ),
      );
    }
  }

  Future<void> deleteGalleryPost(String postId) async {
    try {
      await _firestore.collection(campusGalleryCollection).doc(postId).delete();
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to remove the photo right now.',
        ),
      );
    }
  }

  Future<void> toggleGalleryLike(String postId, String email) async {
    final String normalizedEmail = _requireSignedInEmail(email);
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection(campusGalleryCollection)
        .doc(postId);

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);
        if (!snapshot.exists) {
          return;
        }

        final List<String> likedBy = List<String>.from(
          snapshot.data()?['likedBy'] as List? ?? const <String>[],
        );
        if (likedBy.contains(normalizedEmail)) {
          likedBy.remove(normalizedEmail);
        } else {
          likedBy.add(normalizedEmail);
        }

        transaction.update(ref, <String, dynamic>{'likedBy': likedBy});
      });
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to update the like right now.',
        ),
      );
    }
  }

  String _requireSignedInEmail(String email) {
    final String normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Please sign in again to continue.');
    }
    return normalizedEmail;
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
