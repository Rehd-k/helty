import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cmd/cmd_breakpoints.dart';
import 'cmac_period_toolbar.dart';
import 'cmac_vibrant_backdrop.dart';

class CmacAnalyticsScaffold extends ConsumerStatefulWidget {
  const CmacAnalyticsScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.accent,
    required this.asyncValue,
    required this.onRefresh,
    required this.builder,
    this.pollInterval,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color accent;
  final AsyncValue<dynamic> asyncValue;
  final VoidCallback onRefresh;
  final Widget Function(BuildContext context, dynamic data) builder;
  final Duration? pollInterval;

  @override
  ConsumerState<CmacAnalyticsScaffold> createState() =>
      _CmacAnalyticsScaffoldState();
}

class _CmacAnalyticsScaffoldState extends ConsumerState<CmacAnalyticsScaffold> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    final interval = widget.pollInterval;
    if (interval != null) {
      _poll = Timer.periodic(interval, (_) => widget.onRefresh());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: CmacVibrantBackdrop(
        colors: widget.colors,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: cs.surface.withValues(alpha: 0.92),
              surfaceTintColor: cs.surfaceTint,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.accent,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bp = CmdBreakpoints.fromWidth(constraints.maxWidth);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: CmdBreakpoints.maxContentWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          bp.paddingH,
                          8,
                          bp.paddingH,
                          bp.paddingV,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CmacPeriodToolbar(
                              accentColor: widget.accent,
                              onRefresh: widget.onRefresh,
                            ),
                            const SizedBox(height: 16),
                            widget.asyncValue.when(
                              data: (data) => widget.builder(context, data),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(48),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (e, _) => _ErrorPanel(
                                error: e.toString(),
                                onRetry: widget.onRefresh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final is403 = error.contains('403') || error.toLowerCase().contains('forbidden');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.error, size: 40),
          const SizedBox(height: 12),
          Text(
            is403
                ? 'Access denied — analytics may require elevated permissions on the API.'
                : 'Could not load analytics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
