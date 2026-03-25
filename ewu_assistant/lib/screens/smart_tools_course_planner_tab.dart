import 'package:flutter/material.dart';

import '../models/routine_class_item.dart';
import '../services/smart_tools_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_tool_widgets.dart';

class SmartToolsCoursePlannerTab extends StatefulWidget {
  const SmartToolsCoursePlannerTab({super.key});

  @override
  State<SmartToolsCoursePlannerTab> createState() =>
      _SmartToolsCoursePlannerTabState();
}

class _SmartToolsCoursePlannerTabState
    extends State<SmartToolsCoursePlannerTab> {
  final SmartToolsService _smartToolsService = SmartToolsService();
  final List<_PlannerCourse> _courses = <_PlannerCourse>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final List<Map<String, dynamic>> rawItems = await _smartToolsService
        .loadCoursePlannerItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _courses
        ..clear()
        ..addAll(rawItems.map(_PlannerCourse.fromJson));
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _smartToolsService.saveCoursePlannerItems(
      _courses.map((_PlannerCourse item) => item.toJson()).toList(),
    );
  }

  Future<void> _showAddPlannerSheet() async {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController creditsController = TextEditingController();
    String day = RoutineClassItem.days.first;

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
                    'Add Planned Course',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Course code',
                      hintText: 'CSE407',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Course title',
                      hintText: 'Mobile Application Development',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: creditsController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Credits',
                      hintText: '3',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: day,
                    items: RoutineClassItem.days.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() {
                        day = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Focus day'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final String code = codeController.text.trim();
                        final String title = titleController.text.trim();
                        final double credits =
                            double.tryParse(creditsController.text.trim()) ?? 0;
                        if (code.isEmpty || title.isEmpty || credits <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add course code, title, and credits.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _courses.add(
                            _PlannerCourse(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              code: code,
                              title: title,
                              credits: credits,
                              day: day,
                            ),
                          );
                        });
                        await _persist();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      child: const Text('Add To Planner'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    codeController.dispose();
    titleController.dispose();
    creditsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final double totalCredits = _courses.fold<double>(
      0,
      (double sum, _PlannerCourse item) => sum + item.credits,
    );
    final Map<String, List<_PlannerCourse>> grouped =
        <String, List<_PlannerCourse>>{};
    for (final _PlannerCourse item in _courses) {
      grouped.putIfAbsent(item.day, () => <_PlannerCourse>[]).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: <Widget>[
        SmartToolSummaryCard(
          title: 'Planner Snapshot',
          subtitle:
              'Keep a clear list of future courses and spread them across your week.',
          trailing: Text(
            totalCredits.toStringAsFixed(1),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SmartToolInfoChip(
              icon: Icons.layers_outlined,
              label: '${_courses.length} planned courses',
            ),
            SmartToolInfoChip(
              icon: Icons.school_outlined,
              label: '${totalCredits.toStringAsFixed(1)} total credits',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showAddPlannerSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Course'),
          ),
        ),
        const SizedBox(height: 16),
        if (_courses.isEmpty)
          const SmartToolEmptyState(
            icon: Icons.route_outlined,
            title: 'Course Planner Is Empty',
            description:
                'Add the courses you want to take so your upcoming semester stays balanced.',
          )
        else
          ...RoutineClassItem.days.where(grouped.containsKey).map((String day) {
            final List<_PlannerCourse> items = grouped[day]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                          icon: Icons.menu_book_outlined,
                          label: '${items.length} items',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...items.map((_PlannerCourse item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.botBubble,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.code,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.title} | ${item.credits.toStringAsFixed(1)} credits',
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
                                onPressed: () async {
                                  setState(() {
                                    _courses.removeWhere(
                                      (_PlannerCourse course) =>
                                          course.id == item.id,
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
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _PlannerCourse {
  const _PlannerCourse({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.day,
  });

  final String id;
  final String code;
  final String title;
  final double credits;
  final String day;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'title': title,
      'credits': credits,
      'day': day,
    };
  }

  factory _PlannerCourse.fromJson(Map<String, dynamic> json) {
    return _PlannerCourse(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      credits: (json['credits'] as num?)?.toDouble() ?? 0,
      day: json['day']?.toString() ?? RoutineClassItem.days.first,
    );
  }
}
