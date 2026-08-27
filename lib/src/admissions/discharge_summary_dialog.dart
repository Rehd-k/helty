import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/admission_model.dart';

/// Read-only discharge summary + linked encounter for bedside view.
Future<void> showDischargeSummaryDialog({
  required BuildContext context,
  required AdmissionModel admission,
  VoidCallback? onOpenEncounter,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _DischargeSummaryDialog(
      admission: admission,
      onOpenEncounter: onOpenEncounter,
    ),
  );
}

class _DischargeSummaryDialog extends StatelessWidget {
  const _DischargeSummaryDialog({
    required this.admission,
    this.onOpenEncounter,
  });

  final AdmissionModel admission;
  final VoidCallback? onOpenEncounter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final encounter = admission.encounter;
    final encounterId = admission.encounterId?.trim();
    final hasEncounter = encounterId != null && encounterId.isNotEmpty;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    Widget kv(String label, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(v, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    String? formatInstant(DateTime? dt) =>
        dt == null ? null : DateFormatter.dateTime(dt);

    final encounterType = encounter?['encounterType']?.toString();
    final encounterStatus = encounter?['status']?.toString();
    final chiefComplaint = encounter?['chiefComplaint']?.toString();
    final visitType = encounter?['visitType']?.toString();
    final startTime = encounter?['startTime'] != null
        ? DateTime.tryParse(encounter!['startTime'].toString())
        : null;
    final endTime = encounter?['endTime'] != null
        ? DateTime.tryParse(encounter!['endTime'].toString())
        : null;
    final primaryDx = [
      encounter?['primaryIcdCode']?.toString(),
      encounter?['primaryIcdDescription']?.toString(),
    ].where((s) => s != null && s.trim().isNotEmpty).join(' — ');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Discharge summary'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              sectionTitle('Clinical discharge'),
              kv('Outcome', admission.outcome),
              kv(
                'Discharged',
                formatInstant(
                  admission.dischargeDateTime ??
                      admission.clinicallyDischargedAt ??
                      admission.dischargeDate,
                ),
              ),
              kv(
                'Discharged by',
                admission.clinicallyDischargedBy?.displayName,
              ),
              kv('Status', admission.status),
              if ((admission.dischargeSummary ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Summary',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    admission.dischargeSummary!.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              if ((admission.otherImportantNotes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Other notes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  admission.otherImportantNotes!.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (admission.billingClearedAt != null ||
                  admission.nursesClearedAt != null) ...[
                const SizedBox(height: 16),
                sectionTitle('Clearance'),
                kv('Billing cleared', formatInstant(admission.billingClearedAt)),
                kv(
                  'Billing cleared by',
                  admission.billingClearedBy?.displayName,
                ),
                kv('Nurses cleared', formatInstant(admission.nursesClearedAt)),
                kv(
                  'Nurses cleared by',
                  admission.nursesClearedBy?.displayName,
                ),
              ],
              const SizedBox(height: 16),
              sectionTitle('Admission encounter'),
              if (!hasEncounter)
                Text(
                  'No encounter linked to this admission.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else ...[
                kv('Encounter ID', encounterId),
                kv('Type', encounterType),
                kv('Visit type', visitType),
                kv('Status', encounterStatus),
                kv('Started', formatInstant(startTime)),
                kv('Ended', formatInstant(endTime)),
                kv('Chief complaint', chiefComplaint),
                if (primaryDx.isNotEmpty) kv('Primary diagnosis', primaryDx),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (hasEncounter && onOpenEncounter != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenEncounter!();
            },
            child: const Text('Open encounter'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
