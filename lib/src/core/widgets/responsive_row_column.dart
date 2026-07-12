import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// Two panels side-by-side on tablet/desktop; stacked on mobile.
class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn({
    super.key,
    required this.first,
    required this.second,
    this.gap = 16,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.stackWhenWidthBelow,
    this.stackFill = true,
  });

  final Widget first;
  final Widget second;
  final double gap;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final int firstFlex;
  final int secondFlex;

  /// Override breakpoint; defaults to [AppBreakpoints.tabletMin].
  final double? stackWhenWidthBelow;

  /// When stacked vertically, distribute remaining height with [Expanded] if the
  /// parent height is bounded. Set false inside scroll views.
  final bool stackFill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold = stackWhenWidthBelow ?? AppBreakpoints.tabletMin;
        final narrow = constraints.maxWidth < threshold;
        if (narrow) {
          final boundedHeight =
              stackFill && constraints.maxHeight.isFinite;
          if (boundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: firstFlex, child: first),
                SizedBox(height: gap),
                Expanded(flex: secondFlex, child: second),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: gap),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: rowCrossAxisAlignment,
          children: [
            Expanded(flex: firstFlex, child: first),
            SizedBox(width: gap),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}
