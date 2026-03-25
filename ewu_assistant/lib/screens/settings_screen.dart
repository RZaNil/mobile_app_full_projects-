import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student_profile.dart';
import '../providers/chat_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_confirmation_dialog.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onSignedOut});

  final Future<void> Function() onSignedOut;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider provider, Widget? child) {
        final StudentProfile? profile = provider.studentProfile;

        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryDark,
                      backgroundImage: profile?.photoUrl.isNotEmpty == true
                          ? NetworkImage(profile!.photoUrl)
                          : null,
                      child: profile?.photoUrl.isEmpty != false
                          ? Text(
                              (profile?.firstName ?? 'E')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            profile?.name ?? 'EWU Student',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile?.email ??
                                AuthService.currentUser?.email ??
                                'No email loaded',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.glassCard,
                child: SwitchListTile.adaptive(
                  value: provider.autoSpeak,
                  onChanged: provider.setAutoSpeak,
                  title: const Text('Auto-speak responses'),
                  subtitle: const Text(
                    'Read assistant answers out loud after each reply.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: AppTheme.glassCard,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Open profile'),
                      subtitle: const Text('View your student details'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<ProfileScreen>(
                            builder: (_) =>
                                ProfileScreen(onSignedOut: onSignedOut),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      subtitle: const Text('Return to the login screen'),
                      onTap: () async {
                        final bool confirmed = await showAppConfirmationDialog(
                          context,
                          title: 'Sign Out?',
                          message:
                              'You will return to the login screen and pause your current campus session on this device.',
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
                        await onSignedOut();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'About EWU Assistant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'EWU Assistant combines an AI campus helper, voice interaction, student feed, and campus gallery in one Flutter app.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
