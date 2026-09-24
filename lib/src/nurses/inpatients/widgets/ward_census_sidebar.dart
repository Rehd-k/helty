import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

/// Quick actions and ward list for the census rail.
class WardCensusSidebar extends StatelessWidget {
  const WardCensusSidebar({
    super.key,
    required this.wards,
    required this.selectedWardId,
    required this.onSelectWard,
    required this.onRefresh,
    required this.onAwaitingClearance,
    this.fillHeight = false,
    this.loadingWards = false,
  });

  final List<Ward> wards;
  final String? selectedWardId;
  final ValueChanged<Ward> onSelectWard;
  final VoidCallback onRefresh;
  final VoidCallback onAwaitingClearance;
  final bool fillHeight;
  final bool loadingWards;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRefresh: onRefresh,
      onAwaitingClearance: onAwaitingClearance,
    );
    final wardsCard = _WardsCard(
      wards: wards,
      selectedWardId: selectedWardId,
      onSelectWard: onSelectWard,
      loading: loadingWards,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [quick, const SizedBox(height: 12), wardsCard],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(child: wardsCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
    required this.onAwaitingClearance,
  });

  final VoidCallback onRefresh;
  final VoidCallback onAwaitingClearance;

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
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: InpatientMetrics.waitAmber,
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
          _GradientActionButton(
            label: 'Refresh Census',
            icon: Icons.refresh,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onRefresh,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Nurses Clearance',
            icon: Icons.fact_check_outlined,
            colors: [
              InpatientMetrics.iconTeal,
              Color.lerp(InpatientMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onAwaitingClearance,
          ),
        ],
      ),
    );
  }
}

class _WardsCard extends StatelessWidget {
  const _WardsCard({
    required this.wards,
    required this.selectedWardId,
    required this.onSelectWard,
    required this.loading,
    this.expanded = false,
  });

  final List<Ward> wards;
  final String? selectedWardId;
  final ValueChanged<Ward> onSelectWard;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget body;
    if (loading && wards.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (wards.isEmpty) {
      body = Text(
        'No inpatient wards.',
        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      );
    } else {
      body = ListView.separated(
        shrinkWrap: !expanded,
        physics: expanded ? null : const NeverScrollableScrollPhysics(),
        itemCount: wards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final ward = wards[i];
          final selected = ward.id == selectedWardId;
          return Material(
            color: selected
                ? InpatientMetrics.iconPurple.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: InkWell(
              onTap: () => onSelectWard(ward),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    HeltySolidIcon(
                      icon: Icons.domain_outlined,
                      color: selected
                          ? InpatientMetrics.iconPurple
                          : InpatientMetrics.iconIndigo,
                      size: 22,
                      iconSize: 12,
                      radius: 6,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HeltyEllipsisText(
                        text: ward.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (ward.capacity > 0)
                      Text(
                        '${ward.capacity}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.apartment_outlined,
                color: InpatientMetrics.iconBlue,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wards',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (expanded) Expanded(child: body) else body,
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
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
