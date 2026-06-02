import 'package:flutter/material.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';

/// Shared list screen shell with gradient header for O&G lists.
class ObListScaffold extends StatelessWidget {
  const ObListScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingActionButton,
    this.actions,
    this.header,
    this.filterBar,
    this.errorBanner,
    this.onRefresh,
    this.isLoading = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final Widget? header;
  final Widget? filterBar;
  final Widget? errorBanner;
  final Future<void> Function()? onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      floatingActionButton: floatingActionButton,
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: ObstetricsTheme.sliverAppBarExpanded,
              pinned: true,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              actions: actions,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Container(
                  decoration: ObstetricsTheme.gradientHeader(scheme),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 48),
                        child: Icon(
                          Icons.pregnant_woman_rounded,
                          size: 56,
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (subtitle != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (errorBanner != null)
              SliverToBoxAdapter(child: errorBanner!),
            if (header != null) SliverToBoxAdapter(child: header!),
            if (filterBar != null) SliverToBoxAdapter(child: filterBar!),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverToBoxAdapter(child: body),
          ],
        ),
      ),
    );
  }
}

/// Horizontal filter chips row.
class ObFilterChipRow extends StatelessWidget {
  const ObFilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ObstetricsTheme.listHorizontalPadding,
        8,
        ObstetricsTheme.listHorizontalPadding,
        12,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[i]),
                selected: selected,
                onSelected: (_) => onSelected(i),
                showCheckmark: false,
              ),
            );
          }),
        ),
      ),
    );
  }
}
