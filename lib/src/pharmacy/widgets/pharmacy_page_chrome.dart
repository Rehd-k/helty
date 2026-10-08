import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/widgets/helty_surface.dart';

/// Shared pharmacy page chrome. Matches the walk-in queue without a live clock.
abstract final class PharmacyAccent {
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0D9488);
  static const purple = Color(0xFF7C3AED);
  static const pink = Color(0xFFDB2777);
  static const indigo = Color(0xFF4F46E5);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFEA580C);

  static const cardBreakpoint = 768.0;
  static const railBreakpoint = 1100.0;
}

class PharmacyKpiItem {
  const PharmacyKpiItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
}

class PharmacyPageHeader extends StatelessWidget {
  const PharmacyPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        HeltySolidIcon(
          icon: icon,
          color: iconColor,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              HeltyEllipsisText(
                text: subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
      ],
    );
  }
}

class PharmacyKpiStrip extends StatelessWidget {
  const PharmacyKpiStrip({super.key, required this.items});

  final List<PharmacyKpiItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) =>
                  SizedBox(width: 200, child: _KpiCard(item: items[i])),
            ),
          );
        }
        if (constraints.maxWidth >= 820) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _KpiCard(item: items[i])),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => _KpiCard(item: items[i]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final PharmacyKpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: item.icon,
            color: item.accent,
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PharmacyFilterButton extends StatelessWidget {
  const PharmacyFilterButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: PharmacyAccent.purple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }
}

InputDecoration pharmacyFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  required IconData icon,
  required Color iconColor,
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    prefixIcon: Padding(
      padding: const EdgeInsets.all(6),
      child: HeltySolidIcon(
        icon: icon,
        color: iconColor,
        size: 22,
        iconSize: 13,
        radius: 6,
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: cs.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    labelStyle: const TextStyle(fontSize: 11),
  );
}

/// Filter dialog aligned to the top right. [child] is the filter body.
Future<void> showPharmacyFilterDialog({
  required BuildContext context,
  required WidgetBuilder body,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final width = MediaQuery.sizeOf(ctx).width;
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(560, width - 32)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const HeltySolidIcon(
                      icon: Icons.tune,
                      color: PharmacyAccent.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                body(ctx),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PharmacyPaginationFooter extends StatelessWidget {
  const PharmacyPaginationFooter({
    super.key,
    required this.label,
    required this.page,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final int page;
  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: HeltyEllipsisText(
              text: label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Color pharmacyZebra(ColorScheme cs, int index) {
  if (index.isEven) return Colors.transparent;
  return cs.onSurface.withValues(alpha: 0.035);
}

class PharmacyRailButton extends StatelessWidget {
  const PharmacyRailButton({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final cs = Theme.of(context).colorScheme;
    final paint = enabled ? colors : [cs.outlineVariant, cs.outline];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: paint),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
