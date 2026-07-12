import 'package:flutter/material.dart';

/// Shared app-wide layout breakpoints (mobile / tablet / desktop).
enum AppBreakpointSize { mobile, tablet, desktop }

/// Width-derived layout flags and padding for all screens.
@immutable
class AppBreakpoints {
  const AppBreakpoints._(this.size, this.maxWidth);

  final AppBreakpointSize size;
  final double maxWidth;

  bool get isMobile => size == AppBreakpointSize.mobile;
  bool get isTablet => size == AppBreakpointSize.tablet;
  bool get isDesktop => size == AppBreakpointSize.desktop;

  /// Max content width for centered panels.
  static const double maxContentWidth = 1280;

  static const double tabletMin = 600;
  static const double desktopMin = 1100;

  factory AppBreakpoints.fromWidth(double width) {
    AppBreakpointSize s;
    if (width >= desktopMin) {
      s = AppBreakpointSize.desktop;
    } else if (width >= tabletMin) {
      s = AppBreakpointSize.tablet;
    } else {
      s = AppBreakpointSize.mobile;
    }
    return AppBreakpoints._(s, width);
  }

  factory AppBreakpoints.of(BuildContext context) {
    return AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width);
  }

  double get paddingH => isMobile ? 16 : 24;
  double get paddingV => isMobile ? 16 : 24;

  EdgeInsets get padding =>
      EdgeInsets.fromLTRB(paddingH, paddingV, paddingH, paddingV);

  /// KPI / tile grid columns.
  int gridColumns({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  /// Alias kept for accounts/cmd-style KPI grids.
  int kpiCrossAxisCount({int mobile = 2, int tablet = 3, int desktop = 4}) {
    return gridColumns(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Aspect ratio for KPI tiles; slightly taller on very narrow phones.
  double kpiChildAspectRatio({
    double narrowMobileMax = 360,
    double desktopRatio = 1.55,
    double tabletRatio = 1.5,
    double mobileRatio = 1.4,
    double narrowMobileRatio = 1.3,
  }) {
    if (isDesktop) return desktopRatio;
    if (isTablet) return tabletRatio;
    return maxWidth < narrowMobileMax ? narrowMobileRatio : mobileRatio;
  }

  double get kpiSpacing => isMobile ? 12 : 16;

  double get chartHeight => isMobile ? 320 : 380;

  /// Minimum width for horizontally scrollable tables on mobile.
  double get tableMinWidth => isMobile ? 720 : 0;

  /// Dialog width clamped to screen.
  double dialogWidth(BuildContext context, {double max = 560}) {
    final screenW = MediaQuery.sizeOf(context).width;
    return (max).clamp(0, screenW - 32).toDouble();
  }

  /// Whether side-by-side panels should stack vertically.
  bool get stackPanels => isMobile;

  /// Whether persistent sidebar navigation should show.
  bool get showSidebar => isDesktop;
}
