import 'package:flutter/material.dart';

class AppContextMenu<T> extends StatelessWidget {
  final Widget child;
  final List<PopupMenuEntry<T>> items;
  final void Function(T value)? onSelected;

  const AppContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) async {
        final selected = await showMenu<T>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: items,
        );

        if (selected != null && onSelected != null) {
          onSelected!(selected);
        }
      },
      child: child,
    );
  }
}
