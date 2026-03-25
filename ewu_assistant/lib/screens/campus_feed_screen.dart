import 'package:flutter/material.dart';

import '../models/feed_post.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/feed_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/campus_section_header.dart';
import '../widgets/notification_action_button.dart';
import 'campus_info_screen.dart';
import 'community_items_tab.dart';
import 'gallery_screen.dart';
import 'notices_tab.dart';
import 'routine_tab.dart';

class CampusFeedScreen extends StatefulWidget {
  const CampusFeedScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CampusFeedScreen> createState() => _CampusFeedScreenState();
}

class _CampusFeedScreenState extends State<CampusFeedScreen>
    with SingleTickerProviderStateMixin {
  final FeedService _feedService = FeedService();
  late final TabController _tabController;

  static const List<String> _tabs = <String>[
    'Feed',
    'Gallery',
    'Notices',
    'Community',
    'Routine',
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(
          length: _tabs.length,
          vsync: this,
          initialIndex: widget.initialTab.clamp(0, _tabs.length - 1),
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCreatePostSheet() async {
    final StudentProfile? profile = await AuthService.getProfile();
    if (!mounted) {
      return;
    }
    if (profile == null) {
      _showMessage('Please sign in again to create a post.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return _CreatePostSheet(
          feedService: _feedService,
          profile: profile,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _showRepliesSheet(FeedPost post) async {
    final StudentProfile? profile = await AuthService.getProfile();
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return _RepliesSheet(
          feedService: _feedService,
          post: post,
          profile: profile,
          dateFormatter: _formatDateTime,
          onMessage: _showMessage,
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshFeed() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<bool> _confirmDeletePost(FeedPost post) {
    return showAppConfirmationDialog(
      context,
      title: 'Delete Post?',
      message:
          'This will remove "${post.title}" from the campus feed and delete its replies.',
      confirmLabel: 'Delete Post',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreatePostSheet,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Share Post'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CampusSectionHeader(
                  title: 'Community Hub',
                  subtitle:
                      'Feed, gallery, notices, clubs, and routine spaces built for student life.',
                  actions: <Widget>[
                    NotificationActionButton(),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<CampusInfoScreen>(
                            builder: (_) => const CampusInfoScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.botBubble,
                        foregroundColor: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const <Widget>[
                    _HubMetricCard(
                      title: '5 sections',
                      subtitle: 'Feed to routine',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                    _HubMetricCard(
                      title: 'Live now',
                      subtitle: 'All 5 lanes',
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryDark.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textPrimary,
                    tabs: _tabs.map((String tab) => Tab(text: tab)).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildFeedTab(),
                      const GalleryScreen(embedded: true),
                      _buildNoticesTab(),
                      _buildCommunityTab(),
                      _buildRoutineTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    if (!_feedService.isAvailable) {
      return const _CommunityPlaceholder(
        title: 'Campus Feed Needs Firebase',
        description:
            'Complete your Firebase setup to enable real-time campus posts and replies.',
        icon: Icons.groups_rounded,
      );
    }

    return StreamBuilder<List<FeedPost>>(
      stream: _feedService.getPosts(),
      builder: (BuildContext context, AsyncSnapshot<List<FeedPost>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _CommunityPlaceholder(
            title: 'Unable To Load Feed',
            description:
                'Please check your Firebase configuration and try again.',
            icon: Icons.error_outline_rounded,
          );
        }

        final List<FeedPost> posts = snapshot.data ?? const <FeedPost>[];
        final String currentEmail =
            AuthService.currentUser?.email?.toLowerCase() ?? '';
        final bool canModerate = AuthService.canModerateContent;

        return RefreshIndicator(
          onRefresh: _refreshFeed,
          child: posts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 48),
                  children: const <Widget>[
                    _CommunityPlaceholder(
                      title: 'No Posts Yet',
                      description:
                          'Create the first campus post and start the conversation.',
                      icon: Icons.forum_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: posts.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (BuildContext context, int index) {
                    final FeedPost post = posts[index];
                    final bool isOwner =
                        currentEmail == post.authorEmail.toLowerCase();
                    final bool canDelete = isOwner || canModerate;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.premiumCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryDark,
                                backgroundImage: post.authorPhotoUrl.isNotEmpty
                                    ? NetworkImage(post.authorPhotoUrl)
                                    : null,
                                child: post.authorPhotoUrl.isEmpty
                                    ? Text(
                                        post.authorName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          post.authorName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (post.authorRole !=
                                            StudentProfile.userRole)
                                          _FeedRoleBadge(role: post.authorRole),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${post.displayHandle} | ${_formatDateTime(post.timestamp)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.botBubble,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      FeedPost.categoryIcons[post.category] ??
                                          Icons.campaign_outlined,
                                      size: 16,
                                      color: AppTheme.primaryDark,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(post.category),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            post.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post.body,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () async {
                                  try {
                                    await _feedService.toggleLike(
                                      post.id,
                                      currentEmail,
                                    );
                                  } catch (error) {
                                    _showMessage(
                                      error.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.favorite_border_rounded),
                                label: Text('${post.likes}'),
                              ),
                              TextButton.icon(
                                onPressed: () => _showRepliesSheet(post),
                                icon: const Icon(Icons.reply_outlined),
                                label: Text('${post.replyCount}'),
                              ),
                              const Spacer(),
                              if (canDelete)
                                IconButton(
                                  onPressed: () async {
                                    final bool confirmed =
                                        await _confirmDeletePost(post);
                                    if (!confirmed) {
                                      return;
                                    }
                                    try {
                                      await _feedService.deletePost(post.id);
                                      _showMessage('Post deleted.');
                                    } catch (error) {
                                      _showMessage(
                                        error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildNoticesTab() {
    return const NoticesTabView();
  }

  Widget _buildCommunityTab() {
    return const CommunityItemsTabView();
  }

  Widget _buildRoutineTab() {
    return const RoutineTabView();
  }

  String _formatDateTime(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String hour = local.hour > 12
        ? (local.hour - 12).toString()
        : (local.hour == 0 ? '12' : local.hour.toString());
    final String minute = local.minute.toString().padLeft(2, '0');
    final String suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} | $hour:$minute $suffix';
  }
}

class _HubMetricCard extends StatelessWidget {
  const _HubMetricCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.premiumCard,
        child: Row(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppTheme.botBubble,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

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
              child: Icon(icon, color: AppTheme.primaryDark, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.feedService,
    required this.profile,
    required this.onMessage,
  });

  final FeedService feedService;
  final StudentProfile profile;
  final ValueChanged<String> onMessage;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedCategory = FeedPost.categories.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      widget.onMessage('Please add both a title and details.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.feedService.createPost(
        FeedPost(
          id: '',
          authorName: widget.profile.name,
          authorEmail: widget.profile.email,
          authorStudentId: widget.profile.studentId,
          authorPhotoUrl: widget.profile.photoUrl,
          authorRole: widget.profile.role,
          category: _selectedCategory,
          title: title,
          body: body,
          timestamp: DateTime.now(),
          likes: 0,
          likedBy: const <String>[],
          replyCount: 0,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage('Post published.');
    } catch (error) {
      widget.onMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Create Campus Post',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: FeedPost.categories
                  .map(
                    (String category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to share?',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Post details',
                hintText: 'Write your message for the campus community.',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Posting...' : 'Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedRoleBadge extends StatelessWidget {
  const _FeedRoleBadge({required this.role});

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

class _RepliesSheet extends StatefulWidget {
  const _RepliesSheet({
    required this.feedService,
    required this.post,
    required this.profile,
    required this.dateFormatter,
    required this.onMessage,
  });

  final FeedService feedService;
  final FeedPost post;
  final StudentProfile? profile;
  final String Function(DateTime dateTime) dateFormatter;
  final ValueChanged<String> onMessage;

  @override
  State<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends State<_RepliesSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final StudentProfile? profile = widget.profile;
    final String body = _replyController.text.trim();
    if (profile == null || body.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.feedService.addReply(
        widget.post.id,
        PostReply(
          id: '',
          authorName: profile.name,
          authorEmail: profile.email,
          authorStudentId: profile.studentId,
          authorPhotoUrl: profile.photoUrl,
          body: body,
          timestamp: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      _replyController.clear();
    } catch (error) {
      widget.onMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.84,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Replies',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              widget.post.title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<PostReply>>(
                stream: widget.feedService.getReplies(widget.post.id),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<PostReply>> snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Replies are unavailable right now.'),
                        );
                      }
                      final List<PostReply> replies =
                          snapshot.data ?? const <PostReply>[];
                      if (replies.isEmpty) {
                        return const Center(
                          child: Text(
                            'No replies yet. Be the first student to reply.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: replies.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final PostReply reply = replies[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.botBubble,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  reply.authorName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(reply.body),
                                const SizedBox(height: 8),
                                Text(
                                  widget.dateFormatter(reply.timestamp),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a reply...',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.profile == null || _isSubmitting
                      ? null
                      : _submitReply,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
