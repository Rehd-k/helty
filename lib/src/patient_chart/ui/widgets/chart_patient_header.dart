import 'package:flutter/material.dart';

import '../../../helper/date.formatter.dart';
import '../../models/patient_chart_models.dart';

class ChartPatientHeader extends StatelessWidget {
  const ChartPatientHeader({
    super.key,
    required this.patient,
    required this.summary,
  });

  final ChartPatientSummary patient;
  final ChartSummaryCounts summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (patient.patientId != null)
                  _chip(context, 'Hosp. no.', patient.patientId!),
                if (patient.gender != null) _chip(context, 'Gender', patient.gender!),
                if (patient.dob != null)
                  _chip(
                    context,
                    'DOB',
                    DateFormatter.medicalDate(patient.dob!),
                  ),
                if (patient.status != null) _chip(context, 'Status', patient.status!),
                if (patient.wardName != null) _chip(context, 'Ward', patient.wardName!),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryChip(context, 'Encounters', '${summary.encounterCount}'),
                _summaryChip(context, 'Admissions', '${summary.admissionCount}'),
                _summaryChip(
                  context,
                  'Open invoices',
                  '${summary.openInvoiceCount}',
                ),
                _summaryChip(
                  context,
                  'Archived groups',
                  '${summary.archivedEncounterGroupCount}',
                ),
                if (summary.walletBalance != null)
                  _summaryChip(
                    context,
                    'Wallet',
                    summary.walletBalance!.toStringAsFixed(2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _summaryChip(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
