import 'package:flutter/material.dart';

import '../../../core/widgets/patient_avatar.dart';
import '../../../helper/date.formatter.dart';
import '../../../helper/theme.dart';
import '../../../models/encounter_model.dart';
import '../../../paitients/patient_model.dart';
import '../../../widgets/helty_surface.dart';
import '../completed_encounters_metrics.dart';

class CompletedEncounterActions extends StatelessWidget {
  const CompletedEncounterActions({
    super.key,
    required this.encounter,
    required this.onView,
    required this.onEditHistory,
  });

  final EncounterModel encounter;
  final VoidCallback onView;
  final VoidCallback onEditHistory;

  bool get _hasEdits => encounter.editMeta?.hasEdits == true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: onView,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const StadiumBorder(),
          ),
          child: const Text('View'),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
              case 'history':
                onEditHistory();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Open encounter')),
            if (_hasEdits)
              const PopupMenuItem(
                value: 'history',
                child: Text('View edit history'),
              ),
          ],
        ),
      ],
    );
  }
}

class CompletedUrgencyStripe extends StatelessWidget {
  const CompletedUrgencyStripe({
    super.key,
    required this.color,
    required this.child,
    this.clip = true,
  });

  final Color color;
  final Widget child;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(color: color, child: const SizedBox(width: 4)),
          Expanded(child: child),
        ],
      ),
    );
    if (!clip) return row;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: row,
    );
  }
}

class CompletedPatientIdentity extends StatelessWidget {
  const CompletedPatientIdentity({
    super.key,
    required this.encounter,
    this.patient,
  });

  final EncounterModel encounter;
  final Patient? patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = CompletedEncountersMetrics.patientName(encounter, patient);
    final mrn = CompletedEncountersMetrics.mrn(patient);
    final phone = CompletedEncountersMetrics.phone(patient);
    final avatarColor = CompletedEncountersMetrics.avatarBlockColor(
      encounter.patientId.isNotEmpty ? encounter.patientId : encounter.id,
    );
    final avatar = patient != null
        ? PatientAvatar.fromPatient(
            patient!,
            size: 36,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            fontWeight: FontWeight.bold,
          )
        : PatientAvatar(
            firstName: name,
            size: 36,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            fontWeight: FontWeight.bold,
          );

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HeltyEllipsisText(
                text: name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (mrn.isNotEmpty)
                HeltyEllipsisText(
                  text: 'MRN: $mrn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (phone != null)
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: HeltyEllipsisText(
                        text: phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CompletedDoctorCell extends StatelessWidget {
  const CompletedDoctorCell({
    super.key,
    required this.encounter,
    required this.doctorLabel,
  });

  final EncounterModel encounter;
  final String doctorLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final created = encounter.createdBy?.displayName.trim() ?? '';
    final showCreated =
        created.isNotEmpty &&
        created != encounter.createdBy?.id &&
        created.toLowerCase() != doctorLabel.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeltyEllipsisText(text: doctorLabel, style: theme.textTheme.bodyMedium),
        if (showCreated)
          HeltyEllipsisText(
            text: 'Created by $created',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class CompletedVisitTypeChip extends StatelessWidget {
  const CompletedVisitTypeChip({super.key, required this.encounter});

  final EncounterModel encounter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = CompletedEncountersMetrics.visitTypeLabel(encounter);
    final color = CompletedEncountersMetrics.colorForVisitType(
      label,
      cs.primary,
    );
    return HeltyEllipsisChip(label: label, color: color);
  }
}

class CompletedStatusChip extends StatelessWidget {
  const CompletedStatusChip({super.key, required this.encounter});

  final EncounterModel encounter;

  @override
  Widget build(BuildContext context) {
    final edited = encounter.editMeta?.hasEdits == true;
    return HeltyEllipsisChip(
      label: edited ? 'Edited' : 'Completed',
      color: edited
          ? CompletedEncountersMetrics.waitAmber
          : CompletedEncountersMetrics.waitGreen,
    );
  }
}

class CompletedPaginationFooter extends StatelessWidget {
  const CompletedPaginationFooter({
    super.key,
    required this.skip,
    required this.pageSize,
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int skip;
  final int pageSize;
  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = shown == 0 ? 0 : skip + 1;
    final end = skip + shown;
    final canPrev = skip > 0;
    final page = (skip ~/ pageSize) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shown == 0
                  ? 'No encounters to display'
                  : 'Showing $start–$end of $total encounters',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class CompletedEncountersTable extends StatelessWidget {
  const CompletedEncountersTable({
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

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footer = CompletedPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: encounters.length,
      total: total,
      hasMore: hasMore,
      onPrev: onPrev,
      onNext: onNext,
    );

    Widget headerRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            _head(context, '#', flex: 1),
            const SizedBox(width: _colGap),
            _head(context, 'PATIENT', flex: 5),
            const SizedBox(width: _colGap),
            _head(context, 'CHIEF COMPLAINT', flex: 4),
            const SizedBox(width: _colGap),
            _head(context, 'DOCTOR', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'CLOSED', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'STATUS', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'ACTIONS', flex: 3, alignEnd: true),
          ],
        ),
      );
    }

    Widget body({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            headerRow(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : encounters.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: encounters.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final encounter = encounters[index];
                        final patient = patientOf(encounter);
                        final closed = CompletedEncountersMetrics.closedAt(
                          encounter,
                        );
                        final duration = CompletedEncountersMetrics.duration(
                          encounter,
                        );
                        return Material(
                          color: CompletedEncountersMetrics.zebraFill(
                            cs,
                            index,
                          ),
                          child: InkWell(
                            onTap: () => onView(encounter),
                            onDoubleTap: () => onView(encounter),
                            child: CompletedUrgencyStripe(
                              color: CompletedEncountersMetrics.stripeColor(
                                encounter,
                              ),
                              clip: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: HeltyEllipsisText(
                                        text: '${skip + index + 1}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 5,
                                      child: CompletedPatientIdentity(
                                        encounter: encounter,
                                        patient: patient,
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 4,
                                      child: HeltyEllipsisText(
                                        text:
                                            CompletedEncountersMetrics.complaint(
                                              encounter,
                                            ),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 3,
                                      child: CompletedDoctorCell(
                                        encounter: encounter,
                                        doctorLabel: doctorLabelOf(encounter),
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          HeltyEllipsisText(
                                            text: DateFormatter.dateTime(
                                              closed,
                                            ),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (duration != null)
                                            HeltyEllipsisText(
                                              text:
                                                  CompletedEncountersMetrics.formatDuration(
                                                    duration,
                                                  ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 2,
                                      child: CompletedStatusChip(
                                        encounter: encounter,
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: CompletedEncounterActions(
                                            encounter: encounter,
                                            onView: () => onView(encounter),
                                            onEditHistory: () =>
                                                onEditHistory(encounter),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                const minWidth = 1100.0;
                final tableWidth = inner.maxWidth < minWidth
                    ? minWidth
                    : inner.maxWidth;
                final sheet = body(width: tableWidth, height: inner.maxHeight);
                if (inner.maxWidth >= minWidth) return sheet;
                return Scrollbar(
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: sheet,
                  ),
                );
              },
            ),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
