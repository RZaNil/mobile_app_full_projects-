import 'package:flutter/material.dart';

import '../models/routine_class_item.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_tool_widgets.dart';

class SmartToolsRoutineTab extends StatefulWidget {
  const SmartToolsRoutineTab({super.key});

  @override
  State<SmartToolsRoutineTab> createState() => _SmartToolsRoutineTabState();
}

class _SmartToolsRoutineTabState extends State<SmartToolsRoutineTab> {
  final CommunityService _communityService = CommunityService();
  final List<RoutineClassItem> _draftClasses = <RoutineClassItem>[];
  bool _isSaving = false;

  Future<void> _showAddClassSheet() async {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController roomController = TextEditingController();
    final TextEditingController startController = TextEditingController();
    final TextEditingController endController = TextEditingController();
    String selectedDay = RoutineClassItem.days.first;
    String selectedColor = '#0A1F44';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
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
                      'Add Draft Class',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      items: RoutineClassItem.days.map((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setSheetState(() {
                          selectedDay = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Course code',
                        hintText: 'CSE305',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course title',
                        hintText: 'Artificial Intelligence',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        hintText: 'A-609',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: startController,
                            decoration: const InputDecoration(
                              labelText: 'Start time',
                              hintText: '9:00 AM',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            decoration: const InputDecoration(
                              labelText: 'End time',
                              hintText: '10:20 AM',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedColor,
                      items:
                          const <String>[
                            '#0A1F44',
                            '#1C3F7A',
                            '#2E7D32',
                            '#D32F2F',
                            '#F57C00',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          value.replaceFirst('#', 'FF'),
                                          radix: 16,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setSheetState(() {
                          selectedColor = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final String code = codeController.text.trim();
                          final String title = titleController.text.trim();
                          final String start = startController.text.trim();
                          final String end = endController.text.trim();
                          if (code.isEmpty ||
                              title.isEmpty ||
                              start.isEmpty ||
                              end.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please add the course details and class times.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _draftClasses.add(
                              RoutineClassItem(
                                id: DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                                day: selectedDay,
                                courseCode: code,
                                courseTitle: title,
                                room: roomController.text.trim(),
                                startTime: start,
                                endTime: end,
                                color: selectedColor,
                                createdAt: DateTime.now(),
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Add To Draft'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    codeController.dispose();
    titleController.dispose();
    roomController.dispose();
    startController.dispose();
    endController.dispose();
  }

  Future<void> _saveToRoutine() async {
    if (_draftClasses.isEmpty || _isSaving) {
      return;
    }

    final String? uid = AuthService.currentUser?.uid;
    if (uid == null || !_communityService.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in with Firebase enabled to save classes.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      for (final RoutineClassItem item in _draftClasses) {
        await _communityService.createRoutineClass(uid, item.copyWith(id: ''));
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _draftClasses.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft routine saved to your schedule.')),
      );
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<RoutineClassItem>> grouped =
        <String, List<RoutineClassItem>>{};
    for (final RoutineClassItem item in _draftClasses) {
      grouped.putIfAbsent(item.day, () => <RoutineClassItem>[]).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: <Widget>[
        SmartToolSummaryCard(
          title: 'Draft Weekly Routine',
          subtitle:
              'Add classes quickly, group them by day, and push the finished draft into your routine lane.',
          trailing: Text(
            '${_draftClasses.length}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddClassSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Draft Class'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _draftClasses.isEmpty || _isSaving
                    ? null
                    : _saveToRoutine,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save To Routine'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_draftClasses.isEmpty)
          const SmartToolEmptyState(
            icon: Icons.auto_awesome_outlined,
            title: 'Start With A Draft',
            description:
                'Add your classes here to auto-group them by day before saving to your live routine.',
          )
        else
          ...RoutineClassItem.days.where(grouped.containsKey).map((String day) {
            final List<RoutineClassItem> items = grouped[day]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.premiumCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          day,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        SmartToolInfoChip(
                          icon: Icons.class_outlined,
                          label: '${items.length} classes',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...items.map((RoutineClassItem item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.botBubble,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 10,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: item.colorValue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.courseCode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.courseTitle} | ${item.startTime} - ${item.endTime}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _draftClasses.removeWhere(
                                      (RoutineClassItem draft) =>
                                          draft.id == item.id,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
