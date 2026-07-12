import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/cmac/widgets/cmac_vibrant_backdrop.dart';
import 'package:helty/src/core/layout/app_breakpoints.dart';

import '../accounts_palette.dart';

class AccountsAsyncScaffold<T> extends StatelessWidget {
  const AccountsAsyncScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.asyncValue,
    required this.builder,
    this.colors = AccountsPalette.dashboard,
    this.actions,
    this.header,
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) builder;
  final List<Color> colors;
  final List<Widget>? actions;
  final Widget? header;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = colors.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: theme.colorScheme.surfaceTint.withValues(alpha: 0.8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: actions,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CmacVibrantBackdrop(
        colors: colors,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
            final pad = EdgeInsets.fromLTRB(
              bp.paddingH,
              bp.paddingV,
              bp.paddingH,
              32,
            );

            return asyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: pad,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (onRetry != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              data: (data) {
                final content = builder(context, data);
                return Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[
                        header!,
                        const SizedBox(height: 20),
                      ],
                      Expanded(child: content),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AccountsEmptyState extends StatelessWidget {
  const AccountsEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
