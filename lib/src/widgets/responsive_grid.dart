import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';

class ModernFormCard extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final Widget? headerAction;
  final Widget? footerAction;
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const ModernFormCard({
    super.key,
    required this.title,
    required this.children,
    this.leadingIcon,
    this.headerAction,
    this.footerAction,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: cs.primary, size: 22),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
                final itemWidth = (width - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: children.map((child) {
                    return SizedBox(width: itemWidth, child: child);
                  }).toList(),
                );
              },
            ),
          ),
          if (footerAction != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: footerAction!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
