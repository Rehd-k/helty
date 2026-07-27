import 'package:flutter/material.dart';

/// Domain accent colors for CMAC oversight screens.
abstract final class CmacPalette {
  static const overview = [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF2DD4BF)];
  static const patientActivity = [Color(0xFF14B8A6), Color(0xFF5EEAD4)];
  static const clinical = [Color(0xFF4F46E5), Color(0xFFC4B5FD)];
  static const laboratory = [Color(0xFFA855F7), Color(0xFFF472B6)];
  static const pharmacy = [Color(0xFF22C55E), Color(0xFFA3E635)];
  static const operations = [Color(0xFFF59E0B), Color(0xFFFB923C)];
  static const quality = [Color(0xFFF43F5E), Color(0xFFFB7185)];
  static const staff = [Color(0xFF3B82F6), Color(0xFF7DD3FC)];
  static const insights = [Color(0xFF8B5CF6), Color(0xFFC4B5FD)];
  static const qualitySafety = [Color(0xFF64748B), Color(0xFF94A3B8)];

  static const chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF22C55E), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFFA855F7), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
  ];

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'warning':
      case 'high':
        return const Color(0xFFF59E0B);
      case 'info':
      case 'low':
      case 'medium':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color trendColor({required bool isPositive}) =>
      isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
}
