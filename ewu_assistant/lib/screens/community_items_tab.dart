import 'package:flutter/material.dart';

import '../models/community_item.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';

class CommunityItemsTabView extends StatefulWidget {
  const CommunityItemsTabView({super.key});

  @override
  State<CommunityItemsTabView> createState() => _CommunityItemsTabViewState();
}

class _CommunityItemsTabViewState extends State<CommunityItemsTabView> {
  final CommunityService _communityService = CommunityService();

  String _selectedType = CommunityItem.eventType;

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

  Future<void> _showComposerSheet({CommunityItem? existingItem}) async {
    final StudentProfile? profile = await AuthService.getProfile();
    final String? uid = AuthService.currentUser?.uid;
    if (!mounted) {
      return;
    }

    if (uid == null || profile == null) {
      _showMessage('Please sign in again to manage community posts.');
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
        return _CommunityComposerSheet(
          initialType: existingItem?.type ?? _selectedType,
          item: existingItem,
          authorUid: uid,
          profile: profile,
          communityService: _communityService,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _deleteItem(CommunityItem item) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete Community Post?',
      message:
          'This will remove "${item.title}" from the ${CommunityItem.typeLabels[item.type] ?? 'community'} lane.',
      confirmLabel: 'Delete Post',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _communityService.deleteCommunityItem(item.id);
      _showMessage('Community item removed.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_communityService.isAvailable) {
      return const _CommunityEmptyState(
        icon: Icons.groups_2_outlined,
        title: 'Community Needs Firebase',
        description:
            'Complete your Firebase setup to publish community posts, events, and club updates.',
      );
    }

    return StreamBuilder<List<CommunityItem>>(
      stream: _communityService.getCommunityItems(),
      builder: (BuildContext context, AsyncSnapshot<List<CommunityItem>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _CommunityEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Community Is Unavailable',
            description:
                'We could not load events, club posts, and lost-found items right now.',
          );
        }

        final List<CommunityItem> allItems =
            snapshot.data ?? const <CommunityItem>[];
        final List<CommunityItem> visibleItems = allItems
            .where((CommunityItem item) => item.type == _selectedType)
            .toList();
        final String? currentUid = AuthService.currentUser?.uid;
        final bool canModerate = AuthService.canModerateContent;
        final Map<String, int> counts = <String, int>{
          CommunityItem.eventType: allItems
              .where(
                (CommunityItem item) => item.type == CommunityItem.eventType,
              )
              .length,
          CommunityItem.lostFoundType: allItems
              .where(
                (CommunityItem item) =>
                    item.type == CommunityItem.lostFoundType,
              )
              .length,
          CommunityItem.clubType: allItems
              .where(
                (CommunityItem item) => item.type == CommunityItem.clubType,
              )
              .length,
        };

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
                          'Student community',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share events, post club updates, and help students recover lost items.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _showComposerSheet,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Create Post'),
                  ),
                ],
              ),
            ),
            if (canModerate) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.botBubble,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin moderation is active here. You can edit or remove community items when needed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    <String>[
                      CommunityItem.eventType,
                      CommunityItem.lostFoundType,
                      CommunityItem.clubType,
                    ].map((String type) {
                      final bool selected = type == _selectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          avatar: Icon(
                            CommunityItem.typeIcons[type],
                            size: 18,
                            color: selected
                                ? Colors.white
                                : AppTheme.primaryDark,
                          ),
                          label: Text(
                            '${CommunityItem.typeLabels[type]} (${counts[type] ?? 0})',
                          ),
                          onSelected: (bool _) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: visibleItems.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 56),
                        children: <Widget>[
                          _CommunityEmptyState(
                            icon:
                                CommunityItem.typeIcons[_selectedType] ??
                                Icons.groups_2_outlined,
                            title: _emptyTitle(_selectedType),
                            description: _emptyDescription(
                              _selectedType,
                              currentUid != null,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: visibleItems.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int index) {
                          final CommunityItem item = visibleItems[index];
                          final bool isOwner =
                              currentUid != null &&
                              item.authorUid == currentUid;
                          final bool canEdit = isOwner || canModerate;
                          final bool canDelete = isOwner || canModerate;

                          return _CommunityItemCard(
                            item: item,
                            canEdit: canEdit,
                            canDelete: canDelete,
                            onEdit: () =>
                                _showComposerSheet(existingItem: item),
                            onDelete: () => _deleteItem(item),
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

class _CommunityItemCard extends StatelessWidget {
  const _CommunityItemCard({
    required this.item,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final CommunityItem item;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: AppTheme.botBubble,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  CommunityItem.typeIcons[item.type] ?? Icons.groups_2_outlined,
                  color: AppTheme.primaryDark,
                ),
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
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CommunityStatusChip(
                          type: item.type,
                          status: item.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.botBubble,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            CommunityItem.typeLabels[item.type] ?? 'Community',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (item.authorRole != StudentProfile.userRole)
                          _CommunityRoleBadge(role: item.authorRole),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${item.authorName} | ${_formatCommunityDate(item.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          if (item.location.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.location,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CommunityComposerSheet extends StatefulWidget {
  const _CommunityComposerSheet({
    required this.initialType,
    required this.item,
    required this.authorUid,
    required this.profile,
    required this.communityService,
    required this.onMessage,
  });

  final String initialType;
  final CommunityItem? item;
  final String authorUid;
  final StudentProfile profile;
  final CommunityService communityService;
  final ValueChanged<String> onMessage;

  @override
  State<_CommunityComposerSheet> createState() =>
      _CommunityComposerSheetState();
}

class _CommunityComposerSheetState extends State<_CommunityComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late String _selectedType;
  late String _selectedStatus;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final CommunityItem? item = widget.item;
    _selectedType = item?.type ?? widget.initialType;
    _selectedStatus =
        item?.status ?? _statusOptionsForType(_selectedType).first;
    _titleController.text = item?.title ?? '';
    _descriptionController.text = item?.description ?? '';
    _locationController.text = item?.location ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      widget.onMessage('Please add both a title and a description.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final CommunityItem? existing = widget.item;
      final CommunityItem item = existing == null
          ? CommunityItem(
              id: '',
              type: _selectedType,
              title: title,
              description: description,
              location: location,
              status: _selectedStatus,
              authorUid: widget.authorUid,
              authorName: widget.profile.name,
              authorRole: widget.profile.role,
              createdAt: DateTime.now(),
            )
          : existing.copyWith(
              type: _selectedType,
              title: title,
              description: description,
              location: location,
              status: _selectedStatus,
            );

      if (existing == null) {
        await widget.communityService.createCommunityItem(item);
      } else {
        await widget.communityService.updateCommunityItem(item);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage(
        existing == null
            ? 'Community item published.'
            : 'Community item updated.',
      );
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
    final List<String> statusOptions = _statusOptionsForType(_selectedType);
    if (!statusOptions.contains(_selectedStatus)) {
      _selectedStatus = statusOptions.first;
    }

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
              widget.item == null
                  ? 'New Community Item'
                  : 'Edit Community Item',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items:
                  <String>[
                    CommunityItem.eventType,
                    CommunityItem.lostFoundType,
                    CommunityItem.clubType,
                  ].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(CommunityItem.typeLabels[type] ?? type),
                    );
                  }).toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedType = value;
                  _selectedStatus = _statusOptionsForType(value).first;
                });
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              items: statusOptions.map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(_statusLabel(_selectedType, status)),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedStatus = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Workshop, club fair, or lost item summary',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Room, building, campus lawn, or nearby spot',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Share the details students need to know.',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : widget.item == null
                      ? 'Publish Item'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityRoleBadge extends StatelessWidget {
  const _CommunityRoleBadge({required this.role});

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

class _CommunityStatusChip extends StatelessWidget {
  const _CommunityStatusChip({required this.type, required this.status});

  final String type;
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'found':
        color = AppTheme.success;
        break;
      case 'lost':
        color = AppTheme.error;
        break;
      case 'closed':
        color = AppTheme.textSecondary;
        break;
      default:
        color = AppTheme.primaryDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(type, status),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommunityEmptyState extends StatelessWidget {
  const _CommunityEmptyState({
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

List<String> _statusOptionsForType(String type) {
  switch (type) {
    case CommunityItem.lostFoundType:
      return const <String>['lost', 'found', 'closed'];
    case CommunityItem.clubType:
      return const <String>['open', 'closed'];
    default:
      return const <String>['open', 'closed'];
  }
}

String _statusLabel(String type, String status) {
  switch (type) {
    case CommunityItem.lostFoundType:
      switch (status) {
        case 'found':
          return 'Found';
        case 'closed':
          return 'Closed';
        default:
          return 'Lost';
      }
    case CommunityItem.clubType:
      return status == 'closed' ? 'Closed' : 'Open';
    default:
      return status == 'closed' ? 'Closed' : 'Upcoming';
  }
}

String _emptyTitle(String type) {
  switch (type) {
    case CommunityItem.lostFoundType:
      return 'No Lost & Found Posts';
    case CommunityItem.clubType:
      return 'No Club Updates Yet';
    default:
      return 'No Events Yet';
  }
}

String _emptyDescription(String type, bool isSignedIn) {
  switch (type) {
    case CommunityItem.lostFoundType:
      return isSignedIn
          ? 'Post a lost or found item to help students reconnect with their belongings.'
          : 'Lost and found updates will appear here once students start posting.';
    case CommunityItem.clubType:
      return isSignedIn
          ? 'Share a club update, recruitment post, or community announcement.'
          : 'Club and community posts will appear here soon.';
    default:
      return isSignedIn
          ? 'Create the first campus event post to kick things off.'
          : 'Upcoming campus events will appear here soon.';
  }
}

String _formatCommunityDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  final String hour = local.hour > 12
      ? (local.hour - 12).toString()
      : (local.hour == 0 ? '12' : local.hour.toString());
  final String minute = local.minute.toString().padLeft(2, '0');
  final String suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day}/${local.month}/${local.year} | $hour:$minute $suffix';
}
