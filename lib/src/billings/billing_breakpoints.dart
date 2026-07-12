import 'package:flutter/material.dart';

import 'package:helty/src/core/layout/app_breakpoints.dart';

/// @deprecated Use [AppBreakpoints] from `package:helty/src/core/responsive.dart`.
typedef BillingBreakpointSize = AppBreakpointSize;

/// @deprecated Use [AppBreakpoints] from `package:helty/src/core/responsive.dart`.
@immutable
class BillingBreakpoints {
  const BillingBreakpoints._(this.size, this.maxWidth);

  final AppBreakpointSize size;
  final double maxWidth;

  bool get isMobile => size == AppBreakpointSize.mobile;
  bool get isTablet => size == AppBreakpointSize.tablet;
  bool get isDesktop => size == AppBreakpointSize.desktop;

  static const double maxContentWidth = AppBreakpoints.maxContentWidth;

  factory BillingBreakpoints.fromWidth(double width) {
    final bp = AppBreakpoints.fromWidth(width);
    return BillingBreakpoints._(bp.size, bp.maxWidth);
  }

  double get paddingH => AppBreakpoints.fromWidth(maxWidth).paddingH;
  double get paddingV => AppBreakpoints.fromWidth(maxWidth).paddingV;

  int kpiCrossAxisCount({int mobile = 1, int tablet = 2, int desktop = 3}) {
    return AppBreakpoints.fromWidth(maxWidth).gridColumns(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  double get kpiSpacing => AppBreakpoints.fromWidth(maxWidth).kpiSpacing;

  double get chartHeight => AppBreakpoints.fromWidth(maxWidth).chartHeight;

  double get invoiceTableMinWidth => AppBreakpoints.fromWidth(maxWidth).tableMinWidth;
}
