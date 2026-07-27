import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubNotesScreen extends ConsumerStatefulWidget {
  const HubNotesScreen({super.key});

  @override
  ConsumerState<HubNotesScreen> createState() => _HubNotesScreenState();
}

class _HubNotesScreenState extends ConsumerState<HubNotesScreen> {
  HubSortOrder _sort = HubSortOrder.newestFirst;

  @override
  Widget build(BuildContext context) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final sectionAsync = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [
            PatientChartSectionKeys.medicalHistories,
            PatientChartSectionKeys.doctorReports,
          ],
          limit: 100,
          fromDate: range.from,
          toDate: range.to,
        ),
      ),
    );

    return sectionAsync.when(
      loading: () => const HubSectionScaffold(loading: true, child: SizedBox()),
      error: (e, _) => HubSectionScaffold(
        error: '$e',
        onRetry: () => ref.invalidate(patientHubSectionProvider),
        child: const SizedBox(),
      ),
      data: (response) {
        var items = <Map<String, dynamic>>[];
        for (final key in [
          PatientChartSectionKeys.doctorReports,
          PatientChartSectionKeys.medicalHistories,
        ]) {
          for (final row in response.section(key)) {
            items.add({...row, '_section': key});
          }
        }
        items = hubFilterByDateRange(items, range);
        items = hubSortRows(items, _sort);

        return ResponsiveBody(
          builder: (context, bp) => HubSectionScaffold(
          sortDropdown: DropdownButton<HubSortOrder>(
            value: _sort,
            items: const [
              DropdownMenuItem(
                value: HubSortOrder.newestFirst,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: HubSortOrder.oldestFirst,
                child: Text('Oldest'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _sort = v);
            },
          ),
          child: items.isEmpty
              ? const HubEmptyState(
                  title: 'No clinical notes or reports',
                  icon: Icons.description_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'notes';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(hubRowTitle(section, item)),
                        subtitle: Text(
                          item['content']?.toString() ??
                              item['report']?.toString() ??
                              hubRowSubtitle(item) ??
                              '',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
        ),
        );
      },
    );
  }
}
