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
      child: padding != null ? Padding(padding: padding!, child: child) : child,
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
  const HeltyPagePadding({super.key, required this.child, this.padding});

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

/// Solid colored icon tile — white glyph on an opaque rounded square.
/// Never use a translucent primary wash for leading icons.
class HeltySolidIcon extends StatelessWidget {
  const HeltySolidIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 32,
    this.iconSize = 16,
    this.radius = 8,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// Single-line (or capped) text with ellipsis and a hover tooltip.
class HeltyEllipsisText extends StatelessWidget {
  const HeltyEllipsisText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.align,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isEmpty ? '—' : text;
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 350),
      child: Text(
        label,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      ),
    );
  }
}

/// Status/department pill that ellipsizes inside its column and tooltips on hover.
class HeltyEllipsisChip extends StatelessWidget {
  const HeltyEllipsisChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 350),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
