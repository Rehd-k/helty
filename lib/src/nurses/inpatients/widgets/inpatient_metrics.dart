import 'package:flutter/material.dart';

/// Accent tiles for inpatient chrome — same palette as Walk-in Queue.
abstract final class InpatientMetrics {
  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconPink = Color(0xFFDB2777);
  static const Color iconIndigo = Color(0xFF4F46E5);
  static const Color waitGreen = Color(0xFF16A34A);
  static const Color waitAmber = Color(0xFFEA580C);
  static const Color waitRed = Color(0xFFDC2626);

  static const double cardBreakpoint = 768;
  static const double sidebarBreakpoint = 1100;

  static Color losColor(int days) {
    if (days >= 14) return waitRed;
    if (days >= 7) return waitAmber;
    return waitGreen;
  }

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }
}
