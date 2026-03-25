import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_profile.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_branding.dart';
import '../widgets/campus_section_header.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/notification_action_button.dart';
import 'admin_panel_screen.dart';
import 'campus_feed_screen.dart';
import 'settings_screen.dart';
import 'smart_tools_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onSignedOut});

  final Future<void> Function() onSignedOut;

  Future<void> _openQuickDestination(
    BuildContext context, {
    required String title,
    required String description,
    required WidgetBuilder builder,
  }) async {
    try {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: builder));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ProfileFeatureStarterScreen(
            title: title,
            description: description,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider provider, Widget? child) {
        final StudentProfile? profile = provider.studentProfile;
        final String email =
            profile?.email ?? AuthService.currentUser?.email ?? '';
        final String name = profile?.name ?? 'EWU Student';
        final String studentId = profile?.studentId ?? 'Not available';
        final String department = profile?.department ?? 'Unknown';
        final String batch = profile?.batchYear ?? 'Unknown';
        final DateTime? joinedAt = profile?.joinedAt;
        final String role = profile?.role ?? AuthService.currentRole;
        final bool canAccessAdminPanel =
            profile?.canAccessAdminPanel ?? AuthService.canModerateContent;

        return Scaffold(
          backgroundColor: AppTheme.pageTint,
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: <Widget>[
                  CampusSectionHeader(
                    title: 'Profile',
                    subtitle:
                        'Your student identity, campus shortcuts, and assistant settings in one place.',
                    actions: <Widget>[
                      _HeaderRoleChip(label: _roleLabel(role)),
                      NotificationActionButton(),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<SettingsScreen>(
                              builder: (_) =>
                                  SettingsScreen(onSignedOut: onSignedOut),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.botBubble,
                          foregroundColor: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.navyCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final bool compact = constraints.maxWidth < 360;
                                final Widget avatar = CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                  backgroundImage:
                                      profile?.photoUrl.isNotEmpty == true
                                      ? NetworkImage(profile!.photoUrl)
                                      : null,
                                  child: profile?.photoUrl.isEmpty != false
                                      ? Text(
                                          name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                );
                                final Widget identity = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                          ),
                                    ),
                                  ],
                                );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      avatar,
                                      const SizedBox(height: 12),
                                      identity,
                                    ],
                                  );
                                }

                                return Row(
                                  children: <Widget>[
                                    avatar,
                                    const SizedBox(width: 16),
                                    Expanded(child: identity),
                                  ],
                                );
                              },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            const _ProfileTagLogo(),
                            _ProfileTag(label: 'ID: $studentId'),
                            _ProfileTag(label: department),
                            _ProfileTag(label: 'Batch $batch'),
                            _ProfileTag(label: _roleLabel(role)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final bool compact = constraints.maxWidth < 390;
                                final Widget settingsButton =
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<SettingsScreen>(
                                            builder: (_) => SettingsScreen(
                                              onSignedOut: onSignedOut,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.settings_outlined),
                                      label: const Text('Settings'),
                                    );
                                final Widget signOutButton =
                                    ElevatedButton.icon(
                                      onPressed: () => _handleSignOut(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppTheme.primaryDark,
                                      ),
                                      icon: const Icon(Icons.logout_rounded),
                                      label: const Text('Sign Out Safely'),
                                    );

                                if (compact) {
                                  return Column(
                                    children: <Widget>[
                                      SizedBox(
                                        width: double.infinity,
                                        child: settingsButton,
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: signOutButton,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: <Widget>[
                                    Expanded(child: settingsButton),
                                    const SizedBox(width: 12),
                                    Expanded(child: signOutButton),
                                  ],
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoGrid(
                    context,
                    studentId: studentId,
                    department: department,
                    joinedAt: joinedAt,
                  ),
                  const SizedBox(height: 16),
                  _AccessSummaryCard(
                    title: _accessTitle(role),
                    subtitle: _accessSubtitle(role),
                    icon: _accessIcon(role),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick Access',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Each shortcut opens a live screen or a safe starter destination inside EWU Assistant.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canAccessAdminPanel)
                    _QuickAccessCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Panel',
                      badgeLabel: profile?.isSuperAdmin == true
                          ? 'Super Admin'
                          : 'Admin',
                      subtitle: profile?.isSuperAdmin == true
                          ? 'Manage admins, roles, and campus moderation tools'
                          : 'Open your moderation tools and campus admin actions',
                      onTap: () async {
                        await _openQuickDestination(
                          context,
                          title: 'Admin Panel',
                          description:
                              'Your admin workspace is being prepared. Please reopen the panel in a moment.',
                          builder: (_) =>
                              AdminPanelScreen(currentProfile: profile),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        await provider.refreshProfile();
                      },
                    ),
                  if (canAccessAdminPanel) const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'My Routine',
                    badgeLabel: 'Live',
                    subtitle: 'Open your routine lane and daily class view',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'My Routine',
                        description:
                            'Your routine lane will appear here once the routine view is ready on this device.',
                        builder: (_) => const CampusFeedScreen(initialTab: 4),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Smart Routine Generator',
                    badgeLabel: 'Smart',
                    subtitle:
                        'Draft a day-wise class plan and save it into your routine lane',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'Smart Routine Generator',
                        description:
                            'The routine generator starter tool is opening so you can draft classes and save them into your routine.',
                        builder: (_) => const SmartToolsScreen(
                          initialTool: SmartToolType.routineGenerator,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.functions_outlined,
                    title: 'CGPA Predictor',
                    badgeLabel: 'Live',
                    subtitle:
                        'Estimate semester outcomes with a working CGPA calculator',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'CGPA Predictor',
                        description:
                            'The CGPA predictor is opening so you can model credits and expected grades.',
                        builder: (_) => const SmartToolsScreen(
                          initialTool: SmartToolType.cgpaPredictor,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Student Smart Tools',
                    badgeLabel: '5 tools',
                    subtitle:
                        'Open course planner, exam countdown, faculty finder, and more',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'Student Smart Tools',
                        description:
                            'Your academic smart tools hub is opening with planner, countdown, routine, and faculty tools.',
                        builder: (_) => const SmartToolsScreen(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.groups_rounded,
                    title: 'Community Hub',
                    badgeLabel: 'Campus',
                    subtitle:
                        'Jump back into feed, gallery, and student activity',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'Community Hub',
                        description:
                            'The community workspace is opening so you can browse feed, gallery, notices, and routine tabs.',
                        builder: (_) => const CampusFeedScreen(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickAccessCard(
                    icon: Icons.notifications_outlined,
                    title: 'Notices',
                    badgeLabel: 'Official',
                    subtitle: 'Open the notices lane for official updates',
                    onTap: () {
                      _openQuickDestination(
                        context,
                        title: 'Notices',
                        description:
                            'Official notices will appear here once the notices lane finishes loading.',
                        builder: (_) => const CampusFeedScreen(initialTab: 2),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoGrid(
    BuildContext context, {
    required String studentId,
    required String department,
    required DateTime? joinedAt,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = 12;
        final double itemWidth = constraints.maxWidth >= 720
            ? (constraints.maxWidth - (spacing * 2)) / 3
            : constraints.maxWidth >= 420
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _InfoCard(
                label: 'Student ID',
                value: studentId,
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InfoCard(
                label: 'Department',
                value: department,
                icon: Icons.school_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InfoCard(
                label: 'Joined',
                value: joinedAt == null ? 'Unknown' : _formatDate(joinedAt),
                icon: Icons.access_time_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final bool confirmed = await showAppConfirmationDialog(
      context,
      title: 'Sign Out?',
      message:
          'You will return to the login screen and your current campus session will end on this device.',
      confirmLabel: 'Sign Out',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    await AuthService.signOut();
    if (!context.mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
    await onSignedOut();
  }

  static String _formatDate(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  static String _roleLabel(String role) {
    switch (role) {
      case StudentProfile.superAdminRole:
        return 'Super Admin';
      case StudentProfile.adminRole:
        return 'Admin';
      default:
        return 'Student';
    }
  }

  static String _accessTitle(String role) {
    switch (role) {
      case StudentProfile.superAdminRole:
        return 'Super Admin Access';
      case StudentProfile.adminRole:
        return 'Admin Access';
      default:
        return 'Student Access';
    }
  }

  static String _accessSubtitle(String role) {
    switch (role) {
      case StudentProfile.superAdminRole:
        return 'You can manage admins, moderate every campus lane, and oversee notices and community activity.';
      case StudentProfile.adminRole:
        return 'You can moderate campus content across feed, gallery, notices, and community items.';
      default:
        return 'You can use the full student experience across messages, community, services, smart tools, and voice support.';
    }
  }

  static IconData _accessIcon(String role) {
    switch (role) {
      case StudentProfile.superAdminRole:
        return Icons.verified_user_outlined;
      case StudentProfile.adminRole:
        return Icons.shield_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}

class _HeaderRoleChip extends StatelessWidget {
  const _HeaderRoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileTagLogo extends StatelessWidget {
  const _ProfileTagLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const AppLogoMark(size: 24, dark: true, framed: false),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppTheme.primaryDark),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              child: Icon(icon, color: AppTheme.primaryDark),
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
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (badgeLabel != null) ...<Widget>[
                        const SizedBox(width: 10),
                        _QuickAccessBadge(label: badgeLabel!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessBadge extends StatelessWidget {
  const _QuickAccessBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.botBubble,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AccessSummaryCard extends StatelessWidget {
  const _AccessSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppTheme.botBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFeatureStarterScreen extends StatelessWidget {
  const _ProfileFeatureStarterScreen({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageTint,
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    child: const Icon(
                      Icons.rocket_launch_outlined,
                      color: AppTheme.primaryDark,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
