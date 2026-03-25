import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/notification_action_button.dart';
import 'smart_tools_cgpa_tab.dart';
import 'smart_tools_course_planner_tab.dart';
import 'smart_tools_exam_countdown_tab.dart';
import 'smart_tools_faculty_finder_tab.dart';
import 'smart_tools_routine_tab.dart';

enum SmartToolType {
  cgpaPredictor,
  routineGenerator,
  coursePlanner,
  examCountdown,
  facultyFinder,
}

extension SmartToolTypeX on SmartToolType {
  String get label {
    switch (this) {
      case SmartToolType.cgpaPredictor:
        return 'CGPA Predictor';
      case SmartToolType.routineGenerator:
        return 'Routine Generator';
      case SmartToolType.coursePlanner:
        return 'Course Planner';
      case SmartToolType.examCountdown:
        return 'Exam Countdown';
      case SmartToolType.facultyFinder:
        return 'Faculty Finder';
    }
  }

  IconData get icon {
    switch (this) {
      case SmartToolType.cgpaPredictor:
        return Icons.analytics_outlined;
      case SmartToolType.routineGenerator:
        return Icons.auto_awesome_outlined;
      case SmartToolType.coursePlanner:
        return Icons.route_outlined;
      case SmartToolType.examCountdown:
        return Icons.timer_outlined;
      case SmartToolType.facultyFinder:
        return Icons.contact_mail_outlined;
    }
  }

  String get subtitle {
    switch (this) {
      case SmartToolType.cgpaPredictor:
        return 'Model semester outcomes and keep your target CGPA in view.';
      case SmartToolType.routineGenerator:
        return 'Draft classes quickly and save them into your routine lane.';
      case SmartToolType.coursePlanner:
        return 'Organize planned courses and keep a simple weekly overview.';
      case SmartToolType.examCountdown:
        return 'Track important assessments and stay ahead of deadlines.';
      case SmartToolType.facultyFinder:
        return 'Build a personal searchable directory for faculty contacts.';
    }
  }
}

class SmartToolsScreen extends StatefulWidget {
  const SmartToolsScreen({
    super.key,
    this.initialTool = SmartToolType.cgpaPredictor,
  });

  final SmartToolType initialTool;

  @override
  State<SmartToolsScreen> createState() => _SmartToolsScreenState();
}

class _SmartToolsScreenState extends State<SmartToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(
          length: SmartToolType.values.length,
          vsync: this,
          initialIndex: widget.initialTool.index,
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SmartToolType currentTool =
        SmartToolType.values[_tabController.index];

    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      appBar: AppBar(
        title: const Text('Smart Tools'),
        actions: <Widget>[
          NotificationActionButton(
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.navyCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(currentTool.icon, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              currentTool.label,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        currentTool.subtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryDark.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textPrimary,
                    tabs: SmartToolType.values
                        .map((SmartToolType tool) => Tab(text: tool.label))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const <Widget>[
                    SmartToolsCgpaTab(),
                    SmartToolsRoutineTab(),
                    SmartToolsCoursePlannerTab(),
                    SmartToolsExamCountdownTab(),
                    SmartToolsFacultyFinderTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
