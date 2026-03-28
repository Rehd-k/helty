import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';

/// Cycles Light → Dark → System. Prefer [WindowButtons] theme menu for explicit choice.
class ThemeSwitchButton extends ConsumerWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return InkWell(
      onTap: () {
        final next = switch (mode) {
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.system,
          ThemeMode.system => ThemeMode.light,
        };
        ref.read(themeModeProvider.notifier).setThemeMode(next);
      },
      child: Tooltip(
        message: 'Cycle theme',
        child: Icon(
          switch (mode) {
            ThemeMode.light => Icons.wb_sunny_outlined,
            ThemeMode.dark => Icons.nightlight_round,
            ThemeMode.system => Icons.brightness_auto_outlined,
          },
          size: 10,
        ),
      ),
    );
  }
}
