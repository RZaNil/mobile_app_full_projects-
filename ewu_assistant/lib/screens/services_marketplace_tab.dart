import 'package:flutter/material.dart';

import '../models/marketplace_post.dart';
import '../services/auth_service.dart';
import '../services/services_hub_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';

class ServicesMarketplaceTab extends StatefulWidget {
  const ServicesMarketplaceTab({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  State<ServicesMarketplaceTab> createState() => _ServicesMarketplaceTabState();
}

class _ServicesMarketplaceTabState extends State<ServicesMarketplaceTab> {
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
      _showMessage('Please sign in again to add a marketplace post.');
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
        return _CreateMarketplaceSheet(
          authorUid: uid,
          servicesHubService: _servicesHubService,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _deletePost(MarketplacePost post) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete Listing?',
      message: 'This will remove "${post.title}" from the student marketplace.',
      confirmLabel: 'Delete Listing',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _servicesHubService.deleteMarketplacePost(post.id);
      _showMessage('Marketplace post removed.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<MarketplacePost> _filterPosts(List<MarketplacePost> posts) {
    final String query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return posts;
    }

    return posts.where((MarketplacePost post) {
      return post.title.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.condition.toLowerCase().contains(query) ||
          post.price.toLowerCase().contains(query) ||
          post.contactInfo.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesHubService.isAvailable) {
      return const _ServicesEmptyState(
        icon: Icons.storefront_outlined,
        title: 'Marketplace Needs Firebase',
        description:
            'Complete your Firebase setup to publish student buy and sell listings.',
      );
    }

    return StreamBuilder<List<MarketplacePost>>(
      stream: _servicesHubService.getMarketplacePosts(),
      builder: (BuildContext context, AsyncSnapshot<List<MarketplacePost>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ServicesEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Marketplace Unavailable',
            description: 'We could not load the student marketplace right now.',
          );
        }

        final List<MarketplacePost> posts = _filterPosts(
          snapshot.data ?? const <MarketplacePost>[],
        );
        final String? currentUid = AuthService.currentUser?.uid;
        final bool canModerate = AuthService.canModerateContent;

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.premiumCard,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Student marketplace',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A premium starter space for books, gadgets, hostel essentials, and class-friendly buys.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
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
                          '${posts.length} listings',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (canModerate) ...<Widget>[
                        const SizedBox(height: 10),
                        const _AdminModeChip(),
                      ],
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
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('List Item'),
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
                            icon: Icons.shopping_bag_outlined,
                            title: widget.searchQuery.trim().isEmpty
                                ? 'No Listings Yet'
                                : 'No Listings Match',
                            description: widget.searchQuery.trim().isEmpty
                                ? 'Create the first buy or sell post for the campus marketplace.'
                                : 'Try a different keyword to find matching marketplace listings.',
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
                          final MarketplacePost post = posts[index];
                          final bool canDelete =
                              post.authorUid == currentUid || canModerate;
                          return _MarketplaceCard(
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

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({
    required this.post,
    required this.canDelete,
    required this.onDelete,
  });

  final MarketplacePost post;
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _MetaPill(
                          icon: Icons.sell_outlined,
                          label: post.price.isEmpty
                              ? 'Price on request'
                              : post.price,
                        ),
                        _MetaPill(
                          icon: Icons.verified_outlined,
                          label: post.condition.isEmpty
                              ? 'Condition not set'
                              : post.condition,
                        ),
                      ],
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
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                post.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => _ImagePlaceholder(hasLink: true),
              ),
            )
          else
            const _ImagePlaceholder(hasLink: false),
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

class _CreateMarketplaceSheet extends StatefulWidget {
  const _CreateMarketplaceSheet({
    required this.authorUid,
    required this.servicesHubService,
    required this.onMessage,
  });

  final String authorUid;
  final ServicesHubService servicesHubService;
  final ValueChanged<String> onMessage;

  @override
  State<_CreateMarketplaceSheet> createState() =>
      _CreateMarketplaceSheetState();
}

class _CreateMarketplaceSheetState extends State<_CreateMarketplaceSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _conditionController.dispose();
    _contactController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String price = _priceController.text.trim();
    final String condition = _conditionController.text.trim();
    final String contactInfo = _contactController.text.trim();
    final String imageUrl = _imageUrlController.text.trim();

    if (title.isEmpty || description.isEmpty || contactInfo.isEmpty) {
      widget.onMessage('Please add title, description, and contact info.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.servicesHubService.createMarketplacePost(
        MarketplacePost(
          id: '',
          title: title,
          description: description,
          price: price,
          condition: condition,
          contactInfo: contactInfo,
          imageUrl: imageUrl,
          authorUid: widget.authorUid,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage('Marketplace listing published.');
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
              'Add Marketplace Listing',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Textbook set, calculator, desk lamp, or headset',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'BDT 1200 or Negotiable',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _conditionController,
              decoration: const InputDecoration(
                labelText: 'Condition',
                hintText: 'New, lightly used, good condition',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact info',
                hintText: 'Phone, email, or messaging handle',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional placeholder)',
                hintText: 'Paste an image link for this listing if available',
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
                    'Add item details, pickup notes, and anything buyers should know.',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting ? 'Publishing...' : 'Publish Listing',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.hasLink});

  final bool hasLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            hasLink ? Icons.image_outlined : Icons.photo_library_outlined,
            color: AppTheme.primaryDark,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            hasLink ? 'Listing image placeholder' : 'No image added yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
