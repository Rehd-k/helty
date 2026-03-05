import 'package:flutter/material.dart';

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
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: actions!),
                ],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

