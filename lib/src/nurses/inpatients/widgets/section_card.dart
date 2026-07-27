import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';

/// Below this width, [SectionCard] stacks title and action buttons.
const double _kSectionCardStackActionsMaxWidth = 560;

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.all(AppTheme.spaceLg),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppTheme.spaceSm / 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );

                final list = actions;
                if (list == null || list.isEmpty) {
                  return titleBlock;
                }

                final stackActions = constraints.maxWidth <
                        _kSectionCardStackActionsMaxWidth ||
                    list.length > 1;

                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: AppTheme.spaceSm,
                          runSpacing: AppTheme.spaceSm,
                          alignment: WrapAlignment.end,
                          children: list,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    Row(mainAxisSize: MainAxisSize.min, children: list),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceMd),
            child,
          ],
        ),
      ),
    );
  }
}
