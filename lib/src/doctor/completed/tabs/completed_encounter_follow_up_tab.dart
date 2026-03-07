import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';

@RoutePage()
class CompletedEncounterFollowUpTab extends StatelessWidget {
  const CompletedEncounterFollowUpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasFollowUp = (e.followUpDate != null && e.followUpDate!.isNotEmpty) ||
        (e.followUpInstructions != null && e.followUpInstructions!.isNotEmpty) ||
        (e.referral != null && e.referral!.isNotEmpty);

    if (!hasFollowUp) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No follow-up or referral recorded for this encounter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (e.followUpDate != null && e.followUpDate!.isNotEmpty)
            _Block(
              title: 'Follow-up date',
              content: e.followUpDate!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          if (e.followUpInstructions != null && e.followUpInstructions!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Block(
              title: 'Follow-up instructions',
              content: e.followUpInstructions!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
          if (e.referral != null && e.referral!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Block(
              title: 'Referral',
              content: e.referral!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.content,
    required this.theme,
    required this.colorScheme,
  });

  final String title;
  final String content;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
