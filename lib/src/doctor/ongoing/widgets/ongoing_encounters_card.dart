import 'package:flutter/material.dart';

import '../../../models/encounter_model.dart';
import '../../../paitients/patient_model.dart';
import '../../../widgets/helty_surface.dart';
import '../ongoing_encounters_metrics.dart';
import 'ongoing_encounters_table.dart';

/// Mobile ongoing-encounter row: stripe, identity, complaint, and actions.
class OngoingEncounterCard extends StatelessWidget {
  const OngoingEncounterCard({
    super.key,
    required this.encounter,
    this.patient,
    required this.doctorLabel,
    required this.indexLabel,
    required this.onContinue,
  });

  final EncounterModel encounter;
  final Patient? patient;
  final String doctorLabel;
  final String indexLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onContinue,
        onDoubleTap: onContinue,
        child: OngoingUrgencyStripe(
          color: OngoingEncountersMetrics.stripeColor(encounter),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indexLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OngoingPatientIdentity(
                        encounter: encounter,
                        patient: patient,
                      ),
                    ),
                    OngoingElapsedText(encounter: encounter),
                  ],
                ),
                const SizedBox(height: 10),
                HeltyEllipsisText(
                  text: OngoingEncountersMetrics.complaint(encounter),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                OngoingDoctorCell(
                  encounter: encounter,
                  doctorLabel: doctorLabel,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      child: OngoingVisitTypeChip(encounter: encounter),
                    ),
                    SizedBox(
                      width: 130,
                      child: OngoingStatusChip(encounter: encounter),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OngoingEncounterActions(onContinue: onContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OngoingEncounterCardList extends StatelessWidget {
  const OngoingEncounterCardList({
    super.key,
    required this.encounters,
    required this.patientOf,
    required this.doctorLabelOf,
    required this.skip,
    required this.loading,
    required this.emptyMessage,
    required this.total,
    required this.hasMore,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
    required this.onContinue,
  });

  final List<EncounterModel> encounters;
  final Patient? Function(EncounterModel) patientOf;
  final String Function(EncounterModel) doctorLabelOf;
  final int skip;
  final bool loading;
  final String emptyMessage;
  final int total;
  final bool hasMore;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<EncounterModel> onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (encounters.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: encounters.length,
            itemBuilder: (context, index) {
              final encounter = encounters[index];
              return OngoingEncounterCard(
                encounter: encounter,
                patient: patientOf(encounter),
                doctorLabel: doctorLabelOf(encounter),
                indexLabel: '${skip + index + 1}',
                onContinue: () => onContinue(encounter),
              );
            },
          ),
        ),
        OngoingPaginationFooter(
          skip: skip,
          pageSize: pageSize,
          shown: encounters.length,
          total: total,
          hasMore: hasMore,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}
