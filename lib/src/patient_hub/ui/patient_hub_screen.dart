import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';

import '../../helper/theme.dart';
import '../models/patient_hub_models.dart';
import '../patient_hub_metrics.dart';
import '../providers/patient_hub_providers.dart';
import '../widgets/hub_date_range_bar.dart';
import '../widgets/hub_page_header.dart';
import '../widgets/hub_patient_header.dart';
import '../widgets/hub_sidebar.dart';
import '../widgets/patient_hub_scope.dart';

@RoutePage()
class PatientHubScreen extends ConsumerStatefulWidget {
  const PatientHubScreen({super.key, required this.patientUuid});

  final String patientUuid;

  @override
  ConsumerState<PatientHubScreen> createState() => _PatientHubScreenState();
}

class _PatientHubScreenState extends ConsumerState<PatientHubScreen> {
  HubDatePreset _preset = HubDatePreset.all;

  Future<void> _pickCustomRange() async {
    final range = ref.read(patientHubDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: range.from != null && range.to != null
          ? DateTimeRange(start: range.from!, end: range.to!)
          : null,
    );
    if (picked == null || !mounted) return;
    setState(() => _preset = HubDatePreset.custom);
    ref.read(patientHubDateRangeProvider.notifier).state = PatientHubDateRange(
      from: picked.start,
      to: picked.end,
    );
    ref.invalidate(patientHubSectionProvider);
  }

  void _onPresetChanged(HubDatePreset preset) {
    setState(() => _preset = preset);
    ref.read(patientHubDateRangeProvider.notifier).state =
        dateRangeForPreset(preset);
    ref.invalidate(patientHubSectionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final headerAsync = ref.watch(patientHubHeaderProvider(widget.patientUuid));
    final profileAsync = ref.watch(patientHubProfileProvider(widget.patientUuid));
    final range = ref.watch(patientHubDateRangeProvider);
    final cs = Theme.of(context).colorScheme;

    return PatientHubScope(
      patientUuid: widget.patientUuid,
      child: headerAsync.when(
        loading: () => Scaffold(
          backgroundColor: cs.surface,
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: cs.surface,
          body: Center(child: Text('Error: $e')),
        ),
        data: (header) {
          return AutoTabsRouter(
            builder: (context, child) {
              final tabsRouter = AutoTabsRouter.of(context);
              final patient = profileAsync.asData?.value;

              return Scaffold(
                backgroundColor: cs.surface,
                body: ResponsiveBody(
                  center: false,
                  builder: (context, bp) {
                    final width = bp.maxWidth > 0
                        ? bp.maxWidth
                        : MediaQuery.sizeOf(context).width;
                    final compact = width < PatientHubMetrics.cardBreakpoint;
                    final showSideBySide =
                        width >= PatientHubMetrics.sidebarBreakpoint;

                    final pageHeader = HubPageHeader(
                      title: header.patient.displayName,
                      subtitle: [
                        if (header.patient.patientId != null)
                          'Hosp. ${header.patient.patientId}',
                        'Patient Hub',
                      ].join(' · '),
                      compact: compact,
                      trailing: IconButton(
                        tooltip: 'Back to search',
                        onPressed: () => context.router.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const HubSolidIcon(
                          icon: Icons.search,
                          color: PatientHubMetrics.iconIndigo,
                          size: 32,
                          iconSize: 16,
                          radius: 8,
                        ),
                      ),
                    );

                    final identity = HubPatientHeader(
                      patient: header.patient,
                      fullProfile: patient,
                    );

                    final filters = HubDateRangeBar(
                      range: range,
                      preset: _preset,
                      onPresetChanged: _onPresetChanged,
                      onCustomRange: _pickCustomRange,
                    );

                    final tabs = _buildTabsStrip(context, tabsRouter);

                    final mainColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pageHeader,
                        const SizedBox(height: 10),
                        identity,
                        const SizedBox(height: 10),
                        filters,
                        const SizedBox(height: 10),
                        tabs,
                        const SizedBox(height: 10),
                        Expanded(child: child),
                      ],
                    );

                    Widget sidebar({required bool fillHeight}) {
                      return HubSidebar(
                        patient: header.patient,
                        summary: header.summary,
                        fullProfile: patient,
                        onSearch: () => context.router.pop(),
                        onSelectTab: (i) => tabsRouter.setActiveIndex(i),
                        fillHeight: fillHeight,
                      );
                    }

                    if (showSideBySide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 9, child: mainColumn),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: sidebar(fillHeight: true),
                          ),
                        ],
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bounded = constraints.maxHeight.isFinite;
                        if (bounded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: mainColumn),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 220,
                                child: SingleChildScrollView(
                                  child: sidebar(fillHeight: false),
                                ),
                              ),
                            ],
                          );
                        }
                        return mainColumn;
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabsStrip(BuildContext context, TabsRouter tabsRouter) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = tabsRouter.pageCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
              child: _HubTabChip(
                selected: tabsRouter.activeIndex == i,
                label: _labelForTab(tabsRouter, i),
                color: PatientHubMetrics.accentForTab(
                  _routeNameForTab(tabsRouter, i),
                ),
                onTap: () => tabsRouter.setActiveIndex(i),
                textStyle: theme.textTheme.labelMedium,
                scheme: cs,
              ),
            ),
        ],
      ),
    );
  }

  String _routeNameForTab(TabsRouter tabsRouter, int index) {
    if (index < 0 || index >= tabsRouter.stack.length) return '';
    return tabsRouter.stack[index].routeData.name;
  }

  String _labelForTab(TabsRouter tabsRouter, int index) {
    return PatientHubMetrics.tabDefForRouteName(
      _routeNameForTab(tabsRouter, index),
    ).label;
  }
}

class _HubTabChip extends StatelessWidget {
  const _HubTabChip({
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
    required this.textStyle,
    required this.scheme,
  });

  final bool selected;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.45)
                  : scheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: textStyle?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? color : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
