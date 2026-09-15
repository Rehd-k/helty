import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../paitients/patient_model.dart';
import '../../patient_chart/models/patient_chart_models.dart';
import '../../widgets/helty_surface.dart';
import '../patient_hub_metrics.dart';

class HubSidebar extends StatelessWidget {
  const HubSidebar({
    super.key,
    required this.patient,
    this.summary,
    this.fullProfile,
    required this.onSearch,
    this.onSelectTab,
    this.fillHeight = false,
  });

  final ChartPatientSummary patient;
  final ChartSummaryCounts? summary;
  final Patient? fullProfile;
  final VoidCallback onSearch;
  final void Function(int index)? onSelectTab;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onSearch: onSearch,
      onSelectTab: onSelectTab,
    );
    final facts = _FactsCard(
      patient: patient,
      summary: summary,
      fullProfile: fullProfile,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          facts,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(child: facts),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onSearch, this.onSelectTab});

  final VoidCallback onSearch;
  final void Function(int index)? onSelectTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HubSolidIcon(
                icon: Icons.flash_on,
                color: PatientHubMetrics.waitAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: 'Back to search',
            icon: Icons.search,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onSearch,
          ),
          if (onSelectTab != null) ...[
            const SizedBox(height: 10),
            _ActionButton(
              label: 'Overview',
              icon: Icons.dashboard_outlined,
              colors: [
                PatientHubMetrics.iconBlue,
                Color.lerp(PatientHubMetrics.iconBlue, cs.primary, 0.25)!,
              ],
              onPressed: () => onSelectTab!(0),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

class _FactsCard extends StatelessWidget {
  const _FactsCard({
    required this.patient,
    this.summary,
    this.fullProfile,
    this.expanded = false,
  });

  final ChartPatientSummary patient;
  final ChartSummaryCounts? summary;
  final Patient? fullProfile;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allergies = fullProfile?.allergies ?? const [];
    final rows = <({String label, String value, Color color})>[
      if (patient.patientId != null)
        (
          label: 'Hospital no.',
          value: patient.patientId!,
          color: PatientHubMetrics.iconBlue,
        ),
      if (summary != null)
        (
          label: 'Encounters',
          value: '${summary!.encounterCount}',
          color: PatientHubMetrics.iconIndigo,
        ),
      if (summary != null)
        (
          label: 'Admissions',
          value: '${summary!.admissionCount}',
          color: PatientHubMetrics.iconTeal,
        ),
      if (allergies.isEmpty)
        (
          label: 'Allergies',
          value: 'None recorded',
          color: PatientHubMetrics.waitGreen,
        )
      else
        (
          label: 'Allergies',
          value: allergies.map((a) => a.name).join(', '),
          color: PatientHubMetrics.waitRed,
        ),
    ];

    final list = ListView(
      shrinkWrap: !expanded,
      physics: expanded ? null : const NeverScrollableScrollPhysics(),
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: row.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      HeltyEllipsisText(
                        text: row.value,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HubSolidIcon(
              icon: Icons.info_outline,
              color: PatientHubMetrics.iconTeal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              'Patient facts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (expanded) Expanded(child: list) else list,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(14), child: body);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }
}
