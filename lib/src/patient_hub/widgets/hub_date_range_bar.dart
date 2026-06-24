import 'package:flutter/material.dart';

import '../models/patient_hub_models.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.date_range, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'History',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              _chip(context, '7 days', HubDatePreset.last7Days),
              _chip(context, '30 days', HubDatePreset.last30Days),
              _chip(context, '90 days', HubDatePreset.last90Days),
              _chip(context, 'All', HubDatePreset.all),
              _chip(context, 'Custom', HubDatePreset.custom),
              if (preset == HubDatePreset.custom &&
                  (range.from != null || range.to != null))
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _customLabel(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _chip(BuildContext context, String label, HubDatePreset value) {
    final selected = preset == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          if (value == HubDatePreset.custom) {
            onCustomRange();
          } else {
            onPresetChanged(value);
          }
        },
      ),
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
