import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode_provider.dart';

class WindowButtons extends ConsumerWidget {
  const WindowButtons({super.key});

  static IconData _themeMenuIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dividerColor = Theme.of(context).dividerColor;
    final currentMode = ref.watch(themeModeProvider);

    final buttonColors = WindowButtonColors(
      iconNormal: dividerColor,
      mouseOver: const Color(0xFFF6A00C),
      mouseDown: const Color(0xFF805306),
      iconMouseOver: const Color(0xFF805306),
      iconMouseDown: const Color(0xFFFFD500),
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: dividerColor,
      iconMouseOver: Colors.white,
    );

    return Row(
      children: [
        PopupMenuButton<ThemeMode>(
          tooltip: 'Theme',
          padding: EdgeInsets.zero,
          icon: Icon(
            _themeMenuIcon(currentMode),
            color: dividerColor,
            size: 16,
          ),
          onSelected: (mode) {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.light,
              child: _ThemeMenuRow(
                icon: Icons.light_mode_outlined,
                label: 'Light',
                selected: currentMode == ThemeMode.light,
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: _ThemeMenuRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark',
                selected: currentMode == ThemeMode.dark,
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: _ThemeMenuRow(
                icon: Icons.brightness_auto_outlined,
                label: 'System',
                selected: currentMode == ThemeMode.system,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {},
          child: Tooltip(
            message: 'Help Center',
            child: Icon(
              Icons.help_outline_outlined,
              color: dividerColor,
              size: 16,
            ),
          ),
        ),
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class _ThemeMenuRow extends StatelessWidget {
  const _ThemeMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        if (selected) Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}
