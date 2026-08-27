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
        // Prefer structured labOrders first so real tests/results surface.
        var items = <Map<String, dynamic>>[];
        for (final key in [
          PatientChartSectionKeys.labOrders,
          PatientChartSectionKeys.labReports,
          PatientChartSectionKeys.labRequests,
        ]) {
          for (final row in response.section(key)) {
            items.add({...row, '_section': key});
          }
        }
        items = hubFilterByDateRange(items, range);
        items = _applyStatusFilter(items);
        items = hubSortRows(items, _sort);

        return ResponsiveBody(
          builder: (context, bp) => HubSectionScaffold(
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
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(hubRowTitle(section, item)),
                          subtitle: Text(hubRowSubtitle(item) ?? ''),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _HubLabOrderBody(
                                section: section,
                                item: item,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
              status.contains('IN_PROGRESS') ||
              status.contains('SAMPLE') ||
              status.contains('PROCESSING'),
        HubLabStatusFilter.completed =>
          status.contains('COMPLETE') ||
              status.contains('DONE') ||
              status.contains('REPORTED') ||
              status.contains('VERIFIED'),
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

class _HubLabOrderBody extends StatelessWidget {
  const _HubLabOrderBody({required this.section, required this.item});

  final String section;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (section == PatientChartSectionKeys.labOrders) {
      final rawItems = item['items'];
      if (rawItems is List && rawItems.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rawItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _HubLabOrderItemBlock(
                item: Map<String, dynamic>.from(rawItems[i] as Map),
              ),
            ],
          ],
        );
      }
      return Text(
        'No tests on this order.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final legacy = item['result']?.toString() ??
        item['results']?.toString() ??
        item['findings']?.toString() ??
        item['notes']?.toString();
    if (legacy != null && legacy.trim().isNotEmpty) {
      return SelectableText(legacy, style: theme.textTheme.bodyMedium);
    }
    return Text(
      'No detailed result text.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _HubLabOrderItemBlock extends StatelessWidget {
  const _HubLabOrderItemBlock({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final testName = hubLabOrderItemTestName(item) ?? 'Lab test';
    final status = item['status']?.toString();
    final results = item['results'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  testName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status != null && status.isNotEmpty)
                Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (results is! List || results.isEmpty)
            Text(
              'No results recorded yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            ...results.map((raw) {
              if (raw is! Map) return const SizedBox.shrink();
              final row = Map<String, dynamic>.from(raw);
              return _HubLabResultRow(result: row);
            }),
        ],
      ),
    );
  }
}

class _HubLabResultRow extends StatelessWidget {
  const _HubLabResultRow({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = result['field'];
    String label = 'Result';
    String? unit;
    String? refRange;
    if (field is Map) {
      label = field['label']?.toString() ?? label;
      unit = field['unit']?.toString();
      refRange = field['referenceRange']?.toString();
    }
    final value = result['value']?.toString() ?? '—';
    final flag = result['abnormalFlag']?.toString();
    final isCritical = result['isCritical'] == true;

    final valueParts = <String>[value];
    if (unit != null && unit.isNotEmpty) valueParts.add(unit);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: theme.textTheme.bodySmall),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  valueParts.join(' '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCritical
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
              ),
              if (flag != null && flag.isNotEmpty)
                Text(
                  flag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
          if (refRange != null && refRange.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Ref: $refRange',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
