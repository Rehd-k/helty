import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../helper/app_timezone.dart';
import '../../../helper/theme.dart';
import '../../../lab/models/lab_models.dart';
import '../../../widgets/date.filter.dart';
import '../../../widgets/helty_surface.dart';

abstract final class LabClinicalUi {
  static const cardBreakpoint = 768.0;
  static const sidebarBreakpoint = 1100.0;

  static const iconBlue = Color(0xFF2563EB);
  static const iconTeal = Color(0xFF0D9488);
  static const iconPurple = Color(0xFF7C3AED);
  static const iconPink = Color(0xFFDB2777);
  static const iconIndigo = Color(0xFF4F46E5);
  static const iconGreen = Color(0xFF16A34A);
  static const iconAmber = Color(0xFFEA580C);

  static const avatarPalette = <Color>[
    iconBlue,
    iconPurple,
    iconTeal,
    iconAmber,
    iconPink,
    iconGreen,
    Color(0xFF0891B2),
    iconIndigo,
  ];

  static Color avatarColor(String seed) {
    if (seed.isEmpty) return avatarPalette.first;
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return avatarPalette[hash % avatarPalette.length];
  }

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }

  static String statusLabel(LabOrderStatus status) => switch (status) {
    LabOrderStatus.pending => 'Pending',
    LabOrderStatus.sampleCollected => 'Collected',
    LabOrderStatus.processing => 'Processing',
    LabOrderStatus.completed => 'Completed',
    LabOrderStatus.verified => 'Verified',
  };

  static Color statusColor(LabOrderStatus status) => switch (status) {
    LabOrderStatus.pending => iconAmber,
    LabOrderStatus.sampleCollected => iconBlue,
    LabOrderStatus.processing => iconIndigo,
    LabOrderStatus.completed => iconTeal,
    LabOrderStatus.verified => iconGreen,
  };

  static String formatWait(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '<1m';
  }

  static Color waitColor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return iconGreen;
    if (minutes < 30) return const Color(0xFFCA8A04);
    if (minutes < 60) return iconAmber;
    return const Color(0xFFDC2626);
  }

  static Duration? waitSince(DateTime? created, [DateTime? now]) {
    if (created == null) return null;
    final clock = now ?? AppTimezone.now();
    final local = created.isUtc ? created.toLocal() : created;
    final diff = clock.difference(local);
    return diff.isNegative ? Duration.zero : diff;
  }
}

class LabPageHeader extends StatefulWidget {
  const LabPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool compact;

  @override
  State<LabPageHeader> createState() => _LabPageHeaderState();
}

class _LabPageHeaderState extends State<LabPageHeader> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = AppTimezone.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = AppTimezone.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = DateFormat('hh:mm a').format(_now);
    final date = DateFormat('EEE, MMM d, yyyy').format(_now);

    final title = Row(
      children: [
        HeltySolidIcon(
          icon: widget.icon,
          color: widget.iconColor,
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
                text: widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              HeltyEllipsisText(
                text: widget.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final clock = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: LabClinicalUi.iconGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: clock),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        clock,
      ],
    );
  }
}

class LabKpiItem {
  const LabKpiItem({
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

class LabKpiStrip extends StatelessWidget {
  const LabKpiStrip({
    super.key,
    required this.items,
    this.useSnapStrip = false,
  });

  final List<LabKpiItem> items;
  final bool useSnapStrip;

  @override
  Widget build(BuildContext context) {
    if (useSnapStrip) {
      return SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const PageScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) =>
              SizedBox(width: 200, child: _LabKpiCard(item: items[i])),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _LabKpiCard(item: items[i])),
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
          itemBuilder: (context, i) => _LabKpiCard(item: items[i]),
        );
      },
    );
  }
}

class _LabKpiCard extends StatelessWidget {
  const _LabKpiCard({required this.item});

  final LabKpiItem item;

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
                HeltyEllipsisText(
                  text: item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                HeltyEllipsisText(
                  text: item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                HeltyEllipsisText(
                  text: item.caption,
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

class LabFilterBar extends StatelessWidget {
  const LabFilterBar({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.compact,
    required this.onSearchSubmitted,
    required this.filterMenuBody,
    this.primaryFilter,
  });

  final TextEditingController searchController;
  final String searchHint;
  final bool compact;
  final ValueChanged<String> onSearchSubmitted;
  final Widget filterMenuBody;
  final Widget? primaryFilter;

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    IconData? icon,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: icon == null
          ? null
          : Padding(
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
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchController,
      onSubmitted: onSearchSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 12),
      decoration: _decoration(
        context,
        label: 'Search',
        hint: searchHint,
        icon: Icons.search,
        iconColor: LabClinicalUi.iconIndigo,
      ),
    );

    final filterButton = IconButton(
      tooltip: 'Filters',
      onPressed: () => showLabFilterMenu(context, filterMenuBody),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: LabClinicalUi.iconPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );

    if (compact || primaryFilter == null) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 8),
          filterButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: primaryFilter!),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

Future<void> showLabFilterMenu(BuildContext context, Widget body) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const HeltySolidIcon(
                      icon: Icons.tune,
                      color: LabClinicalUi.iconPurple,
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
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class LabDateFilterBody extends StatelessWidget {
  const LabDateFilterBody({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
    required this.onRefresh,
    this.leading,
  });

  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;
  final VoidCallback onRefresh;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null) ...[leading!, const SizedBox(height: 12)],
        Text(
          'Date range',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FromToDateFilter(
          doRefresh: onRefresh,
          dateFilter: true,
          notifyOnInit: false,
          initialFrom: from,
          initialTo: to,
          onFilterChanged: (_, _, nextFrom, nextTo) {
            onChanged(
              nextFrom ?? AppTimezone.startOfDay(),
              nextTo ?? AppTimezone.endOfDay(),
            );
          },
        ),
      ],
    );
  }
}

class LabPaginationFooter extends StatelessWidget {
  const LabPaginationFooter({
    super.key,
    required this.skip,
    required this.pageSize,
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
    this.noun = 'patients',
  });

  final int skip;
  final int pageSize;
  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = shown == 0 ? 0 : skip + 1;
    final end = skip + shown;
    final canPrev = skip > 0;
    final page = (skip ~/ pageSize) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: HeltyEllipsisText(
              text: shown == 0
                  ? 'No $noun to display'
                  : 'Showing $start–$end of $total $noun',
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
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class LabStatusCount {
  const LabStatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class LabSidebar extends StatelessWidget {
  const LabSidebar({
    super.key,
    required this.actions,
    required this.statusCounts,
    this.fillHeight = false,
    this.mixTitle = 'Status mix',
    this.mixEmptyLabel = 'No orders in this range',
  });

  final List<LabQuickAction> actions;
  final List<LabStatusCount> statusCounts;
  final bool fillHeight;
  final String mixTitle;
  final String mixEmptyLabel;

  @override
  Widget build(BuildContext context) {
    final quick = _LabQuickActionsCard(actions: actions);
    final mix = _LabStatusMixCard(
      counts: statusCounts,
      expanded: fillHeight,
      title: mixTitle,
      emptyLabel: mixEmptyLabel,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [quick, const SizedBox(height: 12), mix],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(child: mix),
      ],
    );
  }
}

class LabQuickAction {
  const LabQuickAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;
}

class _LabQuickActionsCard extends StatelessWidget {
  const _LabQuickActionsCard({required this.actions});

  final List<LabQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: LabClinicalUi.iconAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _LabGradientActionButton(action: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _LabGradientActionButton extends StatelessWidget {
  const _LabGradientActionButton({required this.action});

  final LabQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: action.colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(action.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
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

class _LabStatusMixCard extends StatelessWidget {
  const _LabStatusMixCard({
    required this.counts,
    required this.expanded,
    required this.title,
    required this.emptyLabel,
  });

  final List<LabStatusCount> counts;
  final bool expanded;
  final String title;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = counts.isEmpty
        ? Center(
            child: Text(
              emptyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: !expanded,
            physics: expanded
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: counts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = counts[i];
              return Row(
                children: [
                  HeltySolidIcon(
                    icon: Icons.circle,
                    color: row.color,
                    size: 22,
                    iconSize: 8,
                    radius: 6,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HeltyEllipsisText(
                      text: row.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${row.count}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          );

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.pie_chart_outline,
                color: LabClinicalUi.iconTeal,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expanded) Expanded(child: list) else list,
        ],
      ),
    );
  }
}
