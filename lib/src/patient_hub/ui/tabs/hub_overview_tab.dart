import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_stat_card.dart';
import '../../widgets/hub_timeline.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubOverviewScreen extends ConsumerWidget {
  const HubOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final headerAsync = ref.watch(patientHubHeaderProvider(patientUuid));
    final range = ref.watch(patientHubDateRangeProvider);

    final prefetch = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [
            PatientChartSectionKeys.encounters,
            PatientChartSectionKeys.vitals,
            PatientChartSectionKeys.labReports,
          ],
          limit: 10,
          fromDate: range.from,
          toDate: range.to,
        ),
      ),
    );

    return headerAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (header) {
        return prefetch.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sections) {
            final encounters = sections.section(PatientChartSectionKeys.encounters);
            final vitals = sections.section(PatientChartSectionKeys.vitals);
            final labs = sections.section(PatientChartSectionKeys.labReports);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth > 900
                          ? 4
                          : c.maxWidth > 560
                              ? 2
                              : 1;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          HubStatCard(
                            label: 'Encounters',
                            value: '${header.summary.encounterCount}',
                            icon: Icons.event_note_outlined,
                          ),
                          HubStatCard(
                            label: 'Admissions',
                            value: '${header.summary.admissionCount}',
                            icon: Icons.bed_outlined,
                          ),
                          HubStatCard(
                            label: 'Recent vitals',
                            value: '${vitals.length}',
                            icon: Icons.monitor_heart_outlined,
                          ),
                          HubStatCard(
                            label: 'Lab reports',
                            value: '${labs.length}',
                            icon: Icons.biotech_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (encounters.isEmpty && vitals.isEmpty && labs.isEmpty)
                    const HubEmptyState(
                      title: 'No recent clinical activity',
                      subtitle: 'Adjust the date range or explore other tabs.',
                    )
                  else
                    HubTimeline(
                      entries: [
                        ...encounters.take(5).map(
                              (e) => HubTimelineEntry(
                                title: hubRowTitle('encounters', e),
                                subtitle: hubRowSubtitle(e) ?? '',
                                date: hubParseDate(
                                  e['createdAt'] ?? e['encounterDate'],
                                ),
                                icon: Icons.event_note_outlined,
                              ),
                            ),
                        ...vitals.take(3).map(
                              (v) => HubTimelineEntry(
                                title: 'Vitals recorded',
                                subtitle: hubRowSubtitle(v) ?? '',
                                date: hubParseDate(
                                  v['recordedAt'] ?? v['createdAt'],
                                ),
                                icon: Icons.monitor_heart_outlined,
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
