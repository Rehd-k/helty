import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// Centers content with responsive padding and optional max width.
///
/// When [expand] is true (default), the builder output is given the full
/// viewport height so [Column] + [Expanded] layouts work inside scaffold bodies.
/// Set [expand] to false for scrollable form/detail pages.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.builder,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.bottomPadding = 32,
    this.center = true,
    this.expand = true,
  });

  final Widget Function(BuildContext context, AppBreakpoints bp) builder;
  final double maxWidth;
  final double bottomPadding;
  final bool center;

  /// When true, fills available viewport height so flex children receive bounded
  /// constraints. Use false when the page body is a [SingleChildScrollView].
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
        final pad = EdgeInsets.fromLTRB(
          bp.paddingH,
          bp.paddingV,
          bp.paddingH,
          bottomPadding,
        );

        Widget child = Padding(
          padding: pad,
          child: builder(context, bp),
        );

        if (center) {
          child = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }

        if (expand && constraints.maxHeight.isFinite) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: child,
          );
        }

        return child;
      },
    );
  }
}
