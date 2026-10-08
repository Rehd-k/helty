import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:helty/src/core/layout/app_breakpoints.dart';

/// Shared layout thresholds for inpatient nurse/doctor flows.
///
/// Compact layouts follow [AppBreakpoints.tabletMin] and are measured with
/// [LayoutBuilder], not the window width.
const double kInpatientCompactBreakpoint = AppBreakpoints.tabletMin;

/// Full-height utility rail beside main content (Walk-in Queue pattern).
const double kInpatientSidebarBreakpoint = AppBreakpoints.desktopMin;

/// Max width for centered inpatient detail content.
const double kInpatientContentMaxWidth = 1440;

/// Clamps dialog form width so [AlertDialog] content fits small screens.
double inpatientDialogBodyWidth(
  BuildContext context, {
  double preferred = 520,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final pad = MediaQuery.paddingOf(context).horizontal;
  return math.max(260.0, math.min(preferred, width - pad - 32));
}
