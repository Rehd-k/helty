import 'package:flutter/material.dart';

import 'package:helty/src/app/org_config.dart';

/// Semi-transparent watermark overlay using [assetPath], shown across the app
/// via [MaterialApp.router]'s builder. Does not block pointer events.
class WatermarkOverlay extends StatelessWidget {
  const WatermarkOverlay({
    super.key,
    this.assetPath,
    this.opacity = 0.12,
    this.size = 400,
  });

  /// Defaults to [OrgConfig.logoAsset] when null.
  final String? assetPath;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = assetPath ?? OrgConfig.instance.logoAsset;
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            path,
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
