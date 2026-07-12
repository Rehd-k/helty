import 'package:flutter/material.dart';

import '../../core/widgets/patient_avatar.dart';
import '../../helper/date.formatter.dart';
import '../../paitients/patient_model.dart';
import '../../patient_chart/models/patient_chart_models.dart';

class HubPatientHeader extends StatelessWidget {
  const HubPatientHeader({
    super.key,
    required this.patient,
    this.summary,
    this.fullProfile,
  });

  final ChartPatientSummary patient;
  final ChartSummaryCounts? summary;
  final Patient? fullProfile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final admitted = patientStatusIsAdmitted(
      fullProfile?.status ?? patient.status,
    );
    final allergies = fullProfile?.allergies ?? const [];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.45),
            cs.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatientAvatar(
                  avatarUrl: fullProfile?.avatarUrl ?? patient.avatarUrl,
                  firstName: patient.firstName ?? fullProfile?.firstName,
                  surname: patient.surname ?? fullProfile?.surname,
                  updatedAt: fullProfile?.updatedAt ?? patient.updatedAt,
                  size: 64,
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (patient.patientId != null)
                            _chip(context, 'Hosp. ${patient.patientId}'),
                          if (patient.gender != null)
                            _chip(context, patient.gender!),
                          if (patient.dob != null)
                            _chip(
                              context,
                              DateFormatter.medicalDate(patient.dob!),
                            ),
                          if (patient.phoneNumber != null &&
                              patient.phoneNumber!.isNotEmpty)
                            _chip(context, patient.phoneNumber!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (admitted) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bed_outlined, size: 18, color: cs.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _admissionLine(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (allergies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in allergies)
                    Chip(
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: cs.error,
                      ),
                      label: Text(a.name),
                      backgroundColor: cs.errorContainer.withValues(alpha: 0.5),
                      side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                    ),
                ],
              ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(context, '${summary!.encounterCount}', 'Encounters'),
                  _statChip(context, '${summary!.admissionCount}', 'Admissions'),
                  _statChip(
                    context,
                    '${summary!.archivedEncounterGroupCount}',
                    'Document groups',
                  ),
                  if (patient.hmoName != null && patient.hmoName!.isNotEmpty)
                    _chip(context, 'HMO: ${patient.hmoName}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _admissionLine() {
    final ward = fullProfile?.ward ?? patient.wardName ?? 'Ward';
    final bed = fullProfile?.bedNumber;
    if (bed != null && bed.isNotEmpty) {
      return 'Currently admitted · $ward · Bed $bed';
    }
    return 'Currently admitted · $ward';
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  Widget _statChip(BuildContext context, String value, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
