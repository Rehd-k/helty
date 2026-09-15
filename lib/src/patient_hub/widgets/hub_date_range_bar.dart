import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../models/patient_hub_models.dart';
import '../patient_hub_metrics.dart';

/// One-row history preset. Custom range lives behind the filter icon.
class HubDateRangeBar extends StatelessWidget {
  const HubDateRangeBar({
    super.key,
    required this.range,
    required this.preset,
    required this.onPresetChanged,
    required this.onCustomRange,
  });

  final PatientHubDateRange range;
  final HubDatePreset preset;
  final ValueChanged<HubDatePreset> onPresetChanged;
  final VoidCallback onCustomRange;

  InputDecoration _decoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: 'History',
      isDense: true,
      prefixIcon: const Padding(
        padding: EdgeInsets.all(6),
        child: HubSolidIcon(
          icon: Icons.date_range_outlined,
          color: PatientHubMetrics.iconIndigo,
          size: 22,
          iconSize: 13,
          radius: 6,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _presetDropdown(BuildContext context) {
    return DropdownButtonFormField<HubDatePreset>(
      key: ValueKey('hub-preset-$preset'),
      initialValue: preset == HubDatePreset.custom ? HubDatePreset.custom : preset,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(context),
      items: [
        const DropdownMenuItem(
          value: HubDatePreset.last7Days,
          child: Text('Last 7 days'),
        ),
        const DropdownMenuItem(
          value: HubDatePreset.last30Days,
          child: Text('Last 30 days'),
        ),
        const DropdownMenuItem(
          value: HubDatePreset.last90Days,
          child: Text('Last 90 days'),
        ),
        const DropdownMenuItem(
          value: HubDatePreset.all,
          child: Text('All history'),
        ),
        DropdownMenuItem(
          value: HubDatePreset.custom,
          child: Text(
            preset == HubDatePreset.custom &&
                    (range.from != null || range.to != null)
                ? _customLabel()
                : 'Custom range',
          ),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        if (v == HubDatePreset.custom) {
          onCustomRange();
        } else {
          onPresetChanged(v);
        }
      },
    );
  }

  String _customLabel() {
    final f = range.from;
    final t = range.to;
    if (f != null && t != null) {
      return '${_short(f)} – ${_short(t)}';
    }
    if (f != null) return 'From ${_short(f)}';
    if (t != null) return 'Until ${_short(t)}';
    return 'Custom range';
  }

  String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final filterButton = IconButton(
      tooltip: 'Custom date range',
      onPressed: onCustomRange,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HubSolidIcon(
        icon: Icons.tune,
        color: PatientHubMetrics.iconPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );

    return Row(
      children: [
        Expanded(child: _presetDropdown(context)),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

PatientHubDateRange dateRangeForPreset(HubDatePreset preset) {
  final now = DateTime.now();
  switch (preset) {
    case HubDatePreset.last7Days:
      return PatientHubDateRange(
        from: now.subtract(const Duration(days: 7)),
        to: now,
      );
    case HubDatePreset.last30Days:
      return PatientHubDateRange(
        from: now.subtract(const Duration(days: 30)),
        to: now,
      );
    case HubDatePreset.last90Days:
      return PatientHubDateRange(
        from: now.subtract(const Duration(days: 90)),
        to: now,
      );
    case HubDatePreset.all:
      return const PatientHubDateRange();
    case HubDatePreset.custom:
      return const PatientHubDateRange();
  }
}
