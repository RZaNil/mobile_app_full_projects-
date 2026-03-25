import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/direct_chat.dart';
import '../models/friend_request.dart';
import '../models/friendship.dart';
import '../models/student_profile.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class MessagesDashboardData {
  const MessagesDashboardData({
    required this.currentUid,
    required this.users,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friendships,
    required this.chats,
  });

  final String currentUid;
  final List<UserDirectoryRecord> users;
  final List<FriendRequestRecord> incomingRequests;
  final List<FriendRequestRecord> outgoingRequests;
  final List<FriendshipRecord> friendships;
  final List<DirectChatThread> chats;

  factory MessagesDashboardData.empty({required String currentUid}) {
    return MessagesDashboardData(
      currentUid: currentUid,
      users: const <UserDirectoryRecord>[],
      incomingRequests: const <FriendRequestRecord>[],
      outgoingRequests: const <FriendRequestRecord>[],
      friendships: const <FriendshipRecord>[],
      chats: const <DirectChatThread>[],
    );
  }

  Map<String, UserDirectoryRecord> get usersByUid {
    return <String, UserDirectoryRecord>{
      for (final UserDirectoryRecord record in users) record.uid: record,
    };
  }

  List<UserDirectoryRecord> get directoryUsers {
    return users.where((UserDirectoryRecord record) {
      return record.uid != currentUid;
    }).toList();
  }

  List<FriendRequestRecord> get pendingIncomingRequests {
    return incomingRequests.where((FriendRequestRecord request) {
      return request.isPending;
    }).toList();
  }

  Set<String> get friendUserIds {
    return friendships
        .map(
          (FriendshipRecord friendship) => friendship.otherUserId(currentUid),
        )
        .whereType<String>()
        .toSet();
  }

  bool isFriendWith(String otherUid) => friendUserIds.contains(otherUid);

  UserDirectoryRecord? userForId(String uid) => usersByUid[uid];

  FriendRequestRecord? outgoingRequestTo(String otherUid) {
    FriendRequestRecord? latest;
    for (final FriendRequestRecord request in outgoingRequests) {
      if (request.toUid != otherUid) {
        continue;
      }
      if (latest == null || request.createdAt.isAfter(latest.createdAt)) {
        latest = request;
      }
    }
    return latest;
  }

  FriendRequestRecord? incomingRequestFrom(String otherUid) {
    FriendRequestRecord? latest;
    for (final FriendRequestRecord request in incomingRequests) {
      if (request.fromUid != otherUid) {
        continue;
      }
      if (latest == null || request.createdAt.isAfter(latest.createdAt)) {
        latest = request;
      }
    }
    return latest;
  }

  DirectChatThread? chatWith(String otherUid) {
    for (final DirectChatThread chat in chats) {
      if (chat.participants.contains(otherUid)) {
        return chat;
      }
    }
    return null;
  }

  List<UserDirectoryRecord> friendUsers() {
    final List<UserDirectoryRecord> records = <UserDirectoryRecord>[];
    final Map<String, UserDirectoryRecord> map = usersByUid;
    for (final FriendshipRecord friendship in friendships) {
      final String? otherUid = friendship.otherUserId(currentUid);
      if (otherUid == null) {
        continue;
      }
      final UserDirectoryRecord? record = map[otherUid];
      if (record != null) {
        records.add(record);
      }
    }
    records.sort((UserDirectoryRecord a, UserDirectoryRecord b) {
      return a.profile.name.toLowerCase().compareTo(
        b.profile.name.toLowerCase(),
      );
    });
    return records;
  }
}

class SocialService {
  static const String usersCollection = 'users';
  static const String friendRequestsCollection = 'friend_requests';
  static const String friendshipsCollection = 'friendships';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

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

  Stream<MessagesDashboardData> watchDashboard(String currentUid) {
    final String normalizedUid = currentUid.trim();
    if (!isAvailable || normalizedUid.isEmpty) {
      return Stream<MessagesDashboardData>.value(
        MessagesDashboardData.empty(currentUid: normalizedUid),
      );
    }

    late StreamController<MessagesDashboardData> controller;
    final List<StreamSubscription<dynamic>> subscriptions =
        <StreamSubscription<dynamic>>[];

    List<UserDirectoryRecord> users = const <UserDirectoryRecord>[];
    List<FriendRequestRecord> incomingRequests = const <FriendRequestRecord>[];
    List<FriendRequestRecord> outgoingRequests = const <FriendRequestRecord>[];
    List<FriendshipRecord> friendships = const <FriendshipRecord>[];
    List<DirectChatThread> chats = const <DirectChatThread>[];

    void emit() {
      if (controller.isClosed) {
        return;
      }
      controller.add(
        MessagesDashboardData(
          currentUid: normalizedUid,
          users: users,
          incomingRequests: incomingRequests,
          outgoingRequests: outgoingRequests,
          friendships: friendships,
          chats: chats,
        ),
      );
    }

    controller = StreamController<MessagesDashboardData>(
      onListen: () {
        emit();

        subscriptions.add(
          AuthService.watchUsers().listen((List<UserDirectoryRecord> value) {
            users = value;
            emit();
          }, onError: controller.addError),
        );

        subscriptions.add(
          _firestore
              .collection(friendRequestsCollection)
              .where('toUid', isEqualTo: normalizedUid)
              .snapshots()
              .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
                incomingRequests =
                    snapshot.docs
                        .map(FriendRequestRecord.fromFirestore)
                        .toList()
                      ..sort(_sortByDateDescending);
                emit();
              }, onError: controller.addError),
        );

        subscriptions.add(
          _firestore
              .collection(friendRequestsCollection)
              .where('fromUid', isEqualTo: normalizedUid)
              .snapshots()
              .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
                outgoingRequests =
                    snapshot.docs
                        .map(FriendRequestRecord.fromFirestore)
                        .toList()
                      ..sort(_sortByDateDescending);
                emit();
              }, onError: controller.addError),
        );

        subscriptions.add(
          _firestore
              .collection(friendshipsCollection)
              .where('users', arrayContains: normalizedUid)
              .snapshots()
              .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
                friendships =
                    snapshot.docs.map(FriendshipRecord.fromFirestore).toList()
                      ..sort(
                        (FriendshipRecord a, FriendshipRecord b) =>
                            b.createdAt.compareTo(a.createdAt),
                      );
                emit();
              }, onError: controller.addError),
        );

        subscriptions.add(
          _firestore
              .collection(chatsCollection)
              .where('participants', arrayContains: normalizedUid)
              .snapshots()
              .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
                chats =
                    snapshot.docs.map(DirectChatThread.fromFirestore).toList()
                      ..sort((DirectChatThread a, DirectChatThread b) {
                        final DateTime first =
                            a.lastMessageAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        final DateTime second =
                            b.lastMessageAt ??
                            DateTime.fromMillisecondsSinceEpoch(0);
                        return second.compareTo(first);
                      });
                emit();
              }, onError: controller.addError),
        );
      },
      onCancel: () async {
        for (final StreamSubscription<dynamic> subscription in subscriptions) {
          await subscription.cancel();
        }
        if (!controller.isClosed) {
          await controller.close();
        }
      },
    );

    return controller.stream;
  }

  Stream<List<DirectChatMessage>> watchMessages(String chatId) {
    final String normalizedChatId = chatId.trim();
    if (!isAvailable || normalizedChatId.isEmpty) {
      return Stream<List<DirectChatMessage>>.value(const <DirectChatMessage>[]);
    }

    return _firestore
        .collection(chatsCollection)
        .doc(normalizedChatId)
        .collection(messagesCollection)
        .orderBy('createdAt')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map(DirectChatMessage.fromFirestore).toList();
        });
  }

  Future<void> sendFriendRequest({
    required String toUid,
    required StudentProfile toProfile,
  }) async {
    final _SignedInContext current = await _requireSignedInContext();
    final String normalizedToUid = toUid.trim();

    if (normalizedToUid.isEmpty) {
      throw Exception('That student is unavailable right now.');
    }
    if (normalizedToUid == current.uid) {
      throw Exception('You cannot send a friend request to yourself.');
    }

    final DocumentReference<Map<String, dynamic>> friendshipRef = _firestore
        .collection(friendshipsCollection)
        .doc(_friendshipId(current.uid, normalizedToUid));

    try {
      if ((await friendshipRef.get()).exists) {
        throw Exception('You are already connected as friends.');
      }

      final DocumentReference<Map<String, dynamic>> outgoingRef = _firestore
          .collection(friendRequestsCollection)
          .doc(_requestId(current.uid, normalizedToUid));
      final DocumentReference<Map<String, dynamic>> incomingRef = _firestore
          .collection(friendRequestsCollection)
          .doc(_requestId(normalizedToUid, current.uid));

      final DocumentSnapshot<Map<String, dynamic>> outgoingSnapshot =
          await outgoingRef.get();
      if (outgoingSnapshot.exists) {
        final FriendRequestRecord outgoingRequest =
            FriendRequestRecord.fromFirestore(outgoingSnapshot);
        if (outgoingRequest.isPending) {
          throw Exception('You already sent a friend request to this student.');
        }
        if (outgoingRequest.isAccepted) {
          throw Exception('You are already connected as friends.');
        }
      }

      final DocumentSnapshot<Map<String, dynamic>> incomingSnapshot =
          await incomingRef.get();
      if (incomingSnapshot.exists) {
        final FriendRequestRecord incomingRequest =
            FriendRequestRecord.fromFirestore(incomingSnapshot);
        if (incomingRequest.isPending) {
          throw Exception(
            '${toProfile.firstName} already sent you a request. Open Friend Requests to accept it.',
          );
        }
        if (incomingRequest.isAccepted) {
          throw Exception('You are already connected as friends.');
        }
      }

      await outgoingRef.set(<String, dynamic>{
        'fromUid': current.uid,
        'fromEmail': current.profile.email,
        'fromName': current.profile.name,
        'toUid': normalizedToUid,
        'toEmail': toProfile.email,
        'toName': toProfile.name,
        'status': FriendRequestRecord.pendingStatus,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _notificationService.createNotification(
        toUid: normalizedToUid,
        type: 'friend_request',
        title: 'New friend request',
        body: '${current.profile.firstName} sent you a campus friend request.',
        relatedId: outgoingRef.id,
        senderUid: current.uid,
        senderName: current.profile.name,
      );
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to send the friend request right now.',
        ),
      );
    }
  }

  Future<void> acceptFriendRequest(FriendRequestRecord request) async {
    final _SignedInContext current = await _requireSignedInContext();
    if (request.toUid != current.uid) {
      throw Exception('This request is no longer available.');
    }

    try {
      final WriteBatch batch = _firestore.batch();
      final DocumentReference<Map<String, dynamic>> requestRef = _firestore
          .collection(friendRequestsCollection)
          .doc(request.id);
      final DocumentReference<Map<String, dynamic>> friendshipRef = _firestore
          .collection(friendshipsCollection)
          .doc(_friendshipId(request.fromUid, request.toUid));

      batch.set(friendshipRef, <String, dynamic>{
        'users': _sortedUsers(request.fromUid, request.toUid),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.update(requestRef, <String, dynamic>{
        'status': FriendRequestRecord.acceptedStatus,
      });

      await batch.commit();
      await _notificationService.createNotification(
        toUid: request.fromUid,
        type: 'friend_accept',
        title: 'Friend request accepted',
        body:
            '${current.profile.firstName} accepted your campus friend request.',
        relatedId: request.id,
        senderUid: current.uid,
        senderName: current.profile.name,
      );
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to accept the friend request right now.',
        ),
      );
    }
  }

  Future<void> rejectFriendRequest(FriendRequestRecord request) async {
    final _SignedInContext current = await _requireSignedInContext();
    if (request.toUid != current.uid) {
      throw Exception('This request is no longer available.');
    }

    try {
      await _firestore
          .collection(friendRequestsCollection)
          .doc(request.id)
          .update(<String, dynamic>{
            'status': FriendRequestRecord.rejectedStatus,
          });
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to reject the friend request right now.',
        ),
      );
    }
  }

  Future<String> ensureDirectChat({
    required String otherUid,
    required StudentProfile otherProfile,
  }) async {
    final _SignedInContext current = await _requireSignedInContext();
    final String normalizedOtherUid = otherUid.trim();

    if (normalizedOtherUid.isEmpty || normalizedOtherUid == current.uid) {
      throw Exception('That chat is unavailable right now.');
    }

    final String chatId = _chatId(current.uid, normalizedOtherUid);
    final DocumentReference<Map<String, dynamic>> chatRef = _firestore
        .collection(chatsCollection)
        .doc(chatId);

    try {
      final DocumentSnapshot<Map<String, dynamic>> chatSnapshot = await chatRef
          .get();
      if (chatSnapshot.exists) {
        return chatId;
      }

      final DocumentSnapshot<Map<String, dynamic>> friendshipSnapshot =
          await _firestore
              .collection(friendshipsCollection)
              .doc(_friendshipId(current.uid, normalizedOtherUid))
              .get();
      if (!friendshipSnapshot.exists) {
        throw Exception(
          'You can start chatting once the friend request is accepted.',
        );
      }

      await chatRef.set(<String, dynamic>{
        'participants': _sortedUsers(current.uid, normalizedOtherUid),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderUid': '',
      }, SetOptions(merge: true));

      return chatId;
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to open the chat with ${otherProfile.firstName}.',
        ),
      );
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final _SignedInContext current = await _requireSignedInContext();
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> chatRef = _firestore
        .collection(chatsCollection)
        .doc(chatId);

    try {
      final DocumentSnapshot<Map<String, dynamic>> chatSnapshot = await chatRef
          .get();
      if (!chatSnapshot.exists) {
        throw Exception('This chat is not ready yet. Please reopen it.');
      }

      final List<String> participants = List<String>.from(
        chatSnapshot.data()?['participants'] as List? ?? const <String>[],
      );
      if (!participants.contains(current.uid)) {
        throw Exception('You do not have access to this chat.');
      }

      final DocumentReference<Map<String, dynamic>> messageRef = chatRef
          .collection(messagesCollection)
          .doc();

      final WriteBatch batch = _firestore.batch();
      batch.set(messageRef, <String, dynamic>{
        'senderUid': current.uid,
        'senderName': current.profile.name,
        'text': trimmedText,
        'createdAt': FieldValue.serverTimestamp(),
        'seenBy': <String>[current.uid],
      });
      batch.set(chatRef, <String, dynamic>{
        'participants': participants,
        'lastMessage': trimmedText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderUid': current.uid,
      }, SetOptions(merge: true));
      await batch.commit();

      final List<String> recipientIds = participants
          .where((String uid) => uid != current.uid)
          .toList();
      await _notificationService.createForUsers(
        userIds: recipientIds,
        type: 'message_activity',
        title: 'New message from ${current.profile.firstName}',
        body: trimmedText,
        relatedId: chatId,
        senderUid: current.uid,
        senderName: current.profile.name,
      );
    } on FirebaseException catch (error) {
      throw Exception(
        _mapFirestoreError(
          error,
          fallback: 'Unable to send the message right now.',
        ),
      );
    }
  }

  Future<void> markChatSeen(String chatId) async {
    final String? currentUid = AuthService.currentUser?.uid;
    if (!isAvailable || currentUid == null || currentUid.isEmpty) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final WriteBatch batch = _firestore.batch();
      int updateCount = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String senderUid = data['senderUid']?.toString() ?? '';
        final List<String> seenBy = List<String>.from(
          data['seenBy'] as List? ?? const <String>[],
        );
        if (senderUid == currentUid || seenBy.contains(currentUid)) {
          continue;
        }
        batch.update(doc.reference, <String, dynamic>{
          'seenBy': FieldValue.arrayUnion(<String>[currentUid]),
        });
        updateCount++;
      }

      if (updateCount > 0) {
        await batch.commit();
      }
    } on FirebaseException {
      // Best-effort only.
    }
  }

  Future<_SignedInContext> _requireSignedInContext() async {
    final String? uid = AuthService.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Please sign in again to continue.');
    }

    final StudentProfile? profile = await AuthService.getProfile();
    if (profile == null || profile.email.isEmpty) {
      throw Exception('We could not load your student profile right now.');
    }

    return _SignedInContext(uid: uid, profile: profile);
  }

  static int _sortByDateDescending(
    FriendRequestRecord first,
    FriendRequestRecord second,
  ) {
    return second.createdAt.compareTo(first.createdAt);
  }

  static String _requestId(String fromUid, String toUid) {
    return 'request_${fromUid}_$toUid';
  }

  static String _friendshipId(String firstUid, String secondUid) {
    return 'friendship_${_pairKey(firstUid, secondUid)}';
  }

  static String _chatId(String firstUid, String secondUid) {
    return 'chat_${_pairKey(firstUid, secondUid)}';
  }

  static String _pairKey(String firstUid, String secondUid) {
    final List<String> users = _sortedUsers(firstUid, secondUid);
    return '${users[0]}_${users[1]}';
  }

  static List<String> _sortedUsers(String firstUid, String secondUid) {
    final List<String> users = <String>[firstUid, secondUid]..sort();
    return users;
  }

  String _mapFirestoreError(
    FirebaseException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to complete that action.';
      case 'unavailable':
        return 'The messaging service is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'That conversation or request is no longer available.';
      default:
        return fallback;
    }
  }
}

class _SignedInContext {
  const _SignedInContext({required this.uid, required this.profile});

  final String uid;
  final StudentProfile profile;
}
