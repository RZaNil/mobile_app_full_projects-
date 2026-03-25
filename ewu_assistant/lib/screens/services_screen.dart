import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/campus_section_header.dart';
import '../widgets/notification_action_button.dart';
import 'services_marketplace_tab.dart';
import 'services_notes_tab.dart';
import 'smart_tools_screen.dart';
import 'services_workplace_tab.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const List<_SmartToolShortcut> _smartTools = <_SmartToolShortcut>[
    _SmartToolShortcut(
      title: 'Smart Routine Generator',
      subtitle: 'Draft classes by day and save them into your live routine.',
      icon: Icons.auto_awesome_outlined,
      toolType: SmartToolType.routineGenerator,
    ),
    _SmartToolShortcut(
      title: 'CGPA Predictor',
      subtitle: 'Estimate your next CGPA using credits and expected grades.',
      icon: Icons.analytics_outlined,
      toolType: SmartToolType.cgpaPredictor,
    ),
    _SmartToolShortcut(
      title: 'Course Planner',
      subtitle: 'Build a simple weekly plan for upcoming courses.',
      icon: Icons.route_outlined,
      toolType: SmartToolType.coursePlanner,
    ),
    _SmartToolShortcut(
      title: 'Exam Countdown',
      subtitle: 'Track assessments and see how many days remain.',
      icon: Icons.timer_outlined,
      toolType: SmartToolType.examCountdown,
    ),
    _SmartToolShortcut(
      title: 'Faculty Contact Finder',
      subtitle: 'Save and search faculty contacts in one quick directory.',
      icon: Icons.contact_mail_outlined,
      toolType: SmartToolType.facultyFinder,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openTool(_SmartToolShortcut tool) {
    Navigator.of(context).push(
      MaterialPageRoute<SmartToolsScreen>(
        builder: (_) => SmartToolsScreen(initialTool: tool.toolType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String searchQuery = _searchController.text;
    final bool compact = MediaQuery.sizeOf(context).height < 760;

    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CampusSectionHeader(
                  title: 'Services',
                  subtitle:
                      'Course materials, campus opportunities, student marketplace posts, and practical smart tools.',
                  actions: <Widget>[NotificationActionButton()],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search notes, jobs, listings, or course tags',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.premiumCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Smart Tools',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${_smartTools.length} live',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Useful starter tools for planning, prediction, countdowns, and personal academic organization.',
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: compact ? 132 : 140,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List<Widget>.generate(_smartTools.length, (
                        int index,
                      ) {
                        final _SmartToolShortcut tool = _smartTools[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _smartTools.length - 1 ? 0 : 12,
                          ),
                          child: _SmartToolCard(
                            tool: tool,
                            compact: compact,
                            onTap: () => _openTool(tool),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryDark.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textPrimary,
                    tabs: const <Tab>[
                      Tab(text: 'Notes'),
                      Tab(text: 'Workplace'),
                      Tab(text: 'Marketplace'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      ServicesNotesTab(searchQuery: searchQuery),
                      ServicesWorkplaceTab(searchQuery: searchQuery),
                      ServicesMarketplaceTab(searchQuery: searchQuery),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmartToolCard extends StatelessWidget {
  const _SmartToolCard({
    required this.tool,
    required this.compact,
    required this.onTap,
  });

  final _SmartToolShortcut tool;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: compact ? 208 : 220,
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.premiumCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.botBubble,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(tool.icon, color: AppTheme.primaryDark),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tool.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                tool.subtitle,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartToolShortcut {
  const _SmartToolShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.toolType,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final SmartToolType toolType;
}
