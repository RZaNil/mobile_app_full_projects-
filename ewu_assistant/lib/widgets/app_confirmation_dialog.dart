import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive
                  ? AppTheme.error
                  : AppTheme.primaryDark,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
