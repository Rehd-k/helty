import 'package:flutter/material.dart';

/// Shared CMD layout breakpoints (align with financial command center).
enum CmdBreakpointSize { mobile, tablet, desktop }

/// Width-derived layout flags and padding for command-center screens.
@immutable
class CmdBreakpoints {
  const CmdBreakpoints._(this.size, this.maxWidth);

  final CmdBreakpointSize size;
  final double maxWidth;

  bool get isMobile => size == CmdBreakpointSize.mobile;
  bool get isTablet => size == CmdBreakpointSize.tablet;
  bool get isDesktop => size == CmdBreakpointSize.desktop;

  /// Max content width for centered CMD panels (matches financial screen).
  static const double maxContentWidth = 1280;

  static const double _tabletMin = 600;
  static const double _desktopMin = 1100;

  factory CmdBreakpoints.fromWidth(double width) {
    CmdBreakpointSize s;
    if (width >= _desktopMin) {
      s = CmdBreakpointSize.desktop;
    } else if (width >= _tabletMin) {
      s = CmdBreakpointSize.tablet;
    } else {
      s = CmdBreakpointSize.mobile;
    }
    return CmdBreakpoints._(s, width);
  }

  double get paddingH => isMobile ? 16 : 24;
  double get paddingV => isMobile ? 16 : 24;

  /// KPI grid columns: mobile 2, tablet 3, desktop 5 (dashboard-style).
  int kpiCrossAxisCount({int mobile = 2, int tablet = 3, int desktop = 5}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  /// Aspect ratio for KPI tiles; slightly taller on very narrow phones.
  double kpiChildAspectRatio({double narrowMobileMax = 360}) {
    if (isDesktop) return 1.6;
    if (isTablet) return 1.55;
    return maxWidth < narrowMobileMax ? 1.35 : 1.45;
  }
}
