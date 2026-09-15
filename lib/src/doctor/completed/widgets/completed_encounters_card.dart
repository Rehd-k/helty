import 'package:flutter/material.dart';

import '../../../helper/date.formatter.dart';
import '../../../models/encounter_model.dart';
import '../../../paitients/patient_model.dart';
import '../../../widgets/helty_surface.dart';
import '../completed_encounters_metrics.dart';
import 'completed_encounters_table.dart';

/// Mobile completed-encounter row: stripe, identity, complaint, and actions.
class CompletedEncounterCard extends StatelessWidget {
  const CompletedEncounterCard({
    super.key,
    required this.encounter,
    this.patient,
    required this.doctorLabel,
    required this.indexLabel,
    required this.onView,
    required this.onEditHistory,
  });

  final EncounterModel encounter;
  final Patient? patient;
  final String doctorLabel;
  final String indexLabel;
  final VoidCallback onView;
  final VoidCallback onEditHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final closed = CompletedEncountersMetrics.closedAt(encounter);
    final duration = CompletedEncountersMetrics.duration(encounter);

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onView,
        onDoubleTap: onView,
        child: CompletedUrgencyStripe(
          color: CompletedEncountersMetrics.stripeColor(encounter),
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
                      child: CompletedPatientIdentity(
                        encounter: encounter,
                        patient: patient,
                      ),
                    ),
                    Text(
                      DateFormatter.timeOnly(closed),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                HeltyEllipsisText(
                  text: CompletedEncountersMetrics.complaint(encounter),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                CompletedDoctorCell(
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
                      child: CompletedVisitTypeChip(encounter: encounter),
                    ),
                    SizedBox(
                      width: 110,
                      child: CompletedStatusChip(encounter: encounter),
                    ),
                    if (duration != null)
                      Text(
                        CompletedEncountersMetrics.formatDuration(duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: CompletedEncounterActions(
                    encounter: encounter,
                    onView: onView,
                    onEditHistory: onEditHistory,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompletedEncounterCardList extends StatelessWidget {
  const CompletedEncounterCardList({
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
    required this.onView,
    required this.onEditHistory,
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
  final ValueChanged<EncounterModel> onView;
  final ValueChanged<EncounterModel> onEditHistory;

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
              return CompletedEncounterCard(
                encounter: encounter,
                patient: patientOf(encounter),
                doctorLabel: doctorLabelOf(encounter),
                indexLabel: '${skip + index + 1}',
                onView: () => onView(encounter),
                onEditHistory: () => onEditHistory(encounter),
              );
            },
          ),
        ),
        CompletedPaginationFooter(
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
