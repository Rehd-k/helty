import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// Wraps wide table content with horizontal scroll and bounded height.
class ResponsiveDataTable extends StatelessWidget {
  const ResponsiveDataTable({
    super.key,
    required this.child,
    this.minWidth,
    this.heightFactor = 0.75,
    this.minHeight = 260,
    this.maxHeight = 2000,
    this.horizontalScrollController,
  });

  final Widget child;
  final double? minWidth;
  final double heightFactor;
  final double minHeight;
  final double maxHeight;
  final ScrollController? horizontalScrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
        final availableW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final configuredMin = minWidth ?? bp.tableMinWidth;
        final tableMinW = math.max(availableW, configuredMin);

        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(minHeight, double.infinity)
            : _fallbackHeight(context);

        final table = Scrollbar(
          controller: horizontalScrollController,
          thumbVisibility: horizontalScrollController != null,
          notificationPredicate: (n) =>
              n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableMinW),
              child: SizedBox(
                height: height,
                child: child,
              ),
            ),
          ),
        );

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: table,
        );
      },
    );
  }

  double _fallbackHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewportH = media.size.height;
    const chrome = 200.0;
    final available = viewportH - media.padding.vertical - chrome;
    return (available * heightFactor).clamp(minHeight, maxHeight);
  }
}
