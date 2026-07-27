import 'package:flutter/material.dart';

/// Hospital-wide department color codes, as approved by the CMD.
///
/// This is the single source of truth for department branding colors used
/// across the sidebar navigation, module headers, and palettes. Pure color
/// constants only — do not add logic here.
///
/// Values are intentionally high-saturation to match the CityCare EHR mockup.
abstract final class DepartmentColors {
  static const outpatientClinic = Color(0xFF3B82F6); // Bright Blue
  static const frontDesk = Color(0xFF14B8A6); // Vivid Teal
  static const billing = Color(0xFFFB923C); // Bright Orange
  static const accountingFinance = Color(0xFFF59E0B); // Hot Amber
  static const pharmacy = Color(0xFF22C55E); // Vivid Green
  static const laboratory = Color(0xFFA855F7); // Bright Purple
  static const radiology = Color(0xFF6366F1); // Bright Indigo
  static const emergency = Color(0xFFEF4444); // Bright Red
  static const icu = Color(0xFFB91C1C); // Crimson
  static const theatre = Color(0xFF06B6D4); // Bright Cyan
  static const maternity = Color(0xFFEC4899); // Hot Pink
  static const obgyn = Color(0xFFF43F5E); // Rose
  static const pediatrics = Color(0xFF38BDF8); // Sky Blue
  static const dental = Color(0xFFD97706); // Warm Brown-Amber
  static const physiotherapy = Color(0xFF84CC16); // Lime
  static const eyeClinic = Color(0xFFA78BFA); // Violet
  static const ent = Color(0xFF2DD4BF); // Turquoise
  static const cardiology = Color(0xFFDC2626); // Deep Red
  static const orthopedics = Color(0xFF64748B); // Slate
  static const dermatology = Color(0xFFFB7185); // Coral
  static const medicalRecords = Color(0xFF94A3B8); // Cool Gray
  static const administration = Color(0xFF1D4ED8); // Strong Navy Blue
  static const itDepartment = Color(0xFF2563EB); // Primary Blue
  static const security = Color(0xFF475569); // Charcoal Slate
}
