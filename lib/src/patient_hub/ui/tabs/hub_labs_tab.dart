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
class HubLabsScreen extends ConsumerStatefulWidget {
  const HubLabsScreen({super.key});

  @override
  ConsumerState<HubLabsScreen> createState() => _HubLabsScreenState();
}

class _HubLabsScreenState extends ConsumerState<HubLabsScreen> {
  HubSortOrder _sort = HubSortOrder.newestFirst;
  HubLabStatusFilter _status = HubLabStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final sectionAsync = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [
            PatientChartSectionKeys.labOrders,
            PatientChartSectionKeys.labRequests,
            PatientChartSectionKeys.labReports,
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
          PatientChartSectionKeys.labReports,
          PatientChartSectionKeys.labOrders,
          PatientChartSectionKeys.labRequests,
        ]) {
          for (final row in response.section(key)) {
            items.add({...row, '_section': key});
          }
        }
        items = hubFilterByDateRange(items, range);
        items = _applyStatusFilter(items);
        items = hubSortRows(items, _sort);

        return HubSectionScaffold(
          filterRow: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HubLabStatusFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_statusLabel(f)),
                        selected: _status == f,
                        onSelected: (_) => setState(() => _status = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
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
                  title: 'No lab orders or results',
                  icon: Icons.biotech_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'labs';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(hubRowTitle(section, item)),
                        subtitle: Text(hubRowSubtitle(item) ?? ''),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              item['result']?.toString() ??
                                  item['findings']?.toString() ??
                                  item['notes']?.toString() ??
                                  'No detailed result text.',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyStatusFilter(
    List<Map<String, dynamic>> items,
  ) {
    if (_status == HubLabStatusFilter.all) return items;
    return items.where((item) {
      final status = (item['status'] ?? '').toString().toUpperCase();
      return switch (_status) {
        HubLabStatusFilter.pending =>
          status.contains('PENDING') ||
              status.contains('ORDERED') ||
              status.contains('IN_PROGRESS'),
        HubLabStatusFilter.completed =>
          status.contains('COMPLETE') ||
              status.contains('DONE') ||
              status.contains('REPORTED'),
        HubLabStatusFilter.all => true,
      };
    }).toList();
  }

  String _statusLabel(HubLabStatusFilter f) => switch (f) {
        HubLabStatusFilter.all => 'All',
        HubLabStatusFilter.pending => 'Pending',
        HubLabStatusFilter.completed => 'Completed',
      };
}
