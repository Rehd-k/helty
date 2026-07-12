import 'package:flutter/material.dart';

import 'package:helty/src/core/layout/app_breakpoints.dart';

/// @deprecated Use [AppBreakpoints] from `package:helty/src/core/responsive.dart`.
typedef CmdBreakpointSize = AppBreakpointSize;

/// @deprecated Use [AppBreakpoints] from `package:helty/src/core/responsive.dart`.
@immutable
class CmdBreakpoints {
  const CmdBreakpoints._(this.size, this.maxWidth);

  final AppBreakpointSize size;
  final double maxWidth;

  bool get isMobile => size == AppBreakpointSize.mobile;
  bool get isTablet => size == AppBreakpointSize.tablet;
  bool get isDesktop => size == AppBreakpointSize.desktop;

  static const double maxContentWidth = AppBreakpoints.maxContentWidth;

  factory CmdBreakpoints.fromWidth(double width) {
    final bp = AppBreakpoints.fromWidth(width);
    return CmdBreakpoints._(bp.size, bp.maxWidth);
  }

  double get paddingH => AppBreakpoints.fromWidth(maxWidth).paddingH;
  double get paddingV => AppBreakpoints.fromWidth(maxWidth).paddingV;

  int kpiCrossAxisCount({int mobile = 2, int tablet = 3, int desktop = 5}) {
    return AppBreakpoints.fromWidth(maxWidth).kpiCrossAxisCount(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  double kpiChildAspectRatio({double narrowMobileMax = 360}) {
    return AppBreakpoints.fromWidth(maxWidth).kpiChildAspectRatio(
      narrowMobileMax: narrowMobileMax,
      desktopRatio: 1.6,
      tabletRatio: 1.55,
      mobileRatio: 1.45,
      narrowMobileRatio: 1.35,
    );
  }
}
