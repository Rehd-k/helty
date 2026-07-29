import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

/// Wraps wide table content with horizontal scroll and bounded height.
class ResponsiveDataTable extends StatefulWidget {
  const ResponsiveDataTable({
    super.key,
    required this.child,
    this.minWidth,
    this.heightFactor = 0.75,
    this.minHeight = 260,
    this.maxHeight = 2000,
    this.horizontalScrollController,
  });

  final Widget child;
  final double? minWidth;
  final double heightFactor;
  final double minHeight;
  final double maxHeight;
  final ScrollController? horizontalScrollController;

  @override
  State<ResponsiveDataTable> createState() => _ResponsiveDataTableState();
}

class _ResponsiveDataTableState extends State<ResponsiveDataTable> {
  ScrollController? _ownedHorizontalController;

  ScrollController get _horizontalController =>
      widget.horizontalScrollController ?? _ownedHorizontalController!;

  @override
  void initState() {
    super.initState();
    if (widget.horizontalScrollController == null) {
      _ownedHorizontalController = ScrollController();
    }
  }

  @override
  void didUpdateWidget(covariant ResponsiveDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontalScrollController !=
        widget.horizontalScrollController) {
      if (oldWidget.horizontalScrollController == null) {
        _ownedHorizontalController?.dispose();
        _ownedHorizontalController = null;
      }
      if (widget.horizontalScrollController == null) {
        _ownedHorizontalController = ScrollController();
      }
    }
  }

  @override
  void dispose() {
    _ownedHorizontalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
        final availableW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
        final configuredMin = widget.minWidth ?? bp.tableMinWidth;
        final tableMinW = math.max(availableW, configuredMin);

        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(widget.minHeight, double.infinity)
            : _fallbackHeight(context);

        final table = Scrollbar(
          controller: _horizontalController,
          thumbVisibility: widget.horizontalScrollController != null,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            // Horizontal scroll views pass unbounded max width. Pin both
            // min and max so Column/Row stretch children get finite constraints.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tableMinW,
                maxWidth: tableMinW,
              ),
              child: SizedBox(
                height: height,
                child: widget.child,
              ),
            ),
          ),
        );

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: table,
        );
      },
    );
  }

  double _fallbackHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewportH = media.size.height;
    const chrome = 200.0;
    final available = viewportH - media.padding.vertical - chrome;
    return (available * widget.heightFactor).clamp(
      widget.minHeight,
      widget.maxHeight,
    );
  }
}
