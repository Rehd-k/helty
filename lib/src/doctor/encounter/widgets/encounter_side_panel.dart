import 'package:flutter/material.dart';

import '../../../core/layout/app_breakpoints.dart';

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
/// On mobile it stacks above the main content; on tablet/desktop it sits on
/// the right as an expandable rail.
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
    if (bp.isMobile || forceStacked) return _buildMobile(context);
    return _buildSide(context);
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: addTooltip ?? addLabel,
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? expandedWidth : collapsedWidth,
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
        child: expanded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Summary',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 8),
                    _PanelBody(
                      subtitle: subtitle,
                      chips: chips,
                      controls: controls,
                      addLabel: addLabel,
                      onAdd: onAdd,
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: 'Expand summary',
                    onPressed: onToggleExpanded,
                    icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                  ),
                  if (onAdd != null)
                    IconButton(
                      tooltip: addTooltip ?? addLabel,
                      onPressed: onAdd,
                      icon: Icon(Icons.add_rounded, color: scheme.primary),
                    ),
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
        children: [sidePanel, const SizedBox(height: 12), child],
      );
    }

    final bp = AppBreakpoints.of(context);
    if (bp.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidePanel,
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        const SizedBox(width: 16),
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
        if (controls != null) ...[controls!, const SizedBox(height: 12)],
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
            children: chips
                .map(
                  (chip) => _SummaryChip(
                    icon: chip.icon,
                    label: chip.label,
                    color: chip.color,
                  ),
                )
                .toList(),
          ),
        ],
        if (onAdd != null && addLabel != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(addLabel!),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
