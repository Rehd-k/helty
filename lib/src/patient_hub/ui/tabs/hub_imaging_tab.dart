import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_order_results_dialog.dart';
import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_list_row.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../patient_hub_metrics.dart';
import '../../../widgets/helty_surface.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubImagingScreen extends ConsumerStatefulWidget {
  const HubImagingScreen({super.key});

  @override
  ConsumerState<HubImagingScreen> createState() => _HubImagingScreenState();
}

class _HubImagingScreenState extends ConsumerState<HubImagingScreen> {
  HubSortOrder _sort = HubSortOrder.newestFirst;
  final _radiologyService = RadiologyService();

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
                  title: 'No imaging orders or reports',
                  icon: Icons.radar_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section = item['_section']?.toString() ?? 'imaging';
                    final status = item['status']?.toString();
                    return HubListRow(
                      title: hubRowTitle(section, item),
                      subtitle: hubRowSubtitle(item),
                      icon: Icons.image_search_outlined,
                      iconColor: PatientHubMetrics.iconPink,
                      trailing: status == null || status.isEmpty
                          ? null
                          : SizedBox(
                              width: 110,
                              child: HeltyEllipsisChip(
                                label: status,
                                color: PatientHubMetrics.iconTeal,
                              ),
                            ),
                      onTap: () {
                        final orderId = item['id']?.toString() ??
                            item['orderId']?.toString();
                        if (orderId == null || orderId.isEmpty) return;
                        showRadiologyOrderResultsDialog(
                          context,
                          service: _radiologyService,
                          orderId: orderId,
                        );
                      },
                    );
                  },
                ),
        ),
        );
      },
    );
  }
}
