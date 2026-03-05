import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientCarePlanScreen extends StatelessWidget {
  const InpatientCarePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final problems = [
      'Risk of falls',
      'Acute pain',
      'Impaired mobility',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Care Plan',
        subtitle: 'Structured nursing problems, goals and interventions',
        child: Column(
          children: problems
              .map(
                (p) => _CarePlanProblemTile(problem: p),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _CarePlanProblemTile extends StatelessWidget {
  final String problem;

  const _CarePlanProblemTile({required this.problem});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          problem,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          'Goal: Maintain safety and functional status',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(context, 'Goal', scheme.primary),
                _chip(context, 'Interventions', scheme.secondary),
                _chip(context, 'Evaluation', scheme.tertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark achieved'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Update evaluation'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

