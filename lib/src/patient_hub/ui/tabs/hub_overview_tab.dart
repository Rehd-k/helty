import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../patient_hub_metrics.dart';
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

            return ResponsiveBody(
              expand: false,
              builder: (context, bp) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResponsiveWrapGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 4,
                    children: [
                          HubStatCard(
                            label: 'Encounters',
                            value: '${header.summary.encounterCount}',
                            caption: 'Lifetime visits',
                            icon: Icons.event_note_outlined,
                            color: PatientHubMetrics.iconBlue,
                          ),
                          HubStatCard(
                            label: 'Admissions',
                            value: '${header.summary.admissionCount}',
                            caption: 'Inpatient stays',
                            icon: Icons.bed_outlined,
                            color: PatientHubMetrics.iconTeal,
                          ),
                          HubStatCard(
                            label: 'Recent vitals',
                            value: '${vitals.length}',
                            caption: 'In selected range',
                            icon: Icons.monitor_heart_outlined,
                            color: PatientHubMetrics.waitRed,
                          ),
                          HubStatCard(
                            label: 'Lab reports',
                            value: '${labs.length}',
                            caption: 'In selected range',
                            icon: Icons.biotech_outlined,
                            color: PatientHubMetrics.iconIndigo,
                          ),
                        ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
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
                                iconColor: PatientHubMetrics.iconBlue,
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
                                iconColor: PatientHubMetrics.waitRed,
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }
}
