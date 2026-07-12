import 'package:flutter/material.dart';

/// Wraps panel content that uses [Column] + [Expanded] internally.
///
/// When the parent height is bounded, the child fills available space.
/// Otherwise a viewport-based height estimate is applied so flex layouts
/// still receive finite constraints (see [AccountsDataTableBox]).
class FlexPanel extends StatelessWidget {
  const FlexPanel({
    super.key,
    required this.child,
    this.heightFactor = 0.75,
    this.minHeight = 280,
    this.maxHeight = 2000,
    this.chromeHeight = 200,
  });

  final Widget child;

  /// Fraction of estimated available height when parent height is unbounded.
  final double heightFactor;
  final double minHeight;
  final double maxHeight;

  /// App bar, shell chrome, and padding subtracted from viewport height.
  final double chromeHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: child,
          );
        }

        final height = _fallbackHeight(context);
        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: child,
        );
      },
    );
  }

  double _fallbackHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.padding.vertical - chromeHeight;
    return (available * heightFactor).clamp(minHeight, maxHeight);
  }
}
