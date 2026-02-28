import 'package:flutter/material.dart';

Widget _buildModernTextField(
  ColorScheme colorScheme,
  String label,
  String hint, {
  bool isNumber = false,
}) {
  return TextFormField(
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      filled: true,
      fillColor: colorScheme.onSurface.withValues(alpha: 0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
  );
}
