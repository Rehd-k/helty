import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../nurses/inpatients/widgets/inpatient_layout_constants.dart';
import '../models/patient_hub_models.dart';
import '../providers/patient_hub_providers.dart';
import '../widgets/hub_date_range_bar.dart';
import '../widgets/hub_patient_header.dart';
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

  static const _tabLabels = [
    'Overview',
    'Profile',
    'Encounters',
    'Vitals',
    'Labs',
    'Imaging',
    'Meds',
    'Dialysis',
    'Theatre',
    'Documents',
    'Notes',
  ];

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

    return PatientHubScope(
      patientUuid: widget.patientUuid,
      child: headerAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Patient Hub')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Patient Hub')),
          body: Center(child: Text('Error: $e')),
        ),
        data: (header) {
          return AutoTabsRouter(
            routes: [
              HubOverviewRoute(),
              HubProfileRoute(),
              HubEncountersRoute(),
              HubVitalsRoute(),
              HubLabsRoute(),
              HubImagingRoute(),
              HubMedsRoute(),
              HubDialysisRoute(),
              HubTheatreRoute(),
              HubDocumentsRoute(),
              HubNotesRoute(),
            ],
            builder: (context, child) {
              final tabsRouter = AutoTabsRouter.of(context);
              final patient = profileAsync.asData?.value;

              return Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                appBar: AppBar(
                  title: Text(header.patient.displayName),
                  actions: [
                    IconButton(
                      tooltip: 'Back to search',
                      icon: const Icon(Icons.search),
                      onPressed: () => context.router.pop(),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kInpatientContentMaxWidth,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact =
                              constraints.maxWidth < kInpatientCompactBreakpoint;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HubPatientHeader(
                                patient: header.patient,
                                summary: header.summary,
                                fullProfile: patient,
                              ),
                              HubDateRangeBar(
                                range: range,
                                preset: _preset,
                                onPresetChanged: _onPresetChanged,
                                onCustomRange: _pickCustomRange,
                              ),
                              _buildTabsStrip(
                                context,
                                tabsRouter,
                                compact: compact,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: child,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabsStrip(
    BuildContext context,
    TabsRouter tabsRouter, {
    required bool compact,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            final selected = tabsRouter.activeIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text(_tabLabels[index]),
                selected: selected,
                onSelected: (_) => tabsRouter.setActiveIndex(index),
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
