import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../nurses/inpatients/widgets/inpatient_chart_table.dart';
import '../../../widgets/helty_surface.dart';

class EncounterSidePanelChip {
  const EncounterSidePanelChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class EncounterSidePanelBadge {
  const EncounterSidePanelBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;
}

/// Collapsible summary panel for doctor encounter tabs.
///
/// Stacks above content on mobile/tablet; full-height rail from ≥1100.
class EncounterSidePanel extends StatelessWidget {
  const EncounterSidePanel({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggleExpanded,
    this.subtitle,
    this.chips = const [],
    this.railBadges = const [],
    this.controls,
    this.addLabel,
    this.onAdd,
    this.addTooltip,
    this.expandedWidth = 260,
    this.collapsedWidth = 60,
    this.forceStacked = false,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final String? subtitle;
  final List<EncounterSidePanelChip> chips;
  final List<EncounterSidePanelBadge> railBadges;
  final Widget? controls;
  final String? addLabel;
  final VoidCallback? onAdd;
  final String? addTooltip;
  final double expandedWidth;
  final double collapsedWidth;

  /// Stack the summary above content (chart embed or mobile).
  final bool forceStacked;

  @override
  Widget build(BuildContext context) {
    final bp = AppBreakpoints.of(context);
    if (!bp.isDesktop || forceStacked) return _buildMobile(context);
    return _buildSide(context);
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);

    return HeltySurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Row(
                children: [
                  HeltySolidIcon(
                    icon: Icons.summarize_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                    iconSize: 14,
                    radius: 7,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeltyEllipsisText(
                      text: title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: addTooltip ?? addLabel,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _PanelBody(
                subtitle: subtitle,
                chips: chips,
                controls: controls,
                addLabel: addLabel,
                onAdd: onAdd,
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildSide(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? expandedWidth : collapsedWidth,
      child: HeltySurfaceCard(
        padding: const EdgeInsets.all(10),
        child: expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.summarize_outlined,
                        color: Color(0xFF4F46E5),
                        size: 26,
                        iconSize: 14,
                        radius: 7,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: 'Summary',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Collapse panel',
                        visualDensity: VisualDensity.compact,
                        onPressed: onToggleExpanded,
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _PanelBody(
                        subtitle: subtitle,
                        chips: chips,
                        controls: controls,
                        addLabel: addLabel,
                        onAdd: onAdd,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  IconButton(
                    tooltip: 'Expand summary',
                    onPressed: onToggleExpanded,
                    icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (onAdd != null) ...[
                    const SizedBox(height: 8),
                    Tooltip(
                      message: addTooltip ?? addLabel ?? 'Add',
                      child: InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(8),
                        child: HeltySolidIcon(
                          icon: Icons.add_rounded,
                          color: theme.colorScheme.primary,
                          size: 28,
                          iconSize: 16,
                          radius: 8,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final badge in railBadges)
                    _RailBadge(
                      icon: badge.icon,
                      value: badge.value,
                      color: badge.color,
                      tooltip: badge.tooltip,
                    ),
                ],
              ),
      ),
    );
  }
}

class EncounterTabLayout extends StatelessWidget {
  const EncounterTabLayout({
    super.key,
    required this.sidePanel,
    required this.child,
    this.embedded = false,
  });

  final Widget sidePanel;
  final Widget child;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [sidePanel, const SizedBox(height: 10), child],
      );
    }

    final bp = AppBreakpoints.of(context);
    if (!bp.isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidePanel,
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        const SizedBox(width: 12),
        sidePanel,
      ],
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    this.subtitle,
    this.chips = const [],
    this.controls,
    this.addLabel,
    this.onAdd,
  });

  final String? subtitle;
  final List<EncounterSidePanelChip> chips;
  final Widget? controls;
  final String? addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controls != null) ...[controls!, const SizedBox(height: 10)],
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (chips.isNotEmpty) ...[
          if (subtitle != null) const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final chip in chips)
                HeltyStatusChip(label: chip.label, color: chip.color),
            ],
          ),
        ],
        if (onAdd != null && addLabel != null) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(addLabel!),
            style: inpatientCompactFill(),
          ),
        ],
      ],
    );
  }
}

class _RailBadge extends StatelessWidget {
  const _RailBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            HeltySolidIcon(
              icon: icon,
              color: color,
              size: 28,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(height: 4),
            Text(value, style: themeText(context, color)),
          ],
        ),
      ),
    );
  }

  TextStyle themeText(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ) ??
        TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color);
  }
}
