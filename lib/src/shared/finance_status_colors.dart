import 'package:flutter/material.dart';

import 'department_colors.dart';

/// Invoice, payment, and finance KPI colors — use instead of raw [Colors.green] /
/// [Colors.orange] / [Colors.red] in billing and accounts UI.
abstract final class FinanceStatusColors {
  /// Invoice / bill status label color (matches billing dashboard chips).
  static Color invoiceStatus(String status, ColorScheme scheme) {
    final s = status.toUpperCase();
    if (s.contains('PAID') && !s.contains('PARTIAL')) {
      return DepartmentColors.pharmacy;
    }
    if (s.contains('PARTIAL')) return DepartmentColors.billing;
    if (s.contains('PEND')) return DepartmentColors.accountingFinance;
    if (s.contains('CANCEL')) return DepartmentColors.medicalRecords;
    return scheme.primary;
  }

  static Color transactionStatus(String? status, ColorScheme scheme) =>
      switch (status) {
        'PAID' => DepartmentColors.pharmacy,
        'PARTIALLY_PAID' => DepartmentColors.billing,
        'CANCELLED' => DepartmentColors.emergency,
        'REFUNDED' => DepartmentColors.laboratory,
        'ACTIVE' => scheme.primary,
        _ => scheme.onSurface.withValues(alpha: 0.5),
      };

  static Color success(ColorScheme scheme) => DepartmentColors.pharmacy;

  static Color warning(ColorScheme scheme) => DepartmentColors.billing;

  static Color danger(ColorScheme scheme) => scheme.error;

  static Color severity(String severity, ColorScheme scheme) {
    switch (severity.toLowerCase()) {
      case 'high':
        return scheme.error;
      case 'medium':
        return DepartmentColors.billing;
      default:
        return DepartmentColors.accountingFinance;
    }
  }

  static Color trend(String direction, ColorScheme scheme) => switch (direction) {
    'up' => DepartmentColors.pharmacy,
    'down' => scheme.error,
    _ => DepartmentColors.medicalRecords,
  };

  static Color discount(ColorScheme scheme) => DepartmentColors.billing;

  static Color debt(ColorScheme scheme, {required bool hasDebt}) =>
      hasDebt ? scheme.error : scheme.onSurface.withValues(alpha: 0.5);

  static (Color bg, Color fg) clearanceChip(
    String kind,
    ColorScheme scheme,
  ) {
    switch (kind) {
      case 'cleared':
        return (
          DepartmentColors.pharmacy.withValues(alpha: 0.12),
          DepartmentColors.pharmacy,
        );
      case 'pending':
        return (
          DepartmentColors.billing.withValues(alpha: 0.12),
          DepartmentColors.billing,
        );
      case 'blocked':
        return (
          scheme.error.withValues(alpha: 0.1),
          scheme.error,
        );
      default:
        return (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        );
    }
  }
}
