import 'package:flutter/material.dart';

class CmacVibrantBackdrop extends StatelessWidget {
  const CmacVibrantBackdrop({
    super.key,
    required this.child,
    required this.colors,
  });

  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final c1 = colors.isNotEmpty ? colors.first : cs.primary;
    final c2 = colors.length > 1 ? colors[1] : cs.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(cs.surface, c1, dark ? 0.14 : 0.12)!,
            Color.lerp(cs.surface, c2, dark ? 0.10 : 0.08)!,
            cs.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _Blob(color: c1.withValues(alpha: dark ? 0.18 : 0.22)),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _Blob(color: c2.withValues(alpha: dark ? 0.12 : 0.16)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
