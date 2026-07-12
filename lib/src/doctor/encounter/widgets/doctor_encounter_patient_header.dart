import 'package:flutter/material.dart';

import '../../../core/widgets/patient_avatar.dart';

/// OPD encounter patient summary: name, age, gender, allergies, chronic conditions,
/// past admissions count, insurance. Allergies shown as red badge when present.
class DoctorEncounterPatientHeader extends StatelessWidget {
  final String patientName;
  final String ageGender;
  final String hospitalNumber;
  final List<String> allergies;
  final List<String> chronicConditions;
  final int pastAdmissionsCount;
  final String? insurance;
  final String? doctorName;
  final String doctorLabel;
  final String? lastUpdatedByName;
  final String? avatarUrl;
  final String? firstName;
  final String? surname;

  const DoctorEncounterPatientHeader({
    super.key,
    required this.patientName,
    required this.ageGender,
    required this.hospitalNumber,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.pastAdmissionsCount = 0,
    this.insurance,
    this.doctorName,
    this.doctorLabel = 'Doctor',
    this.lastUpdatedByName,
    this.avatarUrl,
    this.firstName,
    this.surname,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PatientAvatar(
                avatarUrl: avatarUrl,
                firstName: firstName,
                surname: surname,
                size: 52,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                foregroundColor: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _metaChip(
                        context,
                        icon: Icons.badge_outlined,
                        label: hospitalNumber,
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        context,
                        icon: Icons.person_outline,
                        label: ageGender,
                      ),
                      if (doctorName != null && doctorName!.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _metaChip(
                          context,
                          icon: Icons.medical_services_outlined,
                          label: '$doctorLabel: ${doctorName!.trim()}',
                        ),
                      ],
                      if (lastUpdatedByName != null &&
                          lastUpdatedByName!.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _metaChip(
                          context,
                          icon: Icons.edit_outlined,
                          label:
                              'Last updated by: ${lastUpdatedByName!.trim()}',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _infoRow(
                  context,
                  label: 'Past admissions',
                  value: '$pastAdmissionsCount',
                ),
                if (insurance != null && insurance!.isNotEmpty)
                  _infoRow(context, label: 'Insurance', value: insurance!),
                if (chronicConditions.isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Chronic conditions',
                    value: chronicConditions.join(', '),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          if (allergies.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Allergies: ${allergies.join(', ')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceBright,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'No recorded allergies',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
