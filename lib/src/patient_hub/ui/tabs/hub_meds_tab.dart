import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_list_row.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../patient_hub_metrics.dart';
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
          filterRow: DropdownButtonFormField<HubMedsFilter>(
            key: ValueKey('hub-meds-$_filter'),
            initialValue: _filter,
            isExpanded: true,
            decoration: hubFilterDecoration(
              context,
              label: 'Meds',
              iconColor: PatientHubMetrics.waitAmber,
              icon: Icons.medication_outlined,
            ),
            items: const [
              DropdownMenuItem(value: HubMedsFilter.all, child: Text('All')),
              DropdownMenuItem(
                value: HubMedsFilter.active,
                child: Text('Active'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _filter = v);
            },
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
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'meds';
                    return HubListRow(
                      title: hubRowTitle(section, item),
                      subtitle: hubRowSubtitle(item),
                      icon: Icons.medication_liquid_outlined,
                      iconColor: PatientHubMetrics.waitAmber,
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
