import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class EncounterTabSpec {
  const EncounterTabSpec({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Tab chrome for doctor encounter (ongoing + completed).
abstract final class EncounterUiTabs {
  static const chart = EncounterTabSpec(
    label: 'Chart',
    icon: Icons.folder_shared_outlined,
    color: InpatientMetrics.iconPurple,
  );
  static const history = EncounterTabSpec(
    label: 'History',
    icon: Icons.history,
    color: InpatientMetrics.iconBlue,
  );
  static const examination = EncounterTabSpec(
    label: 'Examination',
    icon: Icons.accessibility_new_outlined,
    color: InpatientMetrics.iconTeal,
  );
  static const diagnosis = EncounterTabSpec(
    label: 'Diagnosis',
    icon: Icons.medical_information_outlined,
    color: InpatientMetrics.iconPurple,
  );
  static const investigations = EncounterTabSpec(
    label: 'Investigations',
    icon: Icons.biotech_outlined,
    color: InpatientMetrics.iconTeal,
  );
  static const imaging = EncounterTabSpec(
    label: 'Imaging',
    icon: Icons.photo_camera_outlined,
    color: InpatientMetrics.iconIndigo,
  );
  static const surgery = EncounterTabSpec(
    label: 'Surgery',
    icon: Icons.local_hospital_outlined,
    color: InpatientMetrics.waitRed,
  );
  static const prescription = EncounterTabSpec(
    label: 'Prescription',
    icon: Icons.medication_outlined,
    color: InpatientMetrics.waitAmber,
  );
  static const procedures = EncounterTabSpec(
    label: 'Procedures',
    icon: Icons.healing_outlined,
    color: InpatientMetrics.waitAmber,
  );
  static const notes = EncounterTabSpec(
    label: 'Notes',
    icon: Icons.notes_outlined,
    color: InpatientMetrics.iconPink,
  );
  static const admission = EncounterTabSpec(
    label: 'Admission',
    icon: Icons.hotel_outlined,
    color: InpatientMetrics.iconIndigo,
  );
  static const followUp = EncounterTabSpec(
    label: 'Follow-up',
    icon: Icons.event_available_outlined,
    color: InpatientMetrics.waitGreen,
  );
  static const summary = EncounterTabSpec(
    label: 'Summary',
    icon: Icons.folder_shared_outlined,
    color: InpatientMetrics.iconPurple,
  );
  static const labs = EncounterTabSpec(
    label: 'Labs',
    icon: Icons.biotech_outlined,
    color: InpatientMetrics.iconTeal,
  );
  static const rx = EncounterTabSpec(
    label: 'Rx',
    icon: Icons.medication_outlined,
    color: InpatientMetrics.waitAmber,
  );
  static const appointments = EncounterTabSpec(
    label: 'Appointments',
    icon: Icons.event_outlined,
    color: InpatientMetrics.iconBlue,
  );

  static const List<EncounterTabSpec> ongoing = [
    chart,
    history,
    examination,
    diagnosis,
    investigations,
    imaging,
    surgery,
    prescription,
    procedures,
    notes,
    admission,
    followUp,
  ];

  static const List<EncounterTabSpec> completed = [
    summary,
    history,
    examination,
    notes,
    diagnosis,
    labs,
    imaging,
    surgery,
    rx,
    appointments,
    followUp,
  ];
}

class EncounterTabsStrip extends StatelessWidget {
  const EncounterTabsStrip({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onSelect,
  });

  final List<EncounterTabSpec> tabs;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceBright.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _EncounterTabChip(
                  spec: tabs[i],
                  selected: activeIndex == i,
                  onTap: () => onSelect(i),
                  textStyle: theme.textTheme.labelMedium,
                  onSurface: scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EncounterTabChip extends StatelessWidget {
  const _EncounterTabChip({
    required this.spec,
    required this.selected,
    required this.onTap,
    required this.textStyle,
    required this.onSurface,
  });

  final EncounterTabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: selected ? spec.color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeltySolidIcon(
              icon: spec.icon,
              color: spec.color,
              size: 22,
              iconSize: 12,
              radius: 6,
            ),
            const SizedBox(width: 6),
            Text(
              spec.label,
              style: textStyle?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EncounterJumpChip extends StatelessWidget {
  const EncounterJumpChip({
    super.key,
    required this.spec,
    required this.onPressed,
    this.label,
  });

  final EncounterTabSpec spec;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeltySolidIcon(
            icon: spec.icon,
            color: spec.color,
            size: 20,
            iconSize: 11,
            radius: AppTheme.radiusSm,
          ),
          const SizedBox(width: 6),
          Text(label ?? spec.label),
        ],
      ),
    );
  }
}
