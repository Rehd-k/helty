import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class InpatientChartColumn {
  const InpatientChartColumn(
    this.label, {
    this.flex = 2,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final bool alignEnd;
}

/// Compact tab title + actions (Walk-in header density).
class InpatientTabToolbar extends StatelessWidget {
  const InpatientTabToolbar({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleBlock = Row(
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
              HeltyEllipsisText(
                text: title,
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
      ],
    );

    if (actions.isEmpty) return titleBlock;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        );
      },
    );
  }
}

ButtonStyle inpatientCompactFill() {
  return FilledButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const StadiumBorder(),
  );
}

ButtonStyle inpatientCompactOutline() {
  return OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: const StadiumBorder(),
  );
}

/// Zebra table with 20px gutters, ellipsis cells, pinned row-count footer.
class InpatientChartTable extends StatelessWidget {
  const InpatientChartTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellBuilder,
    this.emptyMessage = 'No records yet.',
    this.minWidth = 720,
    this.footerLabel,
  });

  final List<InpatientChartColumn> columns;
  final int rowCount;
  final List<Widget> Function(BuildContext context, int index) cellBuilder;
  final String emptyMessage;
  final double minWidth;
  final String? footerLabel;

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footerText = footerLabel ??
        (rowCount == 1 ? '1 record' : '$rowCount records');

    Widget header() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: _colGap),
              Expanded(
                flex: columns[i].flex,
                child: HeltyEllipsisText(
                  text: columns[i].label,
                  align: columns[i].alignEnd ? TextAlign.end : TextAlign.start,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget rows() {
      if (rowCount == 0) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }
      return Column(
        children: [
          for (var i = 0; i < rowCount; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: cs.outline.withValues(alpha: 0.08),
              ),
            ColoredBox(
              color: InpatientMetrics.zebraFill(cs, i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    ...() {
                      final cells = cellBuilder(context, i);
                      assert(
                        cells.length == columns.length,
                        'cellBuilder must return ${columns.length} cells',
                      );
                      final out = <Widget>[];
                      for (var c = 0; c < columns.length; c++) {
                        if (c > 0) out.add(const SizedBox(width: _colGap));
                        out.add(
                          Expanded(
                            flex: columns[c].flex,
                            child: columns[c].alignEnd
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: cells[c],
                                  )
                                : cells[c],
                          ),
                        );
                      }
                      return out;
                    }(),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < minWidth
                ? minWidth
                : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header(), rows()],
                ),
              ),
            );
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
          ),
          child: Text(
            footerText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class InpatientKpiTile extends StatelessWidget {
  const InpatientKpiTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
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
                HeltyEllipsisText(
                  text: label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                HeltyEllipsisText(
                  text: value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                if (caption != null)
                  HeltyEllipsisText(
                    text: caption!,
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

class InpatientKpiRow extends StatelessWidget {
  const InpatientKpiRow({super.key, required this.tiles});

  final List<InpatientKpiTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820 && tiles.length >= 3) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth >= 520 ? 2 : 1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => tiles[i],
        );
      },
    );
  }
}
