import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/smart_tool_widgets.dart';

class SmartToolsCgpaTab extends StatefulWidget {
  const SmartToolsCgpaTab({super.key});

  @override
  State<SmartToolsCgpaTab> createState() => _SmartToolsCgpaTabState();
}

class _SmartToolsCgpaTabState extends State<SmartToolsCgpaTab> {
  final TextEditingController _currentCgpaController = TextEditingController();
  final TextEditingController _completedCreditsController =
      TextEditingController();
  final List<_ProjectedCourse> _courses = <_ProjectedCourse>[];

  @override
  void dispose() {
    _currentCgpaController.dispose();
    _completedCreditsController.dispose();
    super.dispose();
  }

  double get _currentCgpa =>
      double.tryParse(_currentCgpaController.text.trim()) ?? 0;

  double get _completedCredits =>
      double.tryParse(_completedCreditsController.text.trim()) ?? 0;

  double get _projectedCredits => _courses.fold<double>(
    0,
    (double total, _ProjectedCourse course) => total + course.credits,
  );

  double get _projectedSemesterGpa {
    if (_courses.isEmpty || _projectedCredits <= 0) {
      return 0;
    }
    final double qualityPoints = _courses.fold<double>(
      0,
      (double total, _ProjectedCourse course) =>
          total + (course.credits * course.gradePoint),
    );
    return qualityPoints / _projectedCredits;
  }

  double get _predictedCgpa {
    final double totalCredits = _completedCredits + _projectedCredits;
    if (totalCredits <= 0) {
      return 0;
    }
    final double currentQualityPoints = _currentCgpa * _completedCredits;
    final double futureQualityPoints = _courses.fold<double>(
      0,
      (double total, _ProjectedCourse course) =>
          total + (course.credits * course.gradePoint),
    );
    return (currentQualityPoints + futureQualityPoints) / totalCredits;
  }

  Future<void> _showAddCourseSheet() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController creditsController = TextEditingController();
    double gradePoint = 4.0;

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
                    'Add Projected Course',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Course title or code',
                      hintText: 'CSE303 or Database Systems',
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
                      hintText: '3.0',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<double>(
                    initialValue: gradePoint,
                    items:
                        const <double>[
                          4.0,
                          3.75,
                          3.5,
                          3.25,
                          3.0,
                          2.75,
                          2.5,
                          2.25,
                          2.0,
                          0.0,
                        ].map((double value) {
                          return DropdownMenuItem<double>(
                            value: value,
                            child: Text(value.toStringAsFixed(2)),
                          );
                        }).toList(),
                    onChanged: (double? value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() {
                        gradePoint = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Expected grade point',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final String title = titleController.text.trim();
                        final double credits =
                            double.tryParse(creditsController.text.trim()) ?? 0;
                        if (title.isEmpty || credits <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add a course title and valid credits.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _courses.add(
                            _ProjectedCourse(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              title: title,
                              credits: credits,
                              gradePoint: gradePoint,
                            ),
                          );
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Add Course'),
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
    creditsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: <Widget>[
        SmartToolSummaryCard(
          title: 'Prediction Summary',
          subtitle:
              'Use your current CGPA and expected grades to estimate your next result.',
          trailing: Text(
            _predictedCgpa == 0 ? '--' : _predictedCgpa.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _currentCgpaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Current CGPA',
                  hintText: '3.60',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _completedCreditsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Completed credits',
                  hintText: '90',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SmartToolInfoChip(
              icon: Icons.auto_graph_outlined,
              label: _projectedSemesterGpa == 0
                  ? 'Projected GPA --'
                  : 'Projected GPA ${_projectedSemesterGpa.toStringAsFixed(2)}',
            ),
            SmartToolInfoChip(
              icon: Icons.menu_book_outlined,
              label: '${_courses.length} projected courses',
            ),
            SmartToolInfoChip(
              icon: Icons.scale_outlined,
              label: '${_projectedCredits.toStringAsFixed(1)} planned credits',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _showAddCourseSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Course'),
          ),
        ),
        const SizedBox(height: 16),
        if (_courses.isEmpty)
          const SmartToolEmptyState(
            icon: Icons.analytics_outlined,
            title: 'No Projected Courses Yet',
            description:
                'Add your expected semester courses to estimate a realistic CGPA outcome.',
          )
        else
          ..._courses.map((_ProjectedCourse course) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.premiumCard,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            course.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${course.credits.toStringAsFixed(1)} credits | grade point ${course.gradePoint.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _courses.removeWhere(
                            (_ProjectedCourse item) => item.id == course.id,
                          );
                        });
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

class _ProjectedCourse {
  const _ProjectedCourse({
    required this.id,
    required this.title,
    required this.credits,
    required this.gradePoint,
  });

  final String id;
  final String title;
  final double credits;
  final double gradePoint;
}
