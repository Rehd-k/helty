import 'package:flutter/material.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // L'en-tête (The Header)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),

          // La Grille (The Body Grid)
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
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

          // Le pied de page (The Footer)
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
