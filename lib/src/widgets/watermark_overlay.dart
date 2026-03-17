import 'package:flutter/material.dart';

/// Semi-transparent watermark overlay using [assetPath], shown across the app
/// via [MaterialApp.router]'s builder. Does not block pointer events.
class WatermarkOverlay extends StatelessWidget {
  const WatermarkOverlay({
    super.key,
    this.assetPath = 'assets/imsh.png',
    this.opacity = 0.12,
    this.size = 400,
  });

  final String assetPath;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
