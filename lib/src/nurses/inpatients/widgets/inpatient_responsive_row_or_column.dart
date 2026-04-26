import 'package:flutter/material.dart';

import 'inpatient_layout_constants.dart';

/// Two panels side-by-side on wide layouts; stacked when width is below
/// [kInpatientCompactBreakpoint].
class InpatientResponsiveRowOrColumn extends StatelessWidget {
  const InpatientResponsiveRowOrColumn({
    super.key,
    required this.first,
    required this.second,
    this.gap = 16,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget first;
  final Widget second;
  final double gap;
  final CrossAxisAlignment rowCrossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < kInpatientCompactBreakpoint;
        if (narrow) {
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
            Expanded(child: first),
            SizedBox(width: gap),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
