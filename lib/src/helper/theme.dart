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

  /// Main sidebar / mobile top bar fill — navy rail in light mode; scheme-derived in dark.
  final Color sidebarBackground;

  /// Hover state for nav rows.
  final Color sidebarHover;

  /// Selected row background — primaryContainer blended onto the rail.
  final Color sidebarActiveContainer;

  /// Darker “current route” pill — bright primary on navy in light mode; scheme blend in dark.
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

  /// Mockup navy rail (light mode) — CityCare-style dark sidebar.
  static const Color _navyRail = Color(0xFF0F172A);
  static const Color _navyRailMid = Color(0xFF1E293B);
  static const Color _navyRailEnd = Color(0xFF1E3A5F);
  static const Color _contentTint = Color(0xFFF0F5FF);

  static AppShellTheme fromColorScheme(ColorScheme cs) {
    final isLight = cs.brightness == Brightness.light;

    // Light mode: dark navy rail + light labels (mockup). Dark mode: scheme-derived.
    if (isLight) {
      const sidebarBg = _navyRail;
      final hover = Color.alphaBlend(
        cs.primary.withValues(alpha: 0.18),
        _navyRailMid,
      );
      final activeContainer = Color.alphaBlend(
        cs.primary.withValues(alpha: 0.42),
        _navyRailMid,
      );
      final selectedRow = Color.alphaBlend(
        cs.primary.withValues(alpha: 0.92),
        sidebarBg,
      );
      return AppShellTheme(
        sidebarBackground: sidebarBg,
        sidebarHover: hover,
        sidebarActiveContainer: activeContainer,
        sidebarSelectedRow: selectedRow,
        sidebarOnBackground: const Color(0xFFF8FAFC),
        sidebarOnActive: Colors.white,
        sidebarMuted: const Color(0xFF94A3B8),
        sidebarDivider: const Color(0xFF334155),
        sidebarAccent: cs.primary,
        contentBackground: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.04),
          _contentTint,
        ),
        titleBarGradientStart: sidebarBg,
        titleBarGradientEnd: _navyRailEnd,
        ripple: cs.primary.withValues(alpha: 0.28),
      );
    }

    final sidebarBg = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.22),
      cs.surfaceContainerHigh,
    );
    final hover = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.10),
      Color.alphaBlend(cs.onSurface.withValues(alpha: 0.05), sidebarBg),
    );
    final activeContainer = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: 0.48),
      sidebarBg,
    );
    final selectedRow = Color.lerp(activeContainer, cs.onSurface, 0.22)!;
    final titleEnd = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: 0.42),
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
      ripple: cs.primary.withValues(alpha: 0.18),
    );
  }

  static AppShellTheme of(BuildContext context) {
    final t = Theme.of(context).extension<AppShellTheme>();
    assert(
      t != null,
      'AppShellTheme must be registered on ThemeData.extensions',
    );
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
      sidebarActiveContainer:
          sidebarActiveContainer ?? this.sidebarActiveContainer,
      sidebarSelectedRow: sidebarSelectedRow ?? this.sidebarSelectedRow,
      sidebarOnBackground: sidebarOnBackground ?? this.sidebarOnBackground,
      sidebarOnActive: sidebarOnActive ?? this.sidebarOnActive,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      sidebarDivider: sidebarDivider ?? this.sidebarDivider,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      contentBackground: contentBackground ?? this.contentBackground,
      titleBarGradientStart:
          titleBarGradientStart ?? this.titleBarGradientStart,
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
      sidebarActiveContainer: lc(
        sidebarActiveContainer,
        other.sidebarActiveContainer,
      ),
      sidebarSelectedRow: lc(sidebarSelectedRow, other.sidebarSelectedRow),
      sidebarOnBackground: lc(sidebarOnBackground, other.sidebarOnBackground),
      sidebarOnActive: lc(sidebarOnActive, other.sidebarOnActive),
      sidebarMuted: lc(sidebarMuted, other.sidebarMuted),
      sidebarDivider: lc(sidebarDivider, other.sidebarDivider),
      sidebarAccent: lc(sidebarAccent, other.sidebarAccent),
      contentBackground: lc(contentBackground, other.contentBackground),
      titleBarGradientStart: lc(
        titleBarGradientStart,
        other.titleBarGradientStart,
      ),
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

  // Mockup primary — vibrant outpatient / dashboard blue.
  static const _lightSeedColor = Color(0xFF2563EB);
  static const _darkSeedColor = Color(0xFF2563EB);

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

  /// Standard radii for premium hospital surfaces.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  /// Standard page / section padding.
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;

  /// A helper method to build the theme from a ColorScheme.
  /// This centralizes component theme definitions.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final shell = AppShellTheme.fromColorScheme(colorScheme);
    final fallbackTextTheme =
        ThemeData(brightness: colorScheme.brightness).textTheme;
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.interTextTheme(fallbackTextTheme);
    } catch (_) {
      // Font cache under AppData can be unreadable when another Windows user
      // (or an elevated run) created it. Fall back so the first frame still
      // rasterizes and the window can be shown.
      textTheme = fallbackTextTheme;
    }
    textTheme = textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final shapeMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    );
    final shapeLg = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLg),
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: shell.contentBackground,
      extensions: <ThemeExtension<dynamic>>[shell],

      // --- Component Themes (Material 3, flat surfaces) ---
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 2,
        highlightElevation: 4,
        shape: const CircleBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: shapeMd,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: shapeMd,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: shapeMd,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: shapeMd,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: shapeLg,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: shapeMd,
        elevation: 2,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: shapeMd,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest,
        ),
        headingTextStyle: textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        dataTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        horizontalMargin: 20,
        columnSpacing: 20,
        dividerThickness: 1,
        headingRowHeight: 52,
        checkboxHorizontalMargin: 12,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(radiusMd),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.titleSmall,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Keep for legacy BottomNavigationBar consumers until fully migrated.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
