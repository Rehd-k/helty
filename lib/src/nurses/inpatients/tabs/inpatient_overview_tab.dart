import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientOverviewScreen extends StatelessWidget {
  const InpatientOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SectionCard(
                      title: 'Latest Vitals',
                      subtitle: 'Most recent bedside observations',
                      child: _placeholderText(context),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Active Medications',
                      subtitle: 'Current medication orders for this admission',
                      child: _placeholderText(context),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'IV Running Status',
                      subtitle: 'Overview of active IV lines',
                      child: _placeholderText(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    SectionCard(
                      title: 'Today\'s Intake / Output',
                      subtitle: 'Fluid balance for the current day',
                      child: _placeholderText(context),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Care Plan Summary',
                      subtitle: 'Key problems, goals and progress',
                      child: _placeholderText(context),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Alerts',
                      subtitle: 'Overdue meds, abnormal vitals, allergy conflicts',
                      child: _placeholderText(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All sections on this tab are read-only. Use the other tabs to record new information.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderText(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Data for this section will appear here once connected to the inpatient services.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}

