import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/widgets/helty_surface.dart';

/// Below this width, [SectionCard] stacks title and action buttons.
const double _kSectionCardStackActionsMaxWidth = 560;

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  final Color? iconColor;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.all(10),
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return HeltySurfaceCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    HeltySolidIcon(
                      icon: icon!,
                      color: iconColor ?? colorScheme.primary,
                      size: 26,
                      iconSize: 14,
                      radius: 7,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeltyEllipsisText(
                          text: title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          HeltyEllipsisText(
                            text: subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );

              final list = actions;
              if (list == null || list.isEmpty) {
                return titleBlock;
              }

              final stackActions =
                  constraints.maxWidth < _kSectionCardStackActionsMaxWidth ||
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
