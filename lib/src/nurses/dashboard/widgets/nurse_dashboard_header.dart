import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../helper/app_timezone.dart';
import '../../../helper/theme.dart';
import '../../../models/nurse_dashboard_models.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Title, unit line, and live clock for the nursing dashboard.
class NursesDashboardHeader extends StatefulWidget {
  const NursesDashboardHeader({
    super.key,
    required this.header,
    this.unitLine,
    this.compact = false,
  });

  final NurseDashboardHeader header;
  final String? unitLine;
  final bool compact;

  @override
  State<NursesDashboardHeader> createState() => _NursesDashboardHeaderState();
}

class _NursesDashboardHeaderState extends State<NursesDashboardHeader> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = AppTimezone.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = AppTimezone.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = DateFormat('hh:mm a').format(_now);
    final date = DateFormat('EEE, MMM d, yyyy').format(_now);
    final title = widget.header.title?.trim().isNotEmpty == true
        ? widget.header.title!.trim()
        : 'Nursing Dashboard';
    final subtitle = NurseDashboardMetrics.resolvedSubtitle(widget.header);
    final unit = widget.unitLine?.trim() ?? '';

    final titleBlock = Row(
      children: [
        const HeltySolidIcon(
          icon: Icons.monitor_heart_outlined,
          color: NurseDashboardMetrics.iconPurple,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              HeltyEllipsisText(
                text: unit.isNotEmpty ? '$subtitle · $unit' : subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final clock = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: NurseDashboardMetrics.waitGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: clock),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        clock,
      ],
    );
  }
}
