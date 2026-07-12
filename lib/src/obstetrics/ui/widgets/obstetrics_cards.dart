import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';
import 'package:helty/src/obstetrics/utils/obstetrics_display.dart';
import 'package:helty/src/paitients/patient_model.dart';

class ObStatChip extends StatelessWidget {
  const ObStatChip({
    super.key,
    required this.label,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onPrimaryContainer;
    final bg = backgroundColor ?? scheme.primaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class ObInfoTile extends StatelessWidget {
  const ObInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = accentColor ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: ObstetricsTheme.borderRadius,
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ObSectionHeader extends StatelessWidget {
  const ObSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ObPatientBanner extends StatelessWidget {
  const ObPatientBanner({
    super.key,
    this.patient,
    this.obstetricsPatient,
    this.subtitle,
  });

  final Patient? patient;
  final ObstetricsPatientRef? obstetricsPatient;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String name = 'Patient';
    String? idLine;
    if (patient != null) {
      name = patient!.displayName.trim();
      if (patient!.patientId.isNotEmpty) {
        idLine = 'ID ${patient!.patientId}';
      } else if (patient!.cardNo.isNotEmpty) {
        idLine = 'Card ${patient!.cardNo}';
      }
    } else if (obstetricsPatient != null) {
      name = obstetricsPatient!.displayName;
      if (name.isEmpty) name = 'Patient';
      idLine = obstetricsPatient!.id.isNotEmpty ? 'ID ${obstetricsPatient!.id}' : null;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        ObstetricsTheme.listHorizontalPadding,
        0,
        ObstetricsTheme.listHorizontalPadding,
        12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.tertiary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: ObstetricsTheme.borderRadius,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (patient != null)
            PatientAvatar.fromPatient(
              patient!,
              size: 40,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
            )
          else
            PatientAvatar(
              avatarUrl: obstetricsPatient?.avatarUrl,
              firstName: obstetricsPatient?.firstName,
              surname: obstetricsPatient?.surname,
              size: 40,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (idLine != null)
                  Text(
                    idLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PregnancySummaryCard extends StatelessWidget {
  const PregnancySummaryCard({
    super.key,
    required this.pregnancy,
    this.onTap,
  });

  final Pregnancy pregnancy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glance = pregnancyAtAGlance(pregnancy);
    final statusColor = pregnancyStatusColor(pregnancy.status, scheme);
    final statusBg = pregnancyStatusContainerColor(pregnancy.status, scheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        elevation: 1,
        shadowColor: statusColor.withValues(alpha: 0.2),
        borderRadius: ObstetricsTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ObstetricsTheme.borderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: ObstetricsTheme.borderRadius,
              border: Border(
                left: BorderSide(color: statusColor, width: 5),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pregnancyGpLabel(pregnancy),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ObStatChip(
                      label: pregnancyStatusLabel(pregnancy.status),
                      color: statusColor,
                      backgroundColor: statusBg,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pregnancyDateRangeLabel(pregnancy),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (glance.gestationalWeeks != null)
                      ObStatChip(
                        label: '${glance.gestationalWeeks} wks GA',
                        icon: Icons.calendar_today_rounded,
                        color: scheme.onSecondaryContainer,
                        backgroundColor: scheme.secondaryContainer,
                      ),
                    ObStatChip(
                      label: formatEddCountdown(glance.daysUntilEdd),
                      icon: Icons.event_rounded,
                      color: scheme.onTertiaryContainer,
                      backgroundColor: scheme.tertiaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.event_note_rounded,
                      label: 'Visits',
                      value: glance.visitCount != null
                          ? '${glance.visitCount}'
                          : '—',
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.local_hospital_rounded,
                      label: 'Deliveries',
                      value: glance.deliveryCount != null
                          ? '${glance.deliveryCount}'
                          : '—',
                    ),
                    const Spacer(),
                    if (glance.lastBp != null)
                      _MiniStat(
                        icon: Icons.favorite_rounded,
                        label: 'Last BP',
                        value: glance.lastBp!,
                      ),
                  ],
                ),
                if (glance.lastFhr != null || glance.lastPresentation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (glance.lastFhr != null) 'FHR ${glance.lastFhr}',
                      if (glance.lastPresentation != null) glance.lastPresentation,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class GynaeProcedureCard extends StatelessWidget {
  const GynaeProcedureCard({
    super.key,
    required this.procedure,
    this.onTap,
  });

  final GynaeProcedure procedure;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasComplications =
        procedure.complications != null && procedure.complications!.trim().isNotEmpty;
    final dateStr = DateFormatter.formatFromBackend(
      procedure.procedureDate,
      DateFormatter.medicalDate,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        elevation: 1,
        borderRadius: ObstetricsTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ObstetricsTheme.borderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: ObstetricsTheme.borderRadius,
              border: Border(
                left: BorderSide(
                  color: hasComplications ? scheme.error : scheme.tertiary,
                  width: 5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ObStatChip(
                        label: procedure.procedureType,
                        color: scheme.onTertiaryContainer,
                        backgroundColor: scheme.tertiaryContainer,
                      ),
                    ),
                    if (hasComplications)
                      ObStatChip(
                        label: 'Complications',
                        icon: Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                        backgroundColor: scheme.errorContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (procedure.findings != null &&
                    procedure.findings!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Findings: ${procedure.findings}',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (procedure.notes != null && procedure.notes!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      procedure.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

/// Hero strip for pregnancy detail screens.
class PregnancyHeroHeader extends StatelessWidget {
  const PregnancyHeroHeader({
    super.key,
    required this.pregnancy,
  });

  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glance = pregnancyAtAGlance(pregnancy);
    final statusColor = pregnancyStatusColor(pregnancy.status, scheme);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: ObstetricsTheme.cardGradientAccent(statusColor, scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pregnancy.patient != null &&
              pregnancy.patient!.displayName.isNotEmpty)
            Text(
              pregnancy.patient!.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                pregnancyGpLabel(pregnancy),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              ObStatChip(
                label: pregnancyStatusLabel(pregnancy.status),
                color: statusColor,
                backgroundColor:
                    pregnancyStatusContainerColor(pregnancy.status, scheme),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (glance.gestationalWeeks != null)
            Text(
              '${glance.gestationalWeeks} weeks gestation',
              style: theme.textTheme.titleMedium,
            ),
          Text(
            formatEddCountdown(glance.daysUntilEdd),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pregnancyDateRangeLabel(pregnancy),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class ObKpiStatCard extends StatelessWidget {
  const ObKpiStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ObstetricsTheme.borderRadius,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AntenatalVisitCard extends StatelessWidget {
  const AntenatalVisitCard({
    super.key,
    required this.visit,
    this.onTap,
  });

  final AntenatalVisit visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final proteinAlert = urineProteinPositive(visit.urineProtein);
    final glucoseAlert = urineDipstickPositive(visit.urineGlucose);
    final alert = proteinAlert || glucoseAlert;
    final (gaWeeks, gaDays) = gestationalAgeParts(visit);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: alert
            ? scheme.errorContainer.withValues(alpha: 0.35)
            : scheme.surface,
        borderRadius: ObstetricsTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ObstetricsTheme.borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatAntenatalVisitDate(visit.visitDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (gaWeeks != null || gaDays != null)
                      ObStatChip(
                        label: formatGestationalAge(gaWeeks, gaDays),
                        backgroundColor: scheme.secondaryContainer,
                        color: scheme.onSecondaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (visit.systolicBP != null && visit.diastolicBP != null)
                      _VitalChip(
                          icon: Icons.favorite, label: 'BP ${visit.systolicBP}/${visit.diastolicBP}'),
                    if (visit.fetalHeartRate != null)
                      _VitalChip(icon: Icons.monitor_heart, label: 'FHR ${visit.fetalHeartRate}'),
                    if (visit.fundalHeight != null)
                      _VitalChip(icon: Icons.height, label: 'FH ${visit.fundalHeight} cm'),
                    if (visit.weight != null)
                      _VitalChip(icon: Icons.scale, label: '${visit.weight} kg'),
                    if (visit.presentation != null)
                      _VitalChip(
                          icon: Icons.child_care,
                          label: formatPresentation(visit.presentation)),
                    if (visit.descent != null && visit.descent!.isNotEmpty)
                      _VitalChip(
                        icon: Icons.arrow_downward,
                        label: 'Descent ${visit.descent}',
                      ),
                    if (visit.urineProtein != null && visit.urineProtein!.isNotEmpty)
                      _VitalChip(
                        icon: Icons.science,
                        label: 'Protein ${visit.urineProtein}',
                        alert: proteinAlert,
                      ),
                    if (visit.urineGlucose != null && visit.urineGlucose!.isNotEmpty)
                      _VitalChip(
                        icon: Icons.water_drop,
                        label: 'Glucose ${visit.urineGlucose}',
                        alert: glucoseAlert,
                      ),
                    if (visit.pcv != null)
                      _VitalChip(
                        icon: Icons.bloodtype,
                        label: 'PCV ${visit.pcv}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip({
    required this.icon,
    required this.label,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = alert ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

class LabourDeliveryCard extends StatelessWidget {
  const LabourDeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
  });

  final LabourDelivery delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final babyCount = delivery.babies?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        borderRadius: ObstetricsTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ObstetricsTheme.borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatFromBackend(
                          delivery.deliveryDateTime,
                          DateFormatter.dateTime,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ObStatChip(
                            label: formatDeliveryMode(delivery.mode),
                            backgroundColor: scheme.primaryContainer,
                            color: scheme.onPrimaryContainer,
                          ),
                          ObStatChip(
                            label: formatDeliveryOutcome(delivery.outcome),
                            backgroundColor: scheme.tertiaryContainer,
                            color: scheme.onTertiaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (babyCount > 0)
                  ObStatChip(
                    label: '$babyCount bab${babyCount == 1 ? 'y' : 'ies'}',
                    icon: Icons.child_care_rounded,
                    backgroundColor: scheme.secondaryContainer,
                    color: scheme.onSecondaryContainer,
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostnatalVisitCard extends StatelessWidget {
  const PostnatalVisitCard({
    super.key,
    required this.visit,
    this.onTap,
  });

  final PostnatalVisit visit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surface,
        borderRadius: ObstetricsTheme.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: ObstetricsTheme.borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ObStatChip(
                            label: formatPostnatalType(visit.type),
                            backgroundColor: visit.type == PostnatalVisitType.MOTHER
                                ? scheme.primaryContainer
                                : scheme.secondaryContainer,
                            color: visit.type == PostnatalVisitType.MOTHER
                                ? scheme.onPrimaryContainer
                                : scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatFromBackend(
                              visit.visitDate,
                              DateFormatter.shortDate,
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (visit.bloodPressure != null) 'BP ${visit.bloodPressure}',
                          if (visit.temperature != null) '${visit.temperature}°C',
                          if (visit.breastfeeding != null) visit.breastfeeding,
                          if (visit.notes != null && visit.notes!.isNotEmpty)
                            visit.notes,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
