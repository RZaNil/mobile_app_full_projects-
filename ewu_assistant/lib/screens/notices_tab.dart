import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/notice_item.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';

class NoticesTabView extends StatefulWidget {
  const NoticesTabView({super.key});

  @override
  State<NoticesTabView> createState() => _NoticesTabViewState();
}

class _NoticesTabViewState extends State<NoticesTabView> {
  final CommunityService _communityService = CommunityService();

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCreateNoticeSheet() async {
    final StudentProfile? profile = await AuthService.getProfile();
    final String? uid = AuthService.currentUser?.uid;
    if (!mounted) {
      return;
    }

    if (uid == null || profile == null || !profile.canModerateContent) {
      _showMessage('Only admins can publish official notices.');
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
        return _NoticeComposerSheet(
          authorUid: uid,
          profile: profile,
          communityService: _communityService,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _deleteNotice(NoticeItem notice) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete Notice?',
      message:
          'This will remove "${notice.title}" from the official notices lane.',
      confirmLabel: 'Delete Notice',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _communityService.deleteNotice(notice.id);
      _showMessage('Notice deleted.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showNoticeDetail(NoticeItem notice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Official Notice',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _NoticeRoleBadge(role: notice.authorRole),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notice.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${notice.authorName} | ${_formatNoticeDate(notice.createdAt)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (notice.imageUrl.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      notice.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => Container(
                            height: 220,
                            color: AppTheme.botBubble,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  notice.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreate = AuthService.canModerateContent;

    if (!_communityService.isAvailable) {
      return const _NoticeEmptyState(
        icon: Icons.notifications_active_outlined,
        title: 'Notices Need Firebase',
        description:
            'Complete your Firebase setup to publish and read official campus notices.',
      );
    }

    return StreamBuilder<List<NoticeItem>>(
      stream: _communityService.getNotices(),
      builder: (BuildContext context, AsyncSnapshot<List<NoticeItem>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _NoticeEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Notices Unavailable',
            description:
                'We could not load official notices right now. Please try again in a moment.',
          );
        }

        final List<NoticeItem> notices = snapshot.data ?? const <NoticeItem>[];

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.premiumCard,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Official announcements',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          canCreate
                              ? 'Publish important updates for students, departments, and campus events.'
                              : 'Stay updated with official campus notices, deadlines, and announcements.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.botBubble,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${notices.length} live',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (canCreate)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _showCreateNoticeSheet,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('New Notice'),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: notices.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 56),
                        children: <Widget>[
                          _NoticeEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'No Notices Yet',
                            description: canCreate
                                ? 'Publish the first official notice to share important student updates.'
                                : 'Official university announcements will appear here as soon as admins publish them.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: notices.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int index) {
                          final NoticeItem notice = notices[index];
                          return _NoticeCard(
                            notice: notice,
                            canDelete: canCreate,
                            onTap: () => _showNoticeDetail(notice),
                            onDelete: () => _deleteNotice(notice),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final NoticeItem notice;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.premiumCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.botBubble,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _NoticeRoleBadge(role: notice.authorRole),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${notice.authorName} | ${_formatNoticeDate(notice.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (notice.imageUrl.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  notice.imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) => Container(
                        height: 190,
                        color: AppTheme.botBubble,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              notice.body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to read more',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeComposerSheet extends StatefulWidget {
  const _NoticeComposerSheet({
    required this.authorUid,
    required this.profile,
    required this.communityService,
    required this.onMessage,
  });

  final String authorUid;
  final StudentProfile profile;
  final CommunityService communityService;
  final ValueChanged<String> onMessage;

  @override
  State<_NoticeComposerSheet> createState() => _NoticeComposerSheetState();
}

class _NoticeComposerSheetState extends State<_NoticeComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  String _imageUrl = '';
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploadingImage) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (file == null) {
        return;
      }

      final String uploadedUrl = await _cloudinaryService.uploadImage(
        File(file.path),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _imageUrl = uploadedUrl;
      });
    } catch (error) {
      widget.onMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      widget.onMessage('Please add both a title and the notice details.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.communityService.createNotice(
        NoticeItem(
          id: '',
          title: title,
          body: body,
          imageUrl: _imageUrl,
          authorUid: widget.authorUid,
          authorName: widget.profile.name,
          authorRole: widget.profile.role,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage('Notice published.');
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Publish Notice',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText:
                    'Semester fee update, exam alert, or club fair notice',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Notice details',
                hintText: 'Add the full announcement text for students.',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.botBubble,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Optional image',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Attach a visual notice, poster, or announcement banner.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_imageUrl.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _imageUrl,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _isUploadingImage
                          ? null
                          : () {
                              setState(() {
                                _imageUrl = '';
                              });
                            },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove image'),
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingImage
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingImage
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                              _isUploadingImage ? 'Uploading...' : 'Gallery',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _isUploadingImage ? null : _submit,
                child: Text(_isSubmitting ? 'Publishing...' : 'Publish Notice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRoleBadge extends StatelessWidget {
  const _NoticeRoleBadge({required this.role});

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

class _NoticeEmptyState extends StatelessWidget {
  const _NoticeEmptyState({
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

String _formatNoticeDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
