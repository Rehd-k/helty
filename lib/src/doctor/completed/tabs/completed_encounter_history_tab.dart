import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';

@RoutePage()
class CompletedEncounterHistoryTab extends StatelessWidget {
  const CompletedEncounterHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }
    final e = scope.encounter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = <String, String?>{
      'Chief complaint': e.chiefComplaint,
      'History of present illness': e.hpi,
      'Past medical history': e.pmh,
      'Surgical history': e.surgicalHistory,
      'Drug history': e.drugHistory,
      'Allergy history': e.allergyHistory,
      'Family history': e.familyHistory,
      'Social history': e.socialHistory,
    };

    return ResponsiveBody(
      center: false,
      builder: (context, bp) => ListView(
        padding: EdgeInsets.zero,
      children: [
        for (final entry in items.entries)
          _Block(
            title: entry.key,
            content: entry.value?.isNotEmpty == true ? entry.value! : '—',
            theme: theme,
            colorScheme: colorScheme,
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
