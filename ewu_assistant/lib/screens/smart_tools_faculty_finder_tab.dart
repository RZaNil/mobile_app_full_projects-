import 'package:flutter/material.dart';

import '../services/smart_tools_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_tool_widgets.dart';

class SmartToolsFacultyFinderTab extends StatefulWidget {
  const SmartToolsFacultyFinderTab({super.key});

  @override
  State<SmartToolsFacultyFinderTab> createState() =>
      _SmartToolsFacultyFinderTabState();
}

class _SmartToolsFacultyFinderTabState
    extends State<SmartToolsFacultyFinderTab> {
  final SmartToolsService _smartToolsService = SmartToolsService();
  final TextEditingController _searchController = TextEditingController();
  final List<_FacultyContactItem> _contacts = <_FacultyContactItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> raw = await _smartToolsService
        .loadFacultyContacts();
    if (!mounted) {
      return;
    }
    setState(() {
      _contacts
        ..clear()
        ..addAll(raw.map(_FacultyContactItem.fromJson));
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _smartToolsService.saveFacultyContacts(
      _contacts.map((_FacultyContactItem item) => item.toJson()).toList(),
    );
  }

  Future<void> _showAddContactSheet() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController departmentController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController roomController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
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
                  'Add Faculty Contact',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Dr. Rahman',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    hintText: 'CSE',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'faculty@ewubd.edu',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    hintText: 'Department office',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Office hours, course advisor, or reminder',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final String name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please add the faculty or contact name.',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _contacts.add(
                          _FacultyContactItem(
                            id: DateTime.now().microsecondsSinceEpoch
                                .toString(),
                            name: name,
                            department: departmentController.text.trim(),
                            email: emailController.text.trim(),
                            room: roomController.text.trim(),
                            note: noteController.text.trim(),
                          ),
                        );
                      });
                      await _persist();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save Contact'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
    departmentController.dispose();
    emailController.dispose();
    roomController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String query = _searchController.text.trim().toLowerCase();
    final List<_FacultyContactItem> filtered = _contacts.where((
      _FacultyContactItem item,
    ) {
      if (query.isEmpty) {
        return true;
      }
      return item.name.toLowerCase().contains(query) ||
          item.department.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: <Widget>[
        SmartToolSummaryCard(
          title: 'Personal Faculty Directory',
          subtitle:
              'Save faculty and office contacts here until a full university directory is connected.',
          trailing: Text(
            '${_contacts.length}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search by name, department, or email',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showAddContactSheet,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Add Contact'),
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const SmartToolEmptyState(
            icon: Icons.contact_mail_outlined,
            title: 'No Saved Faculty Contacts',
            description:
                'Add faculty or office contacts so you can search them quickly during the semester.',
          )
        else
          ...filtered.map((_FacultyContactItem item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.premiumCard,
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.botBubble,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.name.substring(0, 1).toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                                  if (item.department.isNotEmpty)
                                    item.department,
                                  if (item.room.isNotEmpty) item.room,
                                ].join(' | ').isEmpty
                                ? 'Faculty contact'
                                : [
                                    if (item.department.isNotEmpty)
                                      item.department,
                                    if (item.room.isNotEmpty) item.room,
                                  ].join(' | '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          if (item.email.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              item.email,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                          if (item.note.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 6),
                            Text(
                              item.note,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        setState(() {
                          _contacts.removeWhere(
                            (_FacultyContactItem contact) =>
                                contact.id == item.id,
                          );
                        });
                        await _persist();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _FacultyContactItem {
  const _FacultyContactItem({
    required this.id,
    required this.name,
    required this.department,
    required this.email,
    required this.room,
    required this.note,
  });

  final String id;
  final String name;
  final String department;
  final String email;
  final String room;
  final String note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'department': department,
      'email': email,
      'room': room,
      'note': note,
    };
  }

  factory _FacultyContactItem.fromJson(Map<String, dynamic> json) {
    return _FacultyContactItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}
