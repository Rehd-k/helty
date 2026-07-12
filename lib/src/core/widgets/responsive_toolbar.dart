import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// Toolbar that wraps actions on narrow screens instead of overflowing.
class ResponsiveToolbar extends StatelessWidget {
  const ResponsiveToolbar({
    super.key,
    this.leading,
    required this.actions,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.end,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  final Widget? leading;
  final List<Widget> actions;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bp = AppBreakpoints.fromWidth(width);

        if (bp.isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null) leading!,
              if (leading != null) SizedBox(height: spacing),
              Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                alignment: WrapAlignment.start,
                crossAxisAlignment: crossAxisAlignment,
                children: actions,
              ),
            ],
          );
        }

        if (leading == null) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            alignment: alignment,
            crossAxisAlignment: crossAxisAlignment,
            children: actions,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leading!),
            if (actions.isNotEmpty) SizedBox(width: spacing),
            if (actions.isNotEmpty)
              Flexible(
                fit: FlexFit.loose,
                child: Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: crossAxisAlignment,
                  children: actions,
                ),
              ),
          ],
        );
      },
    );
  }
}
