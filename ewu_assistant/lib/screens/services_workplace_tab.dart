import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/services_hub_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../models/workplace_post.dart';

class ServicesWorkplaceTab extends StatefulWidget {
  const ServicesWorkplaceTab({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  State<ServicesWorkplaceTab> createState() => _ServicesWorkplaceTabState();
}

class _ServicesWorkplaceTabState extends State<ServicesWorkplaceTab> {
  final ServicesHubService _servicesHubService = ServicesHubService();

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

  Future<void> _showCreatePostSheet() async {
    final String? uid = AuthService.currentUser?.uid;
    if (uid == null) {
      _showMessage('Please sign in again to add a workplace post.');
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
        return _CreateWorkplaceSheet(
          authorUid: uid,
          servicesHubService: _servicesHubService,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _deletePost(WorkplacePost post) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete Workplace Post?',
      message: 'This will remove "${post.title}" from the workplace board.',
      confirmLabel: 'Delete Post',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _servicesHubService.deleteWorkplacePost(post.id);
      _showMessage('Workplace post removed.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<WorkplacePost> _filterPosts(List<WorkplacePost> posts) {
    final String query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return posts;
    }

    return posts.where((WorkplacePost post) {
      return post.title.toLowerCase().contains(query) ||
          post.organization.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.location.toLowerCase().contains(query) ||
          post.contactInfo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesHubService.isAvailable) {
      return const _ServicesEmptyState(
        icon: Icons.work_outline_rounded,
        title: 'Workplace Needs Firebase',
        description:
            'Complete your Firebase setup to publish internships, jobs, and opportunity posts.',
      );
    }

    return StreamBuilder<List<WorkplacePost>>(
      stream: _servicesHubService.getWorkplacePosts(),
      builder: (BuildContext context, AsyncSnapshot<List<WorkplacePost>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ServicesEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Workplace Hub Unavailable',
            description:
                'We could not load the jobs and internship board right now.',
          );
        }

        final List<WorkplacePost> posts = _filterPosts(
          snapshot.data ?? const <WorkplacePost>[],
        );
        final String? currentUid = AuthService.currentUser?.uid;
        final bool canModerate = AuthService.canModerateContent;

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.premiumCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Workplace board',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
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
                          '${posts.length} posts',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A student-first lane for internships, jobs, campus hiring, and placement-ready leads.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      const _FilterPlaceholderChip(label: 'Internship filters'),
                      const _FilterPlaceholderChip(label: 'Campus roles'),
                      const _FilterPlaceholderChip(label: 'Remote friendly'),
                      if (canModerate) const _AdminModeChip(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _showCreatePostSheet,
                icon: const Icon(Icons.work_history_outlined),
                label: const Text('Post Opportunity'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: posts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 40),
                        children: <Widget>[
                          _ServicesEmptyState(
                            icon: Icons.cases_outlined,
                            title: widget.searchQuery.trim().isEmpty
                                ? 'No Workplace Posts Yet'
                                : 'No Opportunities Match',
                            description: widget.searchQuery.trim().isEmpty
                                ? 'Post the first internship or job lead for EWU students.'
                                : 'Try another keyword to find matching opportunities.',
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
                          final WorkplacePost post = posts[index];
                          final bool canDelete =
                              post.authorUid == currentUid || canModerate;
                          return _WorkplaceCard(
                            post: post,
                            canDelete: canDelete,
                            onDelete: () => _deletePost(post),
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

class _WorkplaceCard extends StatelessWidget {
  const _WorkplaceCard({
    required this.post,
    required this.canDelete,
    required this.onDelete,
  });

  final WorkplacePost post;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: AppTheme.botBubble,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.organization.isEmpty
                          ? 'EWU workplace opportunity'
                          : post.organization,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _MetaPill(
                icon: Icons.place_outlined,
                label: post.location.isEmpty
                    ? 'Location flexible'
                    : post.location,
              ),
              _MetaPill(
                icon: Icons.call_outlined,
                label: post.contactInfo.isEmpty
                    ? 'Contact pending'
                    : post.contactInfo,
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: _formatServicesDate(post.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateWorkplaceSheet extends StatefulWidget {
  const _CreateWorkplaceSheet({
    required this.authorUid,
    required this.servicesHubService,
    required this.onMessage,
  });

  final String authorUid;
  final ServicesHubService servicesHubService;
  final ValueChanged<String> onMessage;

  @override
  State<_CreateWorkplaceSheet> createState() => _CreateWorkplaceSheetState();
}

class _CreateWorkplaceSheetState extends State<_CreateWorkplaceSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String organization = _organizationController.text.trim();
    final String description = _descriptionController.text.trim();
    final String location = _locationController.text.trim();
    final String contactInfo = _contactController.text.trim();

    if (title.isEmpty || description.isEmpty || contactInfo.isEmpty) {
      widget.onMessage('Please add title, details, and contact information.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.servicesHubService.createWorkplacePost(
        WorkplacePost(
          id: '',
          title: title,
          organization: organization,
          description: description,
          location: location,
          contactInfo: contactInfo,
          authorUid: widget.authorUid,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage('Workplace post published.');
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
              'Add Workplace Post',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Software intern, campus ambassador, part-time TA',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText: 'Organization',
                hintText: 'Company, club, department, or campus office',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Dhaka, EWU campus, hybrid, or remote',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact info',
                hintText: 'Email, phone, or application link',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText:
                    'Add role details, expectations, timing, and requirements.',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Publishing...' : 'Publish Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.primaryDark),
          const SizedBox(width: 6),
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

class _FilterPlaceholderChip extends StatelessWidget {
  const _FilterPlaceholderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label soon',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminModeChip extends StatelessWidget {
  const _AdminModeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Admin moderation',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  const _ServicesEmptyState({
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

String _formatServicesDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
