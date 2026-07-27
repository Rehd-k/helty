import 'package:flutter/material.dart';

import '../models/ed_enums.dart';
import 'package:helty/src/shared/department_colors.dart';

class EdStatusChip extends StatelessWidget {
  const EdStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final EdWorkflowStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = _colors(status, scheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : null,
        ),
      ),
    );
  }

  (Color, Color) _colors(EdWorkflowStatus status, ColorScheme scheme) {
    switch (status) {
      case EdWorkflowStatus.registered:
      case EdWorkflowStatus.triage:
        return (
          scheme.secondaryContainer.withValues(alpha: 0.7),
          scheme.onSecondaryContainer,
        );
      case EdWorkflowStatus.waitingDoctor:
        return (
          scheme.tertiaryContainer.withValues(alpha: 0.8),
          scheme.onTertiaryContainer,
        );
      case EdWorkflowStatus.inTreatment:
      case EdWorkflowStatus.dispositionPending:
        return (
          scheme.primaryContainer.withValues(alpha: 0.7),
          scheme.onPrimaryContainer,
        );
      case EdWorkflowStatus.admitted:
        return (
          DepartmentColors.pharmacy.withValues(alpha: 0.16),
          DepartmentColors.pharmacy,
        );
      case EdWorkflowStatus.discharged:
      case EdWorkflowStatus.transferred:
        return (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        );
      case EdWorkflowStatus.lwbs:
      case EdWorkflowStatus.cancelled:
        return (
          scheme.errorContainer.withValues(alpha: 0.6),
          scheme.onErrorContainer,
        );
      case EdWorkflowStatus.deceased:
        return (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        );
    }
  }
}
