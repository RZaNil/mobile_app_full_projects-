import 'package:flutter/material.dart';

import '../models/direct_chat.dart';
import '../models/friend_request.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_section_header.dart';
import '../widgets/notification_action_button.dart';
import 'direct_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const List<String> _sections = <String>[
    'All Users',
    'Friend Requests',
    'Friends',
    'Chats',
  ];

  final SocialService _socialService = SocialService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendFriendRequest(UserDirectoryRecord user) async {
    try {
      await _socialService.sendFriendRequest(
        toUid: user.uid,
        toProfile: user.profile,
      );
      _showMessage('Friend request sent to ${user.profile.firstName}.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _acceptRequest(FriendRequestRecord request) async {
    try {
      await _socialService.acceptFriendRequest(request);
      _showMessage('Friend request accepted.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rejectRequest(FriendRequestRecord request) async {
    try {
      await _socialService.rejectFriendRequest(request);
      _showMessage('Friend request rejected.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openChat(UserDirectoryRecord user) async {
    try {
      final String chatId = await _socialService.ensureDirectChat(
        otherUid: user.uid,
        otherProfile: user.profile,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<DirectChatScreen>(
          builder: (_) => DirectChatScreen(
            chatId: chatId,
            otherUser: user,
            socialService: _socialService,
          ),
        ),
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showCallPlaceholder() {
    _showMessage(
      'Campus calling will be added in a future pass. For now, start a chat to stay connected.',
    );
  }

  void _jumpToRequests() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = AuthService.currentUser?.uid ?? '';
    if (currentUid.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.pageTint,
        body: _MessagesPlaceholder(
          icon: Icons.lock_outline_rounded,
          title: 'Sign In To Open Messages',
          description:
              'Please sign in again so we can load your campus social workspace.',
        ),
      );
    }

    return StreamBuilder<MessagesDashboardData>(
      stream: _socialService.watchDashboard(currentUid),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<MessagesDashboardData> snapshot,
          ) {
            final MessagesDashboardData dashboard =
                snapshot.data ??
                MessagesDashboardData.empty(currentUid: currentUid);

            return _MessagesScaffold(
              selectedIndex: _selectedIndex,
              onSectionChanged: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              searchController: _searchController,
              totalUsers: dashboard.users.length,
              pendingRequestsCount: dashboard.pendingIncomingRequests.length,
              friendsCount: dashboard.friendships.length,
              chatsCount: dashboard.chats.length,
              child: _buildSectionContent(
                dashboard: dashboard,
                snapshot: snapshot,
              ),
            );
          },
    );
  }

  Widget _buildSectionContent({
    required MessagesDashboardData dashboard,
    required AsyncSnapshot<MessagesDashboardData> snapshot,
  }) {
    final String query = _searchController.text.trim().toLowerCase();

    switch (_selectedIndex) {
      case 0:
        if (snapshot.connectionState == ConnectionState.waiting &&
            dashboard.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _MessagesPlaceholder(
            icon: Icons.error_outline_rounded,
            title: 'Users Unavailable',
            description:
                'We could not load the student directory right now. Please try again in a moment.',
          );
        }

        final List<UserDirectoryRecord> filteredUsers = dashboard.directoryUsers
            .where(
              (UserDirectoryRecord record) =>
                  _matchesProfile(record.profile, query),
            )
            .toList();

        if (dashboard.directoryUsers.isEmpty && query.isEmpty) {
          return const _MessagesPlaceholder(
            icon: Icons.groups_outlined,
            title: 'Campus Directory Is Getting Started',
            description:
                'Once more EWU students sign in, you will be able to send requests and open direct chats from here.',
          );
        }

        if (filteredUsers.isEmpty) {
          return _MessagesPlaceholder(
            icon: Icons.person_search_outlined,
            title: query.isEmpty
                ? 'No Classmates Available Yet'
                : 'No Users Found',
            description: query.isEmpty
                ? 'Student profiles will appear here as more users join EWU Assistant.'
                : 'Try another search term or clear the filter to explore the directory again.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: filteredUsers.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final UserDirectoryRecord user = filteredUsers[index];
            final bool isFriend = dashboard.isFriendWith(user.uid);
            final FriendRequestRecord? outgoingRequest = dashboard
                .outgoingRequestTo(user.uid);
            final FriendRequestRecord? incomingRequest = dashboard
                .incomingRequestFrom(user.uid);

            return _DirectoryUserCard(
              user: user,
              isFriend: isFriend,
              outgoingRequest: outgoingRequest,
              incomingRequest: incomingRequest,
              onSendRequest: () => _sendFriendRequest(user),
              onOpenChat: () => _openChat(user),
              onRespond: _jumpToRequests,
              onCall: _showCallPlaceholder,
            );
          },
        );
      case 1:
        final List<FriendRequestRecord> filteredRequests = dashboard
            .pendingIncomingRequests
            .where((FriendRequestRecord request) {
              return _matchesFriendRequest(
                request: request,
                query: query,
                dashboard: dashboard,
              );
            })
            .toList();

        if (filteredRequests.isEmpty) {
          return const _MessagesPlaceholder(
            icon: Icons.person_add_alt_1_outlined,
            title: 'No Incoming Requests',
            description:
                'Incoming friend requests will appear here when other students connect with you.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: filteredRequests.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final FriendRequestRecord request = filteredRequests[index];
            final UserDirectoryRecord? user = dashboard.userForId(
              request.fromUid,
            );
            return _FriendRequestCard(
              request: request,
              user: user,
              onAccept: () => _acceptRequest(request),
              onReject: () => _rejectRequest(request),
            );
          },
        );
      case 2:
        final List<UserDirectoryRecord> friends = dashboard.friendUsers().where(
          (UserDirectoryRecord record) {
            return _matchesProfile(record.profile, query);
          },
        ).toList();

        if (friends.isEmpty) {
          return const _MessagesPlaceholder(
            icon: Icons.people_alt_outlined,
            title: 'No Friends Yet',
            description:
                'Accept requests to build your campus circle, then start direct chats from here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: friends.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final UserDirectoryRecord friend = friends[index];
            return _FriendCard(
              user: friend,
              chat: dashboard.chatWith(friend.uid),
              onStartChat: () => _openChat(friend),
              onCall: _showCallPlaceholder,
            );
          },
        );
      case 3:
        final List<_ResolvedChatItem> chats = dashboard.chats
            .map(
              (DirectChatThread chat) => _ResolvedChatItem(
                chat: chat,
                user: dashboard.userForId(
                  chat.otherParticipantId(dashboard.currentUid) ?? '',
                ),
              ),
            )
            .where((_ResolvedChatItem item) {
              return _matchesChatItem(item, query);
            })
            .toList();

        if (chats.isEmpty) {
          return const _MessagesPlaceholder(
            icon: Icons.mark_chat_unread_outlined,
            title: 'No Chats Yet',
            description:
                'Start a conversation with a friend and your direct chat list will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: chats.length,
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 14),
          itemBuilder: (BuildContext context, int index) {
            final _ResolvedChatItem item = chats[index];
            return _ChatPreviewCard(
              item: item,
              onTap: item.user == null ? null : () => _openChat(item.user!),
              onCall: _showCallPlaceholder,
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static bool _matchesProfile(StudentProfile profile, String query) {
    if (query.isEmpty) {
      return true;
    }
    return profile.name.toLowerCase().contains(query) ||
        profile.email.toLowerCase().contains(query) ||
        profile.studentId.toLowerCase().contains(query) ||
        profile.department.toLowerCase().contains(query);
  }

  static bool _matchesFriendRequest({
    required FriendRequestRecord request,
    required String query,
    required MessagesDashboardData dashboard,
  }) {
    if (query.isEmpty) {
      return true;
    }
    final UserDirectoryRecord? user = dashboard.userForId(request.fromUid);
    final StudentProfile? profile = user?.profile;
    return request.fromName.toLowerCase().contains(query) ||
        request.fromEmail.toLowerCase().contains(query) ||
        (profile?.studentId.toLowerCase().contains(query) ?? false);
  }

  static bool _matchesChatItem(_ResolvedChatItem item, String query) {
    if (query.isEmpty) {
      return true;
    }
    final StudentProfile? profile = item.user?.profile;
    return (profile?.name.toLowerCase().contains(query) ?? false) ||
        (profile?.email.toLowerCase().contains(query) ?? false) ||
        (profile?.studentId.toLowerCase().contains(query) ?? false) ||
        item.chat.lastMessage.toLowerCase().contains(query);
  }
}

class _MessagesScaffold extends StatelessWidget {
  const _MessagesScaffold({
    required this.selectedIndex,
    required this.onSectionChanged,
    required this.searchController,
    required this.totalUsers,
    required this.pendingRequestsCount,
    required this.friendsCount,
    required this.chatsCount,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSectionChanged;
  final TextEditingController searchController;
  final int totalUsers;
  final int pendingRequestsCount;
  final int friendsCount;
  final int chatsCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int availableUsersCount = totalUsers > 0 ? totalUsers - 1 : 0;

    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CampusSectionHeader(
                  title: 'Messages',
                  subtitle:
                      'Campus messaging, friend requests, and direct chats in one polished space.',
                  actions: <Widget>[NotificationActionButton()],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.premiumCard,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool compact = constraints.maxWidth < 380;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                  color: AppTheme.botBubble,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _summaryIcon(selectedIndex),
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _summaryTitle(
                                        selectedIndex,
                                        availableUsersCount:
                                            availableUsersCount,
                                        pendingRequestsCount:
                                            pendingRequestsCount,
                                        friendsCount: friendsCount,
                                        chatsCount: chatsCount,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _summaryDescription(selectedIndex),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _MetricChip(
                                icon: Icons.person_add_alt_1_outlined,
                                label: '$pendingRequestsCount pending requests',
                              ),
                              _MetricChip(
                                icon: Icons.people_alt_outlined,
                                label: '$friendsCount friends',
                              ),
                              _MetricChip(
                                icon: Icons.mark_chat_unread_outlined,
                                label: '$chatsCount chats',
                              ),
                              if (!compact)
                                _MetricChip(
                                  icon: Icons.badge_outlined,
                                  label: '$totalUsers total users',
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: (_) => onSectionChanged(selectedIndex),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or student ID',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              searchController.clear();
                              onSectionChanged(selectedIndex);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List<Widget>.generate(
                      _MessagesScreenState._sections.length,
                      (int index) {
                        final bool selected = selectedIndex == index;
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index ==
                                    _MessagesScreenState._sections.length - 1
                                ? 0
                                : 10,
                          ),
                          child: _MessageSectionTab(
                            title: _sectionTitle(index),
                            count: _sectionCount(
                              index,
                              totalUsers: availableUsersCount,
                              pendingRequestsCount: pendingRequestsCount,
                              friendsCount: friendsCount,
                              chatsCount: chatsCount,
                            ),
                            selected: selected,
                            onTap: () => onSectionChanged(index),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: ClipRect(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sectionTitle(int index) {
    return _MessagesScreenState._sections[index];
  }

  int? _sectionCount(
    int index, {
    required int totalUsers,
    required int pendingRequestsCount,
    required int friendsCount,
    required int chatsCount,
  }) {
    switch (index) {
      case 0:
        return totalUsers;
      case 1:
        return pendingRequestsCount;
      case 2:
        return friendsCount;
      case 3:
        return chatsCount;
      default:
        return null;
    }
  }

  IconData _summaryIcon(int index) {
    switch (index) {
      case 1:
        return Icons.person_add_alt_1_rounded;
      case 2:
        return Icons.people_alt_rounded;
      case 3:
        return Icons.forum_rounded;
      default:
        return Icons.people_alt_rounded;
    }
  }

  String _summaryTitle(
    int index, {
    required int availableUsersCount,
    required int pendingRequestsCount,
    required int friendsCount,
    required int chatsCount,
  }) {
    switch (index) {
      case 1:
        return pendingRequestsCount > 0
            ? '$pendingRequestsCount incoming requests'
            : 'No incoming requests';
      case 2:
        return friendsCount > 0
            ? '$friendsCount campus friends'
            : 'Build your campus circle';
      case 3:
        return chatsCount > 0 ? '$chatsCount active chats' : 'Your chat list';
      default:
        return availableUsersCount > 0
            ? '$availableUsersCount classmates available'
            : 'Campus directory';
    }
  }

  String _summaryDescription(int index) {
    switch (index) {
      case 1:
        return 'Review student requests, accept the right connections, and grow your network thoughtfully.';
      case 2:
        return 'Keep your accepted friends close, start chats quickly, and stay ready for future calling tools.';
      case 3:
        return 'Recent conversations stay here so you can jump back into campus chats without searching around.';
      default:
        return 'Search the student directory, send requests, and open polished direct chats from one place.';
    }
  }
}

class _MessageSectionTab extends StatelessWidget {
  const _MessageSectionTab({
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryDark.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count != null) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.botBubble,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? Colors.white : AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectoryUserCard extends StatelessWidget {
  const _DirectoryUserCard({
    required this.user,
    required this.isFriend,
    required this.outgoingRequest,
    required this.incomingRequest,
    required this.onSendRequest,
    required this.onOpenChat,
    required this.onRespond,
    required this.onCall,
  });

  final UserDirectoryRecord user;
  final bool isFriend;
  final FriendRequestRecord? outgoingRequest;
  final FriendRequestRecord? incomingRequest;
  final VoidCallback onSendRequest;
  final VoidCallback onOpenChat;
  final VoidCallback onRespond;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final StudentProfile profile = user.profile;
    final String subtitle = profile.studentId.isEmpty
        ? profile.department
        : '${profile.studentId} | ${profile.department}';
    final bool hasIncomingPending = incomingRequest?.isPending == true;
    final bool hasOutgoingPending = outgoingRequest?.isPending == true;
    final bool wasRejected = outgoingRequest?.isRejected == true;

    final String statusLabel = isFriend
        ? 'Friends'
        : hasIncomingPending
        ? 'Incoming'
        : hasOutgoingPending
        ? 'Pending'
        : wasRejected
        ? 'Send Again'
        : 'Student';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryDark,
                backgroundImage: profile.photoUrl.isNotEmpty
                    ? NetworkImage(profile.photoUrl)
                    : null,
                child: profile.photoUrl.isEmpty
                    ? Text(
                        profile.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (profile.role != StudentProfile.userRole)
                          _RoleBadge(role: profile.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _StatusChip(label: statusLabel),
              if (isFriend)
                const _HintChip(
                  icon: Icons.mark_chat_unread_outlined,
                  label: 'Chat ready',
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 360;
              final Widget actionButton = OutlinedButton.icon(
                onPressed: isFriend
                    ? onOpenChat
                    : hasOutgoingPending
                    ? null
                    : hasIncomingPending
                    ? onRespond
                    : onSendRequest,
                icon: Icon(
                  isFriend
                      ? Icons.chat_bubble_outline_rounded
                      : hasIncomingPending
                      ? Icons.reply_rounded
                      : Icons.person_add_alt_1_outlined,
                ),
                label: Text(
                  isFriend
                      ? 'Open Chat'
                      : hasOutgoingPending
                      ? 'Pending'
                      : hasIncomingPending
                      ? 'Respond'
                      : wasRejected
                      ? 'Send Again'
                      : 'Send Request',
                ),
              );
              final Widget callButton = IconButton.filledTonal(
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.botBubble,
                  foregroundColor: AppTheme.primaryDark,
                ),
              );

              if (compact) {
                return Column(
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: actionButton),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: callButton),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: actionButton),
                  const SizedBox(width: 10),
                  callButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.request,
    required this.user,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequestRecord request;
  final UserDirectoryRecord? user;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final StudentProfile? profile = user?.profile;
    final String name = profile?.name ?? request.fromName;
    final String email = profile?.email ?? request.fromEmail;
    final String subtitle = profile == null
        ? 'Campus student'
        : (profile.studentId.isEmpty
              ? profile.department
              : '${profile.studentId} | ${profile.department}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryDark,
                backgroundImage: profile?.photoUrl.isNotEmpty == true
                    ? NetworkImage(profile!.photoUrl)
                    : null,
                child: profile?.photoUrl.isEmpty != false
                    ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (profile?.role != null &&
                            profile!.role != StudentProfile.userRole)
                          _RoleBadge(role: profile.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const _HintChip(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Pending request',
              ),
              _HintChip(
                icon: Icons.schedule_rounded,
                label: _formatDateTime(request.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 360;
              final Widget acceptButton = ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Accept'),
              );
              final Widget rejectButton = OutlinedButton.icon(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
              );

              if (compact) {
                return Column(
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: acceptButton),
                    const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: rejectButton),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: acceptButton),
                  const SizedBox(width: 10),
                  Expanded(child: rejectButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.user,
    required this.chat,
    required this.onStartChat,
    required this.onCall,
  });

  final UserDirectoryRecord user;
  final DirectChatThread? chat;
  final VoidCallback onStartChat;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final StudentProfile profile = user.profile;
    final String subtitle = profile.studentId.isEmpty
        ? profile.department
        : '${profile.studentId} | ${profile.department}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryDark,
                backgroundImage: profile.photoUrl.isNotEmpty
                    ? NetworkImage(profile.photoUrl)
                    : null,
                child: profile.photoUrl.isEmpty
                    ? Text(
                        profile.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (profile.role != StudentProfile.userRole)
                          _RoleBadge(role: profile.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chat?.lastMessage.isNotEmpty == true
                          ? chat!.lastMessage
                          : 'Ready to start your first direct conversation.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _HintChip(
            icon: Icons.mark_chat_unread_outlined,
            label: 'Chat ready',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 360;
              final Widget chatButton = ElevatedButton.icon(
                onPressed: onStartChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Start Chat'),
              );
              final Widget callButton = IconButton.filledTonal(
                onPressed: onCall,
                icon: const Icon(Icons.call_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.botBubble,
                  foregroundColor: AppTheme.primaryDark,
                ),
              );

              if (compact) {
                return Column(
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: chatButton),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: callButton),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: chatButton),
                  const SizedBox(width: 10),
                  callButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatPreviewCard extends StatelessWidget {
  const _ChatPreviewCard({
    required this.item,
    required this.onTap,
    required this.onCall,
  });

  final _ResolvedChatItem item;
  final VoidCallback? onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final StudentProfile? profile = item.user?.profile;
    final String title = profile?.name ?? 'Campus Chat';
    final String subtitle = profile == null
        ? 'Participant unavailable'
        : (profile.studentId.isEmpty
              ? profile.department
              : '${profile.studentId} | ${profile.department}');
    final String preview = item.chat.lastMessage.isEmpty
        ? 'Say hello to start the conversation.'
        : item.chat.lastMessage;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.premiumCard,
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryDark,
              backgroundImage: profile?.photoUrl.isNotEmpty == true
                  ? NetworkImage(profile!.photoUrl)
                  : null,
              child: profile?.photoUrl.isEmpty != false
                  ? Text(
                      title.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatDateTime(
                          item.chat.lastMessageAt ?? DateTime.now(),
                          compact: true,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: <Widget>[
                const _UnreadBadge(label: '0 new'),
                const SizedBox(height: 10),
                IconButton.filledTonal(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.botBubble,
                    foregroundColor: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedChatItem {
  const _ResolvedChatItem({required this.chat, required this.user});

  final DirectChatThread chat;
  final UserDirectoryRecord? user;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.primaryDark),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdmin = role == StudentProfile.superAdminRole;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSuperAdmin ? AppTheme.primaryDark : AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isSuperAdmin ? 'Super Admin' : 'Admin',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSuperAdmin ? Colors.white : AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessagesPlaceholder extends StatelessWidget {
  const _MessagesPlaceholder({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.premiumCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                color: AppTheme.botBubble,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppTheme.primaryDark, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime, {bool compact = false}) {
  final DateTime local = dateTime.toLocal();
  final DateTime now = DateTime.now();
  final bool isToday =
      now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;
  final String minute = local.minute.toString().padLeft(2, '0');
  final int rawHour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String suffix = local.hour >= 12 ? 'PM' : 'AM';
  if (compact) {
    return isToday ? '$rawHour:$minute $suffix' : '${local.day}/${local.month}';
  }
  return isToday
      ? 'today at $rawHour:$minute $suffix'
      : '${local.day}/${local.month}/${local.year}';
}
