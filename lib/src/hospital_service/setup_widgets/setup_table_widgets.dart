import 'package:flutter/material.dart';

// --------------------------------------------------------------------------
// Shared reusable table components for the System Setup screen.
// --------------------------------------------------------------------------

/// Fixed-width column spec for a data table.
class SetupColumn {
  const SetupColumn({required this.label, required this.width});
  final String label;
  final double width;
}

/// Sticky header row for a horizontally-scrollable setup table.
class SetupTableHeader extends StatelessWidget {
  const SetupTableHeader({super.key, required this.columns});

  final List<SetupColumn> columns;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: columns
            .map(
              (col) => SizedBox(
                width: col.width,
                child: Text(
                  col.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// One data row in a horizontally-scrollable setup table.
class SetupTableRow extends StatelessWidget {
  const SetupTableRow({super.key, required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: cells,
      ),
    );
  }
}

/// Wraps a table row with right-click / long-press context menu.
/// The menu is placed exactly at the pointer position.
class SetupRowGesture extends StatelessWidget {
  const SetupRowGesture({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.menuEnabled = true,
  });

  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool menuEnabled;

  void _showMenu(BuildContext context, Offset globalPosition) {
    final screenSize = MediaQuery.of(context).size;
    final rect = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      screenSize.width - globalPosition.dx,
      screenSize.height - globalPosition.dy,
    );

    showMenu<String>(
      context: context,
      position: rect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit', style: TextStyle(fontSize: 13)),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') onEdit();
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!menuEnabled) return child;
    return GestureDetector(
      onSecondaryTapDown: (d) => _showMenu(context, d.globalPosition),
      onLongPressStart: (d) => _showMenu(context, d.globalPosition),
      child: Container(color: Colors.transparent, child: child),
    );
  }
}
