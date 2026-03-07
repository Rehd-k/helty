import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';

@RoutePage()
class ObstetricsLabourDeliveryTab extends StatelessWidget {
  final String? pregnancyId;

  const ObstetricsLabourDeliveryTab({
    super.key,
    this.pregnancyId,
  });

  @override
  Widget build(BuildContext context) {
    final pregnancyId = this.pregnancyId ?? PregnancyViewScope.of(context)?.pregnancyId;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (pregnancyId == null || pregnancyId.isEmpty) {
      return const Center(child: Text('Missing pregnancy context'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Record labour & delivery',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add delivery details, partogram entries, and babies.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.router.push(
                ObstetricsAddLabourDeliveryRoute(pregnancyId: pregnancyId),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Record delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
