import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubEncountersScreen extends ConsumerStatefulWidget {
  const HubEncountersScreen({super.key});

  @override
  ConsumerState<HubEncountersScreen> createState() =>
      _HubEncountersScreenState();
}

class _HubEncountersScreenState extends ConsumerState<HubEncountersScreen> {
  HubSortOrder _sort = HubSortOrder.newestFirst;
  HubEncounterFilter _filter = HubEncounterFilter.all;

  void _openItem(
    BuildContext context, {
    required String section,
    required Map<String, dynamic> item,
    required String patientUuid,
  }) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (section == PatientChartSectionKeys.encounters) {
      context.router.push(
        DoctorCompletedEncounterViewRoute(
          encounterId: id,
          patientId: patientUuid,
        ),
      );
      return;
    }

    if (section == PatientChartSectionKeys.admissions) {
      final ward = item['ward'];
      final wardName = ward is Map ? ward['name']?.toString() : null;
      context.router.push(
        InpatientPatientViewRoute(
          admissionId: id,
          ward: wardName,
          bedNumber: item['bedPreference']?.toString() ??
              item['bedNumber']?.toString(),
          diagnosis: item['primaryDiagnosis']?.toString() ??
              item['admissionReason']?.toString() ??
              item['reason']?.toString(),
          readOnly: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final sectionAsync = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [
            PatientChartSectionKeys.encounters,
            PatientChartSectionKeys.admissions,
          ],
          limit: patientHubMaxTake,
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
        for (final e in response.section(PatientChartSectionKeys.encounters)) {
          items.add({...e, '_section': PatientChartSectionKeys.encounters});
        }
        for (final a in response.section(PatientChartSectionKeys.admissions)) {
          items.add({...a, '_section': PatientChartSectionKeys.admissions});
        }
        items = hubFilterByDateRange(items, range);
        items = _applyEncounterFilter(items);
        items = hubSortRows(items, _sort);

        return ResponsiveBody(
          builder: (context, bp) => HubSectionScaffold(
          filterRow: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HubEncounterFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_filterLabel(f)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
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
                  title: 'No encounters or admissions',
                  icon: Icons.event_busy_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final section =
                        item['_section']?.toString() ?? 'encounters';
                    final id = item['id']?.toString();
                    return _EncounterTile(
                      sectionKey: section,
                      item: item,
                      onTap: id != null
                          ? () => _openItem(
                                context,
                                section: section,
                                item: item,
                                patientUuid: patientUuid,
                              )
                          : null,
                    );
                  },
                ),
        ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _applyEncounterFilter(
    List<Map<String, dynamic>> items,
  ) {
    if (_filter == HubEncounterFilter.all) return items;
    return items.where((item) {
      final type = (item['encounterType'] ?? item['type'] ?? '')
          .toString()
          .toUpperCase();
      final section = item['_section']?.toString();
      return switch (_filter) {
        HubEncounterFilter.inpatient =>
          section == PatientChartSectionKeys.admissions ||
              type.contains('INPATIENT') ||
              type.contains('ADMISSION'),
        HubEncounterFilter.emergency => type.contains('EMERGENCY'),
        HubEncounterFilter.outpatient =>
          type.contains('OUTPATIENT') || type.contains('OPD'),
        HubEncounterFilter.all => true,
      };
    }).toList();
  }

  String _filterLabel(HubEncounterFilter f) => switch (f) {
        HubEncounterFilter.all => 'All',
        HubEncounterFilter.outpatient => 'Outpatient',
        HubEncounterFilter.inpatient => 'Inpatient',
        HubEncounterFilter.emergency => 'Emergency',
      };
}

class _EncounterTile extends StatelessWidget {
  const _EncounterTile({
    required this.sectionKey,
    required this.item,
    this.onTap,
  });

  final String sectionKey;
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmission = sectionKey == PatientChartSectionKeys.admissions;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmission
              ? cs.tertiaryContainer
              : cs.primaryContainer,
          child: Icon(
            isAdmission ? Icons.bed_outlined : Icons.medical_information_outlined,
            color: isAdmission ? cs.onTertiaryContainer : cs.onPrimaryContainer,
          ),
        ),
        title: Text(hubRowTitle(sectionKey, item)),
        subtitle: Text(hubRowSubtitle(item) ?? ''),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
