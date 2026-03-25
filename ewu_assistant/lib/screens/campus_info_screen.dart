import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CampusInfoScreen extends StatelessWidget {
  const CampusInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _InfoCard(
            title: 'Address',
            icon: Icons.location_on_outlined,
            lines: <String>[
              'East West University',
              'Plot A/2, Jahurul Islam Avenue',
              'Aftabnagar, Dhaka 1212, Bangladesh',
            ],
          ),
          SizedBox(height: 14),
          _InfoCard(
            title: 'Contact',
            icon: Icons.phone_outlined,
            lines: <String>[
              'Phone: 09666775577',
              'Email: info@ewubd.edu',
              'Website: www.ewubd.edu',
            ],
          ),
          SizedBox(height: 14),
          _InfoCard(
            title: 'Office Hours',
            icon: Icons.schedule_outlined,
            lines: <String>[
              'Administrative offices: Sun to Thu',
              'Typical support hours: 9:00 AM to 5:00 PM',
              'Confirm exact timings before visiting.',
            ],
          ),
          SizedBox(height: 14),
          _InfoCard(
            title: 'Campus Support',
            icon: Icons.support_agent_outlined,
            lines: <String>[
              'Admission office assistance',
              'Accounts and payment helpdesk',
              'Student welfare and club support',
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: AppTheme.primaryDark),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
