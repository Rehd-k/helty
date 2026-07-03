import 'package:flutter/material.dart';

/// [DataTable2] builds internal [Column]/[Flexible] layouts that require a **bounded
/// max height**. Do not place it directly inside [SingleChildScrollView] → [Column]
/// (unbounded vertical constraint).
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

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
            ),
          ),
          child: SizedBox(
            height: height,
            width: double.infinity,
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
