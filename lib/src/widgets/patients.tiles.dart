import 'package:flutter/material.dart';

import '../core/widgets/patient_avatar.dart';
import '../paitients/patient_model.dart';
import 'helty_surface.dart';

/// List tile for patient search / picker results.
class PatientTile extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientTile({super.key, required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return HeltySurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PatientAvatar.fromPatient(patient, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.displayName == 'Unknown'
                      ? patient.patientId
                      : patient.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient ID: ${patient.patientId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  patient.wardHmoDisplayLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (patient.phoneNumber != null &&
                    patient.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _infoBadge(context, Icons.phone_outlined, patient.phoneNumber!),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _infoBadge(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 12, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
