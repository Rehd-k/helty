import 'package:flutter/material.dart';

Widget responsiveFormGrid({
  required List<Widget> children,
  double spacing = 12,
  double runSpacing = 12,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;

      int columns = 1;
      if (width >= 1100) {
        columns = 3;
      } else if (width >= 700) {
        columns = 2;
      }

      final itemWidth = (width - (spacing * (columns - 1))) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children.map((child) {
          return SizedBox(width: itemWidth, child: child);
        }).toList(),
      );
    },
  );
}
