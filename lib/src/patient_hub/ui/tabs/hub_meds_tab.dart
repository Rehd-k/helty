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
class HubMedsScreen extends ConsumerStatefulWidget {
  const HubMedsScreen({super.key});

  @override
  ConsumerState<HubMedsScreen> createState() => _HubMedsScreenState();
}

class _HubMedsScreenState extends ConsumerState<HubMedsScreen> {
  HubSortOrder _sort = HubSortOrder.newestFirst;
  HubMedsFilter _filter = HubMedsFilter.all;

  @override
  Widget build(BuildContext context) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final sectionAsync = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [
            PatientChartSectionKeys.medicationOrders,
            PatientChartSectionKeys.prescriptions,
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
          PatientChartSectionKeys.medicationOrders,
          PatientChartSectionKeys.prescriptions,
        ]) {
          for (final row in response.section(key)) {
            items.add({...row, '_section': key});
          }
        }
        items = hubFilterByDateRange(items, range);
        items = _applyMedsFilter(items);
        items = hubSortRows(items, _sort);

        return ResponsiveBody(
          builder: (context, bp) => HubSectionScaffold(
          filterRow: Row(
            children: HubMedsFilter.values
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(f == HubMedsFilter.all ? 'All' : 'Active'),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                )
                .toList(),
          ),
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
                  title: 'No medications or prescriptions',
                  icon: Icons.medication_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'meds';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication_liquid_outlined),
                        title: Text(hubRowTitle(section, item)),
                        subtitle: Text(hubRowSubtitle(item) ?? ''),
                      ),
                    );
                  },
                ),
        ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyMedsFilter(
    List<Map<String, dynamic>> items,
  ) {
    if (_filter == HubMedsFilter.all) return items;
    return items.where((item) {
      final status = (item['status'] ?? '').toString().toUpperCase();
      return !status.contains('COMPLETE') &&
          !status.contains('CANCEL') &&
          !status.contains('DISCONTINUED');
    }).toList();
  }
}
