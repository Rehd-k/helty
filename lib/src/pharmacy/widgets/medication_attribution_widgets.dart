import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/utils/medication_request_permissions.dart';

/// Prescribed vs current drug when a substitution occurred.
class MedicationSubstitutionSummary extends StatelessWidget {
  const MedicationSubstitutionSummary({
    super.key,
    required this.prescribedDrug,
    required this.currentDrug,
    this.compact = false,
  });

  final String prescribedDrug;
  final String currentDrug;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = compact
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Prescribed: $prescribedDrug',
          style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Current: $currentDrug',
          style: style?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Prominent prescribing doctor line for top of medication cards.
class PrescribingDoctorLine extends StatelessWidget {
  const PrescribingDoctorLine({
    super.key,
    required this.name,
    this.compact = true,
  });

  final String? name;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final value = name?.trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = compact
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: valueStyle,
          children: [
            TextSpan(text: 'Prescribing doctor: ', style: labelStyle),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/// Staff attribution lines for medication requests / dispense lines.
class MedicationStaffAttributionColumn extends StatelessWidget {
  const MedicationStaffAttributionColumn({
    super.key,
    this.prescribingDoctor,
    this.requestedBy,
    this.substitutedBy,
    this.substitutedAt,
    this.isOpd = false,
    this.compact = true,
    this.excludePrescribingDoctor = false,
  });

  final String? prescribingDoctor;
  final String? requestedBy;
  final String? substitutedBy;
  final DateTime? substitutedAt;
  final bool isOpd;
  final bool compact;
  final bool excludePrescribingDoctor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final valueStyle = compact
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;

    final lines = <Widget>[];
    void addLine(String label, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              style: valueStyle,
              children: [
                TextSpan(text: '$label: ', style: labelStyle),
                TextSpan(text: v),
              ],
            ),
          ),
        ),
      );
    }

    if (!excludePrescribingDoctor) {
      addLine('Prescribing doctor', prescribingDoctor);
    }
    addLine(requestedByColumnLabel(isOpd: isOpd), requestedBy);
    if (substitutedBy != null && substitutedBy!.trim().isNotEmpty) {
      var subLine = substitutedBy!.trim();
      if (substitutedAt != null) {
        subLine =
            '$subLine · ${DateFormatter.dateTime(substitutedAt!.toLocal())}';
      }
      addLine('Substituted by', subLine);
    }

    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines,
    );
  }
}

/// Attribution from a [MedicationRequestModel].
class MedicationRequestAttribution extends StatelessWidget {
  const MedicationRequestAttribution({
    super.key,
    required this.request,
    this.compact = true,
  });

  final MedicationRequestModel request;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final order = request.medicationOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order != null && order.wasSubstituted)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MedicationSubstitutionSummary(
              prescribedDrug: order.prescribedDrugLabel,
              currentDrug: order.currentDrugLabel,
              compact: compact,
            ),
          ),
        MedicationStaffAttributionColumn(
          prescribingDoctor: order?.doctor?.displayName,
          requestedBy: request.requestedByNurse?.displayName,
          substitutedBy: order?.substitutedByPharmacist?.displayName,
          substitutedAt: order?.substitutedAt,
          isOpd: request.isOpdEncounter,
          compact: compact,
        ),
      ],
    );
  }
}
