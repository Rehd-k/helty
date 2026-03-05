import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class DoctorPendingImagingScreen extends StatelessWidget {
  const DoctorPendingImagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.radar_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Pending Imaging Reports',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Imaging reports awaiting review will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
