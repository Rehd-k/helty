import 'package:flutter/material.dart';

/// [DataTable2] builds internal [Column]/[Flexible] layouts that require
/// **bounded max height and width**. Do not place it inside a horizontal
/// [SingleChildScrollView] (unbounded width) or a vertical scroll → [Column]
/// without a height bound.
///
/// Horizontal overflow is handled by [DataTable2.minWidth], not an outer
/// scroll view.
///
/// When placed inside an [Expanded] widget (as in [AccountsAsyncScaffold]), this
/// wrapper fills the remaining viewport height. Otherwise it falls back to a
/// viewport-based estimate.
class AccountsDataTableBox extends StatelessWidget {
  const AccountsDataTableBox({
    super.key,
    required this.child,
    this.heightFactor = 0.75,
    this.minHeight = 260,
    this.maxHeight = 2000,
  });

  final Widget child;

  /// Fraction of estimated available height when parent height is unbounded.
  final double heightFactor;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(minHeight, double.infinity)
            : _fallbackHeight(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: height,
            width: width,
            child: child,
          ),
        );
      },
    );
  }

  double _fallbackHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewportH = media.size.height;
    // App bar, shell chrome, padding, and typical header widgets.
    const chrome = 200.0;
    final available = viewportH - media.padding.vertical - chrome;
    return (available * heightFactor).clamp(minHeight, maxHeight);
  }
}
