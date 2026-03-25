import 'package:flutter/material.dart';

import '../services/smart_tools_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_tool_widgets.dart';

class SmartToolsExamCountdownTab extends StatefulWidget {
  const SmartToolsExamCountdownTab({super.key});

  @override
  State<SmartToolsExamCountdownTab> createState() =>
      _SmartToolsExamCountdownTabState();
}

class _SmartToolsExamCountdownTabState
    extends State<SmartToolsExamCountdownTab> {
  final SmartToolsService _smartToolsService = SmartToolsService();
  final List<_ExamCountdownItem> _items = <_ExamCountdownItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> raw = await _smartToolsService
        .loadExamCountdownItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(raw.map(_ExamCountdownItem.fromJson));
      _items.sort(
        (_ExamCountdownItem a, _ExamCountdownItem b) =>
            a.date.compareTo(b.date),
      );
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _smartToolsService.saveExamCountdownItems(
      _items.map((_ExamCountdownItem item) => item.toJson()).toList(),
    );
  }

  Future<void> _showAddExamSheet() async {
    final TextEditingController titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Add Exam Countdown',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Exam title',
                      hintText: 'Database Midterm',
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked == null) {
                        return;
                      }
                      setSheetState(() {
                        selectedDate = picked;
                      });
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_formatDate(selectedDate)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final String title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an exam title.'),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _items.add(
                            _ExamCountdownItem(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              title: title,
                              date: selectedDate,
                            ),
                          );
                          _items.sort(
                            (_ExamCountdownItem a, _ExamCountdownItem b) =>
                                a.date.compareTo(b.date),
                          );
                        });
                        await _persist();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      child: const Text('Add Countdown'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: <Widget>[
        SmartToolSummaryCard(
          title: 'Upcoming Assessments',
          subtitle:
              'Keep your exam dates visible so deadlines never catch you off guard.',
          trailing: Text(
            '${_items.length}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showAddExamSheet,
            icon: const Icon(Icons.add_alert_outlined),
            label: const Text('Add Exam'),
          ),
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          const SmartToolEmptyState(
            icon: Icons.timer_outlined,
            title: 'No Exam Countdowns Yet',
            description:
                'Add an exam date to see how many days are left before the assessment.',
          )
        else
          ..._items.map((_ExamCountdownItem item) {
            final int daysLeft =
                item.date.difference(DateTime.now()).inDays +
                (item.date.isAfter(DateTime.now()) ? 1 : 0);
            final bool overdue = daysLeft < 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.premiumCard,
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: overdue
                            ? AppTheme.error.withValues(alpha: 0.08)
                            : AppTheme.botBubble,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        overdue ? 'Done' : '$daysLeft',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: overdue
                                  ? AppTheme.error
                                  : AppTheme.primaryDark,
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
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(item.date),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            overdue
                                ? 'This exam date has passed.'
                                : daysLeft == 0
                                ? 'Today is the day.'
                                : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: overdue
                                      ? AppTheme.error
                                      : AppTheme.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        setState(() {
                          _items.removeWhere(
                            (_ExamCountdownItem exam) => exam.id == item.id,
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

class _ExamCountdownItem {
  const _ExamCountdownItem({
    required this.id,
    required this.title,
    required this.date,
  });

  final String id;
  final String title;
  final DateTime date;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
    };
  }

  factory _ExamCountdownItem.fromJson(Map<String, dynamic> json) {
    return _ExamCountdownItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final DateTime local = dateTime.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
