import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CampusSectionHeader extends StatelessWidget {
  const CampusSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(width: 12),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(actions.length, (
                      int index,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                        child: actions[index],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
