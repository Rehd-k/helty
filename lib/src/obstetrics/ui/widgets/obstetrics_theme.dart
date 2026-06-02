import 'package:flutter/material.dart';

/// Shared layout constants for the O&G module.
abstract final class ObstetricsTheme {
  static const double contentMaxWidth = 1200;
  static const double cardRadius = 18;
  static const double cardElevation = 0;
  static const double sectionPadding = 20;
  static const double listHorizontalPadding = 20;
  static const double sliverAppBarExpanded = 132;

  static BoxDecoration gradientHeader(ColorScheme scheme) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer.withValues(alpha: 0.85),
          ],
        ),
      );

  static BoxDecoration cardGradientAccent(Color accent, ColorScheme scheme) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            scheme.surface,
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      );

  static BorderRadius get borderRadius => BorderRadius.circular(cardRadius);
}
