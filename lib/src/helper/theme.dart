import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A class to encapsulate all application theme-related configurations.
///
/// This setup uses Material 3's `ColorScheme.fromSeed` to generate
/// complete, harmonious color palettes for both light and dark themes
/// from a single seed color, ensuring a modern and consistent UI.
class AppTheme {
  // Private constructor to prevent instantiation.
  AppTheme._();

  // Seed colors for generating the color schemes.
  static const _lightSeedColor = Color.fromARGB(
    255,
    255,
    94,
    14,
  ); // A vibrant, light lime green
  static const _darkSeedColor = Colors.deepPurple; // A rich, deep purple

  /// Provides the ThemeData for the light mode.
  static ThemeData get lightTheme {
    // Generate the full color scheme from the seed color.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightSeedColor,
      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme);
  }

  /// Provides the ThemeData for the dark mode.
  static ThemeData get darkTheme {
    // Generate the full color scheme from the seed color.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkSeedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  /// A helper method to build the theme from a ColorScheme.
  /// This centralizes component theme definitions.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    // Define the base text theme using Google Fonts.
    final textTheme =
        GoogleFonts.interTextTheme(
          ThemeData(brightness: colorScheme.brightness).textTheme,
        ).apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,

      // --- Component Themes ---
      appBarTheme: AppBarTheme(
        // A more modern, elevated app bar style.
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurfaceVariant,
        elevation: 2,
      ),

      // dataTableTheme: DataTableThemeData(
      //   decoration: BoxDecoration(
      //     color: Colors.black
      //   )
      // ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
      ),

      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
    );
  }
}
