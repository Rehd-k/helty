import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../models/archived_encounter_models.dart';
import '../../widgets/patient_consultation_credits_panel.dart';
import '../models/patient_chart_models.dart';
import '../permissions/patient_chart_permissions.dart';
import '../providers/patient_chart_providers.dart';
import 'package:helty/src/widgets/empty.widget.dart';
import 'widgets/archived_encounter_tile.dart';
import 'widgets/archived_encounter_upload_sheet.dart';
import 'widgets/chart_patient_header.dart';
import 'widgets/chart_section_list.dart';
import 'package:helty/src/core/responsive.dart';

@RoutePage()
class PatientChartScreen extends ConsumerStatefulWidget {
  const PatientChartScreen({super.key, required this.patientUuid});

  final String patientUuid;

  @override
  ConsumerState<PatientChartScreen> createState() => _PatientChartScreenState();
}

class _PatientChartScreenState extends ConsumerState<PatientChartScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<PatientChartTabDef> _tabs = [];
  final Map<String, List<Map<String, dynamic>>> _sectionData = {};
  final Map<String, int> _sectionSkip = {};
  final Map<String, bool> _sectionHasMore = {};
  final Map<String, bool> _sectionLoading = {};
  final Set<String> _loadedTabKeys = {};
  List<PatientArchivedEncounter> _archived = [];
  bool _archivedLoading = false;

  static const int _pageSize = 20;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabs(Staff? staff, List<String> available) {
    final allowed = allowedChartSectionsForStaff(staff).toSet();
    final visible = chartTabsForStaff(staff).where((tab) {
      return tab.includeKeys.any(
        (k) => allowed.contains(k) && available.contains(k),
      );
    }).toList();

    if (_tabs.length == visible.length) {
      var same = true;
      for (var i = 0; i < _tabs.length; i++) {
        if (_tabs[i].label != visible[i].label) {
          same = false;
          break;
        }
      }
      if (same) return;
    }

    _tabController?.dispose();
    _tabs = visible;
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController!.indexIsChanging) {
          _loadTabIfNeeded(_tabs[_tabController!.index]);
        }
      });
  }

  String _tabCacheKey(PatientChartTabDef tab) => tab.includeKeys.join(',');

  Future<void> _loadTabIfNeeded(PatientChartTabDef tab) async {
    final key = _tabCacheKey(tab);
    if (_loadedTabKeys.contains(key)) return;
    _loadedTabKeys.add(key);

    if (tab.includeKeys.length == 1 &&
        tab.includeKeys.first == PatientChartSectionKeys.archivedEncounters) {
      await _loadArchived();
      return;
    }

    await _loadSectionBundle(tab, reset: true);
  }

  Future<void> _loadSectionBundle(
    PatientChartTabDef tab, {
    required bool reset,
  }) async {
    final includeKey = tab.includeKeys.join(',');
    if (reset) {
      _sectionSkip[includeKey] = 0;
      _sectionData[includeKey] = [];
    }
    setState(() => _sectionLoading[includeKey] = true);
    try {
      final skip = _sectionSkip[includeKey] ?? 0;
      final response = await ref.read(patientChartServiceProvider).getChart(
            widget.patientUuid,
            include: tab.includeKeys,
            limit: _pageSize,
            skip: skip,
          );
      if (!mounted) return;
      final merged = <Map<String, dynamic>>[];
      if (!reset) {
        merged.addAll(_sectionData[includeKey] ?? []);
      }
      for (final sectionKey in tab.includeKeys) {
        for (final row in response.section(sectionKey)) {
          merged.add({...row, '_section': sectionKey});
        }
      }
      setState(() {
        _sectionData[includeKey] = merged;
        _sectionSkip[includeKey] = skip + _pageSize;
        final totalFetched = tab.includeKeys.fold<int>(
          0,
          (sum, k) => sum + response.section(k).length,
        );
        _sectionHasMore[includeKey] = totalFetched >= _pageSize;
        _sectionLoading[includeKey] = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _sectionLoading[includeKey] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load section: $e')),
        );
      }
    }
  }

  Future<void> _loadArchived() async {
    setState(() => _archivedLoading = true);
    try {
      final list = await ref
          .read(patientChartServiceProvider)
          .listArchivedEncounters(widget.patientUuid);
      if (mounted) {
        setState(() {
          _archived = list;
          _archivedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _archivedLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load archived: $e')),
        );
      }
    }
  }

  Future<void> _showUploadSheet() async {
    final service = ref.read(patientChartServiceProvider);
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ArchivedEncounterUploadSheet(
        patientUuid: widget.patientUuid,
        service: service,
        onUploaded: () {},
      ),
    );
    if (uploaded == true && mounted) {
      _loadedTabKeys.remove(PatientChartSectionKeys.archivedEncounters);
      ref.invalidate(patientChartHeaderProvider(widget.patientUuid));
      await _loadArchived();
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final headerAsync = ref.watch(patientChartHeaderProvider(widget.patientUuid));
    final canUpload = canUploadArchivedEncounters(staff);

    return headerAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Patient chart')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Patient chart')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (header) {
        _initTabs(staff, header.availableSections);
        if (_tabController == null || _tabs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(header.patient.displayName)),
            body: ResponsiveBody(
              builder: (context, bp) => Column(
                children: [
                ChartPatientHeader(
                  patient: header.patient,
                  summary: header.summary,
                ),
                const Expanded(
                  child: EmptyStateWidget(
                    icon: Icons.medical_information_outlined,
                    title: 'No chart sections available',
                    message:
                        'This account cannot view any sections for this patient.',
                  ),
                ),
              ],
              ),
            ),
          );
        }

        if (_tabController!.length != _tabs.length) {
          _initTabs(staff, header.availableSections);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _loadedTabKeys.isEmpty && _tabs.isNotEmpty) {
            _loadTabIfNeeded(_tabs[_tabController!.index]);
          }
        });

        final archivedTabIndex = _tabs.indexWhere(
          (t) => t.includeKeys.contains(PatientChartSectionKeys.archivedEncounters),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(header.patient.displayName),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _tabs
                  .map(
                    (t) => Tab(
                      text: t.label,
                      icon: t.icon != null ? Icon(t.icon, size: 20) : null,
                    ),
                  )
                  .toList(),
            ),
          ),
          floatingActionButton: canUpload &&
                  archivedTabIndex >= 0 &&
                  _tabController!.index == archivedTabIndex
              ? FloatingActionButton.extended(
                  onPressed: _showUploadSheet,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload scan'),
                )
              : null,
          body: ResponsiveBody(
            builder: (context, bp) => Column(
              children: [
              ChartPatientHeader(
                patient: header.patient,
                summary: header.summary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map(_buildTabBody).toList(),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBody(PatientChartTabDef tab) {
    final includeKey = _tabCacheKey(tab);
    final isBillingTab =
        tab.includeKeys.contains(PatientChartSectionKeys.invoices);

    if (tab.includeKeys.length == 1 &&
        tab.includeKeys.first == PatientChartSectionKeys.archivedEncounters) {
      if (_archivedLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return ArchivedEncountersList(
        groups: _archived,
        service: ref.read(patientChartServiceProvider),
        staff: ref.watch(authProvider).staff,
        onChanged: () {
          ref.invalidate(patientChartHeaderProvider(widget.patientUuid));
          _loadArchived();
        },
      );
    }

    final items = _sectionData[includeKey] ?? [];
    final loading = _sectionLoading[includeKey] == true && items.isEmpty;

    Widget sectionBody;
    if (loading) {
      sectionBody = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      sectionBody = ChartSectionList(
        sectionKey: tab.includeKeys.first,
        items: const [],
      );
    } else {
      sectionBody = ChartSectionList(
        sectionKey: tab.includeKeys.first,
        items: items,
        hasMore: _sectionHasMore[includeKey] ?? false,
        loadingMore: _sectionLoading[includeKey] == true,
        onLoadMore: () => _loadSectionBundle(tab, reset: false),
      );
    }

    if (!isBillingTab) return sectionBody;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PatientConsultationCreditsPanel(
          patientId: widget.patientUuid,
          includeExpired: true,
          showEmptyState: true,
        ),
        const SizedBox(height: 16),
        if (loading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          sectionBody,
      ],
    );
  }
}
