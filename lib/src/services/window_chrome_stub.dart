import 'package:flutter/material.dart';

/// Desktop window chrome is not available in the browser.
void revealHeltyDesktopWindow() {}

class WindowTitleBarBox extends StatelessWidget {
  const WindowTitleBarBox({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class MoveWindow extends StatelessWidget {
  const MoveWindow({super.key, this.child, this.onDoubleTap});

  final Widget? child;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class WindowButtonColors {
  WindowButtonColors({
    Color? normal,
    Color? mouseOver,
    Color? mouseDown,
    Color? iconNormal,
    Color? iconMouseOver,
    Color? iconMouseDown,
  });
}

class MinimizeWindowButton extends StatelessWidget {
  const MinimizeWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    bool? animate,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class MaximizeWindowButton extends StatelessWidget {
  const MaximizeWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    bool? animate,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CloseWindowButton extends StatelessWidget {
  const CloseWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    bool? animate,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
