import 'package:flutter/material.dart';

enum AccountsBreakpointSize { mobile, tablet, desktop }

@immutable
class AccountsBreakpoints {
  const AccountsBreakpoints._(this.size, this.maxWidth);

  final AccountsBreakpointSize size;
  final double maxWidth;

  bool get isMobile => size == AccountsBreakpointSize.mobile;
  bool get isTablet => size == AccountsBreakpointSize.tablet;
  bool get isDesktop => size == AccountsBreakpointSize.desktop;

  static const double maxContentWidth = 1280;
  static const double _tabletMin = 600;
  static const double _desktopMin = 1100;

  factory AccountsBreakpoints.fromWidth(double width) {
    AccountsBreakpointSize s;
    if (width >= _desktopMin) {
      s = AccountsBreakpointSize.desktop;
    } else if (width >= _tabletMin) {
      s = AccountsBreakpointSize.tablet;
    } else {
      s = AccountsBreakpointSize.mobile;
    }
    return AccountsBreakpoints._(s, width);
  }

  double get paddingH => isMobile ? 16 : 24;
  double get paddingV => isMobile ? 16 : 24;

  int kpiCrossAxisCount({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  double kpiChildAspectRatio({double narrowMobileMax = 360}) {
    if (isDesktop) return 1.55;
    if (isTablet) return 1.5;
    return maxWidth < narrowMobileMax ? 1.3 : 1.4;
  }
}
