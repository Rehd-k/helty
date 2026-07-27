import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';

/// Outlined surface card matching the global [CardTheme] (no elevation).
class HeltySurfaceCard extends StatelessWidget {
  const HeltySurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      margin: margin ?? EdgeInsets.zero,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: card,
    );
  }
}

/// Compact status / department pill used across tables and lists.
class HeltyStatusChip extends StatelessWidget {
  const HeltyStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.dense = true,
  });

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Consistent page body padding for module screens.
class HeltyPagePadding extends StatelessWidget {
  const HeltyPagePadding({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceLg),
      child: child,
    );
  }
}
