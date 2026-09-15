import 'package:flutter/material.dart';

import '../../core/widgets/patient_avatar.dart';
import '../../helper/date.formatter.dart';
import '../../paitients/patient_model.dart';
import '../../patient_chart/models/patient_chart_models.dart';
import '../../widgets/helty_surface.dart';
import '../patient_hub_metrics.dart';

/// Dense identity strip — no gradient.
class HubPatientHeader extends StatelessWidget {
  const HubPatientHeader({
    super.key,
    required this.patient,
    this.fullProfile,
  });

  final ChartPatientSummary patient;
  final Patient? fullProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admitted = patientStatusIsAdmitted(
      fullProfile?.status ?? patient.status,
    );
    final allergies = fullProfile?.allergies ?? const [];

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PatientAvatar(
                avatarUrl: fullProfile?.avatarUrl ?? patient.avatarUrl,
                firstName: patient.firstName ?? fullProfile?.firstName,
                surname: patient.surname ?? fullProfile?.surname,
                displayName: patient.displayName,
                updatedAt: fullProfile?.updatedAt ?? patient.updatedAt,
                size: 40,
                backgroundColor: PatientHubMetrics.iconPurple,
                foregroundColor: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: patient.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (patient.patientId != null)
                          _chip('Hosp. ${patient.patientId}', PatientHubMetrics.iconBlue),
                        if (patient.gender != null)
                          _chip(patient.gender!, PatientHubMetrics.iconIndigo),
                        if (patient.dob != null)
                          _chip(
                            DateFormatter.medicalDate(patient.dob!),
                            PatientHubMetrics.iconTeal,
                          ),
                        if (admitted)
                          _chip(_admissionLine(), PatientHubMetrics.waitAmber),
                        if (patient.hmoName != null &&
                            patient.hmoName!.isNotEmpty)
                          _chip('HMO: ${patient.hmoName}', PatientHubMetrics.iconPink),
                        for (final a in allergies.take(4))
                          _chip(a.name, PatientHubMetrics.waitRed),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _admissionLine() {
    final ward = fullProfile?.ward ?? patient.wardName ?? 'Ward';
    final bed = fullProfile?.bedNumber;
    if (bed != null && bed.isNotEmpty) {
      return 'Admitted · $ward · Bed $bed';
    }
    return 'Admitted · $ward';
  }

  Widget _chip(String label, Color color) {
    return HeltyStatusChip(label: label, color: color, dense: true);
  }
}
