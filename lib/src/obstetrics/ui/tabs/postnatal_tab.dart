import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';

@RoutePage()
class ObstetricsPostnatalTab extends StatelessWidget {
  final String? pregnancyId;

  const ObstetricsPostnatalTab({super.key, this.pregnancyId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final _ =
        pregnancyId ??
        PregnancyViewScope.of(context)?.pregnancyId; // ensure we have scope

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Postnatal visits', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Postnatal visits are linked to a labour delivery. Record a delivery first from the Labour & delivery tab, then open that delivery to add mother or baby postnatal visits.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
