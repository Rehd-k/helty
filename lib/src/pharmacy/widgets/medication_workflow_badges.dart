import 'package:flutter/material.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_refill_models.dart';

Color medicationOrderStatusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status.trim()) {
    case 'Prescribed':
      return scheme.primary;
    case 'Pending Dispense':
      return scheme.tertiary;
    case 'Dispensed':
      return Colors.green.shade700;
    case 'Cancelled':
      return scheme.onSurface.withValues(alpha: 0.5);
    default:
      return scheme.outline;
  }
}

Color medicationRequestStatusColor(
  BuildContext context,
  MedicationRequestStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case MedicationRequestStatus.requested:
      return scheme.primary;
    case MedicationRequestStatus.billed:
      return scheme.tertiary;
    case MedicationRequestStatus.dispensed:
      return Colors.green.shade700;
    case MedicationRequestStatus.cancelled:
      return scheme.onSurface.withValues(alpha: 0.5);
  }
}

class MedicationOrderStatusBadge extends StatelessWidget {
  const MedicationOrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = medicationOrderStatusColor(context, status);
    return Chip(
      label: Text(status.trim().isEmpty ? '—' : status),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class MedicationRequestStatusBadge extends StatelessWidget {
  const MedicationRequestStatusBadge({super.key, required this.status});

  final MedicationRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = medicationRequestStatusColor(context, status);
    return Chip(
      label: Text(status.label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

Color refillRequestStatusColor(
  BuildContext context,
  RefillRequestStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case RefillRequestStatus.pending:
      return scheme.primary;
    case RefillRequestStatus.approved:
      return scheme.tertiary;
    case RefillRequestStatus.fulfilled:
      return Colors.green.shade700;
    case RefillRequestStatus.rejected:
      return scheme.error;
    case RefillRequestStatus.cancelled:
      return scheme.onSurface.withValues(alpha: 0.5);
  }
}

class RefillRequestStatusBadge extends StatelessWidget {
  const RefillRequestStatusBadge({super.key, required this.status});

  final RefillRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = refillRequestStatusColor(context, status);
    return Chip(
      label: Text(status.label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
