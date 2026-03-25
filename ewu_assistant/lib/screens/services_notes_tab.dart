import 'package:flutter/material.dart';

import '../models/note_item.dart';
import '../models/student_profile.dart';
import '../services/auth_service.dart';
import '../services/services_hub_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';

class ServicesNotesTab extends StatefulWidget {
  const ServicesNotesTab({super.key, required this.searchQuery});

  final String searchQuery;

  @override
  State<ServicesNotesTab> createState() => _ServicesNotesTabState();
}

class _ServicesNotesTabState extends State<ServicesNotesTab> {
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

  Future<void> _showCreateNoteSheet() async {
    final StudentProfile? profile = await AuthService.getProfile();
    final String? uid = AuthService.currentUser?.uid;
    if (!mounted) {
      return;
    }
    if (profile == null || uid == null) {
      _showMessage('Please sign in again to upload a note.');
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
        return _CreateNoteSheet(
          profile: profile,
          uploaderUid: uid,
          servicesHubService: _servicesHubService,
          onMessage: _showMessage,
        );
      },
    );
  }

  Future<void> _deleteNote(NoteItem note) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Delete Note?',
      message:
          'This will remove "${note.title}" from the shared course materials hub.',
      confirmLabel: 'Delete Note',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }

    try {
      await _servicesHubService.deleteNote(note.id);
      _showMessage('Note removed.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<NoteItem> _filterNotes(List<NoteItem> notes) {
    final String query = widget.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return notes;
    }

    return notes.where((NoteItem note) {
      return note.courseCode.toLowerCase().contains(query) ||
          note.courseTag.toLowerCase().contains(query) ||
          note.title.toLowerCase().contains(query) ||
          note.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesHubService.isAvailable) {
      return const _ServicesEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'Notes Need Firebase',
        description:
            'Complete your Firebase setup to share course notes and study materials.',
      );
    }

    return StreamBuilder<List<NoteItem>>(
      stream: _servicesHubService.getNotes(),
      builder: (BuildContext context, AsyncSnapshot<List<NoteItem>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _ServicesEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Notes Unavailable',
            description:
                'We could not load the notes hub right now. Please try again in a moment.',
          );
        }

        final List<NoteItem> notes = snapshot.data ?? const <NoteItem>[];
        final List<NoteItem> filteredNotes = _filterNotes(notes);
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
                          'Course materials',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share course notes, revision packs, and lab material with your classmates.',
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
                          '${filteredNotes.length} notes',
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
                onPressed: _showCreateNoteSheet,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add Note'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: filteredNotes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 40),
                        children: <Widget>[
                          _ServicesEmptyState(
                            icon: Icons.library_books_outlined,
                            title: widget.searchQuery.trim().isEmpty
                                ? 'No Notes Yet'
                                : 'No Notes Match',
                            description: widget.searchQuery.trim().isEmpty
                                ? 'Upload the first note to kick off the study materials hub.'
                                : 'Try another course code or keyword to find matching notes.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: filteredNotes.length,
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (BuildContext context, int index) {
                          final NoteItem note = filteredNotes[index];
                          final bool canDelete =
                              note.uploaderUid == currentUid || canModerate;
                          return _NoteCard(
                            note: note,
                            canDelete: canDelete,
                            onDelete: () => _deleteNote(note),
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.canDelete,
    required this.onDelete,
  });

  final NoteItem note;
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
                  note.courseTag.isEmpty ? note.courseCode : note.courseTag,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.courseCode,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
          Text(
            note.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            note.description,
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
                icon: Icons.person_outline_rounded,
                label: note.uploaderName,
              ),
              _MetaPill(
                icon: Icons.calendar_today_outlined,
                label: _formatServicesDate(note.createdAt),
              ),
              _MetaPill(
                icon: Icons.attach_file_rounded,
                label: note.fileUrl.isEmpty
                    ? 'Attachment placeholder'
                    : 'File placeholder ready',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateNoteSheet extends StatefulWidget {
  const _CreateNoteSheet({
    required this.profile,
    required this.uploaderUid,
    required this.servicesHubService,
    required this.onMessage,
  });

  final StudentProfile profile;
  final String uploaderUid;
  final ServicesHubService servicesHubService;
  final ValueChanged<String> onMessage;

  @override
  State<_CreateNoteSheet> createState() => _CreateNoteSheetState();
}

class _CreateNoteSheetState extends State<_CreateNoteSheet> {
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseTagController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fileUrlController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTagController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String courseCode = _courseCodeController.text.trim().toUpperCase();
    final String courseTag = _courseTagController.text.trim();
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String fileUrl = _fileUrlController.text.trim();

    if (courseCode.isEmpty || title.isEmpty || description.isEmpty) {
      widget.onMessage('Please add course code, title, and description.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.servicesHubService.createNote(
        NoteItem(
          id: '',
          courseCode: courseCode,
          courseTag: courseTag,
          title: title,
          description: description,
          uploaderUid: widget.uploaderUid,
          uploaderName: widget.profile.name,
          fileUrl: fileUrl,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      widget.onMessage('Note published.');
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
              'Add Note',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course code',
                hintText: 'CSE101',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _courseTagController,
              decoration: const InputDecoration(
                labelText: 'Course tag',
                hintText: 'Theory, Lab, Midterm Pack',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Revision notes for chapter 1',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell students what is included in this note.',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _fileUrlController,
              decoration: const InputDecoration(
                labelText: 'File URL (optional placeholder)',
                hintText: 'Paste a placeholder file link for a future pass',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Publishing...' : 'Publish Note'),
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
        'Admin access',
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
