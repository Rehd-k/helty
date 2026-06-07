import 'package:flutter/material.dart';

/// [DataTable2] builds internal [Column]/[Flexible] layouts that require a **bounded
/// max height**. Do not place it directly inside [SingleChildScrollView] → [Column]
/// (unbounded vertical constraint).
///
/// This wrapper gives a viewport-based height so the table can scroll internally.
class AccountsDataTableBox extends StatelessWidget {
  const AccountsDataTableBox({
    super.key,
    required this.child,
    this.heightFactor = 0.42,
    this.minHeight = 260,
    this.maxHeight = 560,
  });

  final Widget child;

  /// Fraction of screen height used for the table area.
  final double heightFactor;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final h = (screenH * heightFactor).clamp(minHeight, maxHeight);
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
        height: h,
        width: double.infinity,
        child: child,
      ),
    );
  }
}
