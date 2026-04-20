import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Navigation chrome derived from [ColorScheme] — sidebar, title bar gradient, and
/// content backdrop. Use [AppShellTheme.of] below; do not hardcode parallel hex
/// palettes for the shell.
@immutable
class AppShellTheme extends ThemeExtension<AppShellTheme> {
  const AppShellTheme({
    required this.sidebarBackground,
    required this.sidebarHover,
    required this.sidebarActiveContainer,
    required this.sidebarSelectedRow,
    required this.sidebarOnBackground,
    required this.sidebarOnActive,
    required this.sidebarMuted,
    required this.sidebarDivider,
    required this.sidebarAccent,
    required this.contentBackground,
    required this.titleBarGradientStart,
    required this.titleBarGradientEnd,
    required this.ripple,
  });

  /// Main sidebar / mobile top bar fill — [surfaceContainerHigh] + primary tint.
  final Color sidebarBackground;

  /// Hover state for nav rows.
  final Color sidebarHover;

  /// Selected row background — primaryContainer blended onto the rail.
  final Color sidebarActiveContainer;

  /// Darker “current route” pill — lerped toward [ColorScheme.onSurface] so the
  /// active item reads clearly against the rail in light and dark mode.
  final Color sidebarSelectedRow;

  /// Default label/icon on the sidebar.
  final Color sidebarOnBackground;

  /// Selected row label (high emphasis).
  final Color sidebarOnActive;

  /// Secondary labels (e.g. role subtitle).
  final Color sidebarMuted;

  final Color sidebarDivider;
  final Color sidebarAccent;

  /// Main content area behind nested routes.
  final Color contentBackground;

  final Color titleBarGradientStart;
  final Color titleBarGradientEnd;

  /// Ink splash / highlight for sidebar tiles.
  final Color ripple;

  static AppShellTheme fromColorScheme(ColorScheme cs) {
    final isLight = cs.brightness == Brightness.light;
    final primaryTint = isLight ? 0.10 : 0.22;
    final sidebarBg = Color.alphaBlend(
      cs.primary.withValues(alpha: primaryTint),
      cs.surfaceContainerHigh,
    );
    final hover = Color.alphaBlend(
      cs.primary.withValues(alpha: isLight ? 0.06 : 0.10),
      Color.alphaBlend(cs.onSurface.withValues(alpha: 0.05), sidebarBg),
    );
    final activeContainer = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: isLight ? 0.58 : 0.48),
      sidebarBg,
    );
    final selectedRow = Color.lerp(
      activeContainer,
      cs.onSurface,
      isLight ? 0.16 : 0.22,
    )!;
    final titleEnd = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: isLight ? 0.35 : 0.42),
      cs.surfaceContainerHigh,
    );
    return AppShellTheme(
      sidebarBackground: sidebarBg,
      sidebarHover: hover,
      sidebarActiveContainer: activeContainer,
      sidebarSelectedRow: selectedRow,
      sidebarOnBackground: cs.onSurface,
      sidebarOnActive: cs.primary,
      sidebarMuted: cs.onSurfaceVariant,
      sidebarDivider: cs.outlineVariant,
      sidebarAccent: cs.primary,
      contentBackground: cs.surface,
      titleBarGradientStart: sidebarBg,
      titleBarGradientEnd: titleEnd,
      ripple: cs.primary.withValues(alpha: isLight ? 0.14 : 0.18),
    );
  }

  static AppShellTheme of(BuildContext context) {
    final t = Theme.of(context).extension<AppShellTheme>();
    assert(t != null, 'AppShellTheme must be registered on ThemeData.extensions');
    return t!;
  }

  @override
  AppShellTheme copyWith({
    Color? sidebarBackground,
    Color? sidebarHover,
    Color? sidebarActiveContainer,
    Color? sidebarSelectedRow,
    Color? sidebarOnBackground,
    Color? sidebarOnActive,
    Color? sidebarMuted,
    Color? sidebarDivider,
    Color? sidebarAccent,
    Color? contentBackground,
    Color? titleBarGradientStart,
    Color? titleBarGradientEnd,
    Color? ripple,
  }) {
    return AppShellTheme(
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarActiveContainer: sidebarActiveContainer ?? this.sidebarActiveContainer,
      sidebarSelectedRow: sidebarSelectedRow ?? this.sidebarSelectedRow,
      sidebarOnBackground: sidebarOnBackground ?? this.sidebarOnBackground,
      sidebarOnActive: sidebarOnActive ?? this.sidebarOnActive,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarDivider: sidebarDivider ?? this.sidebarDivider,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      contentBackground: contentBackground ?? this.contentBackground,
      titleBarGradientStart: titleBarGradientStart ?? this.titleBarGradientStart,
      titleBarGradientEnd: titleBarGradientEnd ?? this.titleBarGradientEnd,
      ripple: ripple ?? this.ripple,
    );
  }

  @override
  ThemeExtension<AppShellTheme> lerp(
    ThemeExtension<AppShellTheme>? other,
    double t,
  ) {
    if (other is! AppShellTheme) return this;
    Color lc(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppShellTheme(
      sidebarBackground: lc(sidebarBackground, other.sidebarBackground),
      sidebarHover: lc(sidebarHover, other.sidebarHover),
      sidebarActiveContainer: lc(sidebarActiveContainer, other.sidebarActiveContainer),
      sidebarSelectedRow: lc(sidebarSelectedRow, other.sidebarSelectedRow),
      sidebarOnBackground: lc(sidebarOnBackground, other.sidebarOnBackground),
      sidebarOnActive: lc(sidebarOnActive, other.sidebarOnActive),
      sidebarMuted: lc(sidebarMuted, other.sidebarMuted),
      sidebarDivider: lc(sidebarDivider, other.sidebarDivider),
      sidebarAccent: lc(sidebarAccent, other.sidebarAccent),
      contentBackground: lc(contentBackground, other.contentBackground),
      titleBarGradientStart: lc(titleBarGradientStart, other.titleBarGradientStart),
      titleBarGradientEnd: lc(titleBarGradientEnd, other.titleBarGradientEnd),
      ripple: lc(ripple, other.ripple),
    );
  }
}

/// A class to encapsulate all application theme-related configurations.
///
/// This setup uses Material 3's `ColorScheme.fromSeed` to generate
/// complete, harmonious color palettes for both light and dark themes
/// from a single seed color, ensuring a modern and consistent UI.
class AppTheme {
  // Private constructor to prevent instantiation.
  AppTheme._();

  // Seed colors for generating the color schemes.
  // static const _lightSeedColor = Color.fromARGB(
  //   255,
  //   255,
  //   94,
  //   14,
  // );

  static const _lightSeedColor = Colors.deepPurple;

  // A vibrant, light lime green
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
    final shell = AppShellTheme.fromColorScheme(colorScheme);
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
      extensions: <ThemeExtension<dynamic>>[shell],

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
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
        headingTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),

        // 2. Row styling
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        horizontalMargin: 24,
        columnSpacing: 20,

        // 3. Border/Divider styling
        dividerThickness: 1,
        headingRowHeight: 56,

        // Checkbox styling (if used)
        checkboxHorizontalMargin: 12,
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
