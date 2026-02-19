import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';

/// A reusable IconButton to toggle between light and dark themes.
class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the theme state to update the icon.
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      // Choose icon based on the current theme.
      onTap: () {
        // Call the toggle function. 'read' is used here because we're
        // calling a function and don't need to rebuild this specific widget
        // when the state changes (the parent MaterialApp handles that).
        context.read<ThemeProvider>().toggleTheme();
      },
      // Choose icon based on the current theme.
      child: Tooltip(
        message: 'Toggle Theme',
        child: Icon(
          themeProvider.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_round,
          size: 10,
        ),
      ),
    );
  }
}
