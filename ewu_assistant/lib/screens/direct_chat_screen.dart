import 'dart:async';

import 'package:flutter/material.dart';

import '../models/direct_chat.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/social_service.dart';
import '../theme/app_theme.dart';

class DirectChatScreen extends StatefulWidget {
  DirectChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
    SocialService? socialService,
  }) : socialService = socialService ?? SocialService();

  final String chatId;
  final UserDirectoryRecord otherUser;
  final SocialService socialService;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSending = false;
  int _lastMessageCount = 0;

  String get _currentUid => AuthService.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(widget.socialService.markChatSeen(widget.chatId));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.socialService.sendMessage(chatId: widget.chatId, text: text);
      if (!mounted) {
        return;
      }
      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _showCallPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campus calling is ready for a future feature pass.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudentProfile profile = widget.otherUser.profile;

    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    profile.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          profile.studentId.isEmpty
                              ? profile.department
                              : '${profile.studentId} | ${profile.department}',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                      ),
                      if (profile.role != StudentProfile.userRole) ...<Widget>[
                        const SizedBox(width: 8),
                        _RoleBadge(role: profile.role),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _showCallPlaceholder,
            icon: const Icon(Icons.call_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Expanded(
                child: StreamBuilder<List<DirectChatMessage>>(
                  stream: widget.socialService.watchMessages(widget.chatId),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<DirectChatMessage>> snapshot,
                      ) {
                        if (snapshot.hasError) {
                          return const _ChatStateCard(
                            icon: Icons.error_outline_rounded,
                            title: 'Chat Unavailable',
                            description:
                                'We could not load this conversation right now. Please try again in a moment.',
                          );
                        }

                        final List<DirectChatMessage> messages =
                            snapshot.data ?? const <DirectChatMessage>[];

                        if (_lastMessageCount != messages.length) {
                          _lastMessageCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) {
                              return;
                            }
                            _scrollToBottom();
                            unawaited(
                              widget.socialService.markChatSeen(widget.chatId),
                            );
                          });
                        }

                        if (messages.isEmpty &&
                            snapshot.connectionState !=
                                ConnectionState.waiting) {
                          return _ChatStateCard(
                            icon: Icons.mark_chat_read_outlined,
                            title: 'Start The Conversation',
                            description:
                                'Send the first message to ${profile.firstName} and begin your campus chat.',
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          itemCount: messages.length,
                          itemBuilder: (BuildContext context, int index) {
                            final DirectChatMessage message = messages[index];
                            final bool isMine =
                                message.senderUid == _currentUid;
                            return _MessageBubble(
                              message: message,
                              isMine: isMine,
                              showName: !isMine,
                            );
                          },
                        );
                      },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.primaryDark.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Write a message...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showName,
  });

  final DirectChatMessage message;
  final bool isMine;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final Alignment alignment = isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final Color backgroundColor = isMine
        ? AppTheme.userBubble
        : AppTheme.botBubble;
    final Color foregroundColor = isMine ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                if (showName) ...<Widget>[
                  Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foregroundColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foregroundColor.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final bool isToday =
        DateTime.now().difference(local).inDays == 0 &&
        DateTime.now().day == local.day;
    final String minute = local.minute.toString().padLeft(2, '0');
    final int rawHour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String suffix = local.hour >= 12 ? 'PM' : 'AM';
    return isToday
        ? '$rawHour:$minute $suffix'
        : '${local.day}/${local.month} $rawHour:$minute $suffix';
  }
}

class _ChatStateCard extends StatelessWidget {
  const _ChatStateCard({
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
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final String label = role == StudentProfile.superAdminRole
        ? 'Super'
        : 'Admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
