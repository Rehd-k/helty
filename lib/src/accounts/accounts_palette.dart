import 'package:flutter/material.dart';

/// Amber palette for Accounts & Audit surfaces — matches the hospital-wide
/// Accounting/Finance department color (see DepartmentColors.accountingFinance).
abstract final class AccountsPalette {
  static const primary = Color(0xFFF59E0B);
  static const secondary = Color(0xFFD97706);
  static const accent = Color(0xFFFBBF24);

  static const List<Color> dashboard = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
    Color(0xFFFBBF24),
  ];

  static const List<Color> reports = [
    Color(0xFFD97706),
    Color(0xFFEA580C),
  ];

  static const List<Color> audit = [
    Color(0xFFB45309),
    Color(0xFF92400E),
  ];
}
