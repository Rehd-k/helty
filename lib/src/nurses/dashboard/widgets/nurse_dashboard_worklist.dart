import 'package:flutter/material.dart';

import '../../../core/widgets/patient_avatar.dart';
import '../../../helper/date.formatter.dart';
import '../../../nursing/models/nursing_models.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Assigned inpatients or outpatient queue as table (desktop) / cards (compact).
class NurseDashboardWorklist extends StatelessWidget {
  const NurseDashboardWorklist({
    super.key,
    required this.admissions,
    required this.outpatientQueue,
    required this.useCards,
    required this.emptyMessage,
    this.onOpenAdmission,
  });

  final List<NursingAssignedAdmission> admissions;
  final List<NursingOutpatientQueuePatient> outpatientQueue;
  final bool useCards;
  final String emptyMessage;
  final ValueChanged<NursingAssignedAdmission>? onOpenAdmission;

  bool get _isOpd => admissions.isEmpty && outpatientQueue.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isOpd) {
      return _OpdWorklist(
        patients: outpatientQueue,
        useCards: useCards,
        emptyMessage: emptyMessage,
      );
    }
    return _InpatientWorklist(
      admissions: admissions,
      useCards: useCards,
      emptyMessage: emptyMessage,
      onOpenAdmission: onOpenAdmission,
    );
  }
}

class _CountFooter extends StatelessWidget {
  const _CountFooter({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _InpatientWorklist extends StatelessWidget {
  const _InpatientWorklist({
    required this.admissions,
    required this.useCards,
    required this.emptyMessage,
    this.onOpenAdmission,
  });

  final List<NursingAssignedAdmission> admissions;
  final bool useCards;
  final String emptyMessage;
  final ValueChanged<NursingAssignedAdmission>? onOpenAdmission;

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    if (useCards) {
      return _InpatientCards(
        admissions: admissions,
        emptyMessage: emptyMessage,
        onOpenAdmission: onOpenAdmission,
      );
    }
    return _InpatientTable(
      admissions: admissions,
      emptyMessage: emptyMessage,
      onOpenAdmission: onOpenAdmission,
      colGap: _colGap,
    );
  }
}

class _InpatientTable extends StatelessWidget {
  const _InpatientTable({
    required this.admissions,
    required this.emptyMessage,
    required this.colGap,
    this.onOpenAdmission,
  });

  final List<NursingAssignedAdmission> admissions;
  final String emptyMessage;
  final double colGap;
  final ValueChanged<NursingAssignedAdmission>? onOpenAdmission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget head(String label, {required int flex, bool alignEnd = false}) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    Widget headerRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            head('#', flex: 1),
            SizedBox(width: colGap),
            head('PATIENT', flex: 5),
            SizedBox(width: colGap),
            head('WARD / BED', flex: 3),
            SizedBox(width: colGap),
            head('SHIFT', flex: 3),
            SizedBox(width: colGap),
            head('ACTIONS', flex: 2, alignEnd: true),
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
              child: admissions.isEmpty
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
                      itemCount: admissions.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final a = admissions[index];
                        return Material(
                          color: NurseDashboardMetrics.zebraFill(cs, index),
                          child: InkWell(
                            onTap: a.admissionId.isNotEmpty
                                ? () => onOpenAdmission?.call(a)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: HeltyEllipsisText(
                                      text: '${index + 1}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: colGap),
                                  Expanded(
                                    flex: 5,
                                    child: _PatientIdentity(admission: a),
                                  ),
                                  SizedBox(width: colGap),
                                  Expanded(
                                    flex: 3,
                                    child: HeltyEllipsisText(
                                      text: _location(a),
                                    ),
                                  ),
                                  SizedBox(width: colGap),
                                  Expanded(
                                    flex: 3,
                                    child: HeltyEllipsisText(text: _shift(a)),
                                  ),
                                  SizedBox(width: colGap),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton(
                                          onPressed: a.admissionId.isEmpty
                                              ? null
                                              : () => onOpenAdmission?.call(a),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                          child: const Text('View'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                const minWidth = 720.0;
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
          _CountFooter(
            label: admissions.isEmpty
                ? 'No patients to display'
                : '${admissions.length} assigned patient${admissions.length == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }
}

class _InpatientCards extends StatelessWidget {
  const _InpatientCards({
    required this.admissions,
    required this.emptyMessage,
    this.onOpenAdmission,
  });

  final List<NursingAssignedAdmission> admissions;
  final String emptyMessage;
  final ValueChanged<NursingAssignedAdmission>? onOpenAdmission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (admissions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: admissions.length,
            itemBuilder: (context, i) {
              final a = admissions[i];
              return HeltySurfaceCard(
                margin: const EdgeInsets.only(bottom: 10),
                onTap: a.admissionId.isEmpty
                    ? null
                    : () => onOpenAdmission?.call(a),
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${i + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _PatientIdentity(admission: a)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HeltyEllipsisText(text: _location(a)),
                    const SizedBox(height: 4),
                    HeltyEllipsisText(
                      text: _shift(a),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: a.admissionId.isEmpty
                            ? null
                            : () => onOpenAdmission?.call(a),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _CountFooter(
          label:
              '${admissions.length} assigned patient${admissions.length == 1 ? '' : 's'}',
        ),
      ],
    );
  }
}

class _PatientIdentity extends StatelessWidget {
  const _PatientIdentity({required this.admission});

  final NursingAssignedAdmission admission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = admission.patientName.trim().isNotEmpty
        ? admission.patientName.trim()
        : admission.admissionId;
    final parts = title
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return Row(
      children: [
        PatientAvatar(
          avatarUrl: admission.avatarUrl,
          firstName: parts.isNotEmpty ? parts.first : null,
          surname: parts.length > 1 ? parts.last : null,
          displayName: title,
          size: 32,
          backgroundColor: NurseDashboardMetrics.iconBlue,
          foregroundColor: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (admission.patientNumber?.trim().isNotEmpty == true)
                HeltyEllipsisText(
                  text: 'ID ${admission.patientNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _location(NursingAssignedAdmission a) {
  return [
    if (a.wardName?.trim().isNotEmpty == true) a.wardName!.trim(),
    if (a.bedLabel?.trim().isNotEmpty == true) 'Bed ${a.bedLabel!.trim()}',
  ].join(' · ');
}

String _shift(NursingAssignedAdmission a) {
  final shift = NurseDashboardMetrics.shiftLabel(a.shiftType);
  return [
    if (shift.isNotEmpty) '$shift shift',
    if (a.shiftDate != null) DateFormatter.medicalDate(a.shiftDate!),
  ].join(' · ');
}

class _OpdWorklist extends StatelessWidget {
  const _OpdWorklist({
    required this.patients,
    required this.useCards,
    required this.emptyMessage,
  });

  final List<NursingOutpatientQueuePatient> patients;
  final bool useCards;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (useCards) {
      if (patients.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, i) {
                final p = patients[i];
                return HeltySurfaceCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeltyEllipsisText(
                              text: p.patientName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            HeltyEllipsisText(
                              text: p.serviceName ?? '—',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (p.waitingSince != null)
                        Text(
                          DateFormatter.timeOnly(p.waitingSince!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _CountFooter(
            label:
                '${patients.length} queue patient${patients.length == 1 ? '' : 's'}',
          ),
        ],
      );
    }

    Widget head(String label, {required int flex}) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(
            child: patients.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        child: Row(
                          children: [
                            head('#', flex: 1),
                            const SizedBox(width: 20),
                            head('PATIENT', flex: 5),
                            const SizedBox(width: 20),
                            head('SERVICE', flex: 4),
                            const SizedBox(width: 20),
                            head('WAITING', flex: 2),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: patients.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: cs.outline.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, i) {
                            final p = patients[i];
                            return Material(
                              color: NurseDashboardMetrics.zebraFill(cs, i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: HeltyEllipsisText(
                                        text: '${i + 1}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 5,
                                      child: HeltyEllipsisText(
                                        text: p.patientName,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 4,
                                      child: HeltyEllipsisText(
                                        text: p.serviceName ?? '—',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 2,
                                      child: HeltyEllipsisText(
                                        text: p.waitingSince != null
                                            ? DateFormatter.timeOnly(
                                                p.waitingSince!,
                                              )
                                            : '—',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          _CountFooter(
            label: patients.isEmpty
                ? 'No patients to display'
                : '${patients.length} queue patient${patients.length == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }
}
