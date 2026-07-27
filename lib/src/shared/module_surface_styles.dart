import 'package:flutter/material.dart';

/// Shared surfaces for department module screens (pharmacy, lab, radiology).
abstract final class ModuleSurfaceStyles {
  static Color departmentScaffoldBackground(
    ThemeData theme,
    Color departmentColor,
  ) {
    return Color.alphaBlend(
      departmentColor.withValues(alpha: 0.07),
      theme.colorScheme.surfaceContainerLowest,
    );
  }

  static BoxDecoration departmentFilterPanel(
    ThemeData theme,
    Color departmentColor,
  ) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          departmentColor.withValues(alpha: 0.12),
          cs.surface,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: departmentColor.withValues(alpha: 0.28)),
    );
  }

  static BoxDecoration borderedSurface(ThemeData theme, {double radius = 12}) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.outlineVariant),
    );
  }

  static BoxDecoration compactDropdown(ThemeData theme) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: cs.outlineVariant),
    );
  }

  static BoxDecoration errorBanner(ThemeData theme) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      color: cs.errorContainer.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.error.withValues(alpha: 0.35)),
    );
  }

  static BoxDecoration infoBanner(ThemeData theme) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      color: cs.tertiaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.tertiary.withValues(alpha: 0.25)),
    );
  }
}
