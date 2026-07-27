import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/shared/department_colors.dart';

/// App-wide floating snackbar aligned with [SnackBarTheme].
void showSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final accent =
      isError ? DepartmentColors.emergency : DepartmentColors.pharmacy;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.inverseSurface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onInverseSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
