import 'package:flutter/material.dart';

import '../accounts_breakpoints.dart';
import '../accounts_palette.dart';

class AccountsKpiTile {
  const AccountsKpiTile({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onTap;
}

class AccountsKpiGrid extends StatelessWidget {
  const AccountsKpiGrid({super.key, required this.tiles});

  final List<AccountsKpiTile> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AccountsBreakpoints.fromWidth(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: bp.kpiCrossAxisCount(),
            childAspectRatio: bp.kpiChildAspectRatio(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            final accent = tile.accent ?? AccountsPalette.primary;
            return Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: tile.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (tile.icon != null) ...[
                            Icon(tile.icon, size: 18, color: accent),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              tile.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        tile.value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tile.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tile.subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
