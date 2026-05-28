import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/cmac/cmac_palette.dart';
import 'package:helty/src/cmac/widgets/cmac_vibrant_backdrop.dart';

import '../cmd_breakpoints.dart';

class CmdAsyncScaffold<T> extends StatelessWidget {
  const CmdAsyncScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.asyncValue,
    required this.builder,
    this.colors = CmacPalette.operations,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) builder;
  final List<Color> colors;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? colors.first;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
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
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CmacVibrantBackdrop(
        colors: colors,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bp = CmdBreakpoints.fromWidth(constraints.maxWidth);
            Widget wrapBody(Widget child) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CmdBreakpoints.maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      bp.paddingH,
                      bp.paddingV,
                      bp.paddingH,
                      bp.paddingV,
                    ),
                    child: child,
                  ),
                ),
              );
            }

            return asyncValue.when(
              data: (data) => wrapBody(builder(context, data)),
              loading: () => wrapBody(
                const Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => wrapBody(
                Center(
                  child: SelectableText(
                    'Error: $e',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
