import 'package:flutter/material.dart';

import '../models/theatre_models.dart';

class TheatreStatusChip extends StatelessWidget {
  const TheatreStatusChip({
    super.key,
    required this.status,
  });

  final SurgeryRequestStatus status;

  Color _color(ColorScheme scheme) {
    switch (status) {
      case SurgeryRequestStatus.requested:
        return scheme.tertiary;
      case SurgeryRequestStatus.scheduled:
        return scheme.primary;
      case SurgeryRequestStatus.inProgress:
        return scheme.secondary;
      case SurgeryRequestStatus.completed:
        return Colors.green.shade700;
      case SurgeryRequestStatus.billed:
        return scheme.primaryContainer;
      case SurgeryRequestStatus.cancelled:
        return scheme.error;
    }
  }

  IconData _icon() {
    switch (status) {
      case SurgeryRequestStatus.requested:
        return Icons.pending_actions_outlined;
      case SurgeryRequestStatus.scheduled:
        return Icons.event_outlined;
      case SurgeryRequestStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case SurgeryRequestStatus.completed:
        return Icons.check_circle_outline_rounded;
      case SurgeryRequestStatus.billed:
        return Icons.receipt_long_outlined;
      case SurgeryRequestStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    return Chip(
      avatar: Icon(_icon(), size: 18, color: color),
      label: Text(status.displayLabel),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
