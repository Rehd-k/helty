import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubImagingScreen extends ConsumerStatefulWidget {
  const HubImagingScreen({super.key});

  @override
  ConsumerState<HubImagingScreen> createState() => _HubImagingScreenState();
}

class _HubImagingScreenState extends ConsumerState<HubImagingScreen> {
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
            PatientChartSectionKeys.radiologyOrders,
            PatientChartSectionKeys.radiologyReports,
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
          PatientChartSectionKeys.radiologyReports,
          PatientChartSectionKeys.radiologyOrders,
        ]) {
          for (final row in response.section(key)) {
            items.add({...row, '_section': key});
          }
        }
        items = hubFilterByDateRange(items, range);
        items = hubSortRows(items, _sort);

        return HubSectionScaffold(
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
                  title: 'No imaging orders or reports',
                  icon: Icons.radar_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'imaging';
                    final cs = Theme.of(context).colorScheme;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.image_search_outlined),
                        title: Text(hubRowTitle(section, item)),
                        subtitle: Text(hubRowSubtitle(item) ?? ''),
                        trailing: _statusChip(context, item['status']?.toString()),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget? _statusChip(BuildContext context, String? status) {
    if (status == null || status.isEmpty) return null;
    return Chip(label: Text(status, style: const TextStyle(fontSize: 11)));
  }
}
