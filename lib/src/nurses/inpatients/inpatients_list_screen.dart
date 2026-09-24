import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/ward_census_header.dart';
import 'package:helty/src/nurses/inpatients/widgets/ward_census_sidebar.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/ward_service.dart';
import 'package:helty/src/widgets/helty_surface.dart';

@RoutePage()
class InpatientsListScreen extends ConsumerStatefulWidget {
  const InpatientsListScreen({super.key});

  @override
  ConsumerState<InpatientsListScreen> createState() =>
      _InpatientsListScreenState();
}

/// Outpatient department is not an inpatient ward; hide from this census UI.
bool _wardExcludedFromInpatientList(Ward w) {
  return w.name.trim().toUpperCase() == 'OPD';
}

bool _staffIsDoctor(Staff? staff) {
  final role = staff?.staffRole.toLowerCase() ?? '';
  final accountType = staff?.accountType?.name.toLowerCase() ?? '';
  return role == 'doctor' ||
      role == 'consultant' ||
      role == 'resident' ||
      role == 'intern' ||
      role == 'junior_resident' ||
      role == 'senior_resident' ||
      role == 'chief_resident' ||
      role == 'medical_student' ||
      accountType == 'physician' ||
      accountType == 'consultant' ||
      accountType == 'inpatient_doctor';
}

class _InpatientsListScreenState extends ConsumerState<InpatientsListScreen> {
  final _wardService = WardService();
  final _searchController = TextEditingController();
  final _listKey = GlobalKey();

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<InpatientCensus> _rows = const [];
  List<InpatientCensus> _filteredRows = const [];

  bool _isLoadingWards = false;
  bool _isLoadingWardDetails = false;

  @override
  void initState() {
    super.initState();
    _loadWards();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWards() async {
    setState(() {
      _isLoadingWards = true;
    });
    try {
      final fetched = await _wardService.fetchWards();
      final wards = fetched
          .where((w) => !_wardExcludedFromInpatientList(w))
          .toList(growable: false);
      setState(() {
        _wards = wards;
        final currentId = _selectedWard?.id;
        final stillValid =
            currentId != null && wards.any((w) => w.id == currentId);
        if (!stillValid) {
          _selectedWard = wards.isNotEmpty ? wards.first : null;
        }
      });
      if (_selectedWard != null) {
        await _loadWardDetails(_selectedWard!.id);
      } else if (mounted) {
        setState(() {
          _rows = const [];
          _filteredRows = const [];
        });
      }
    } catch (e) {
      _showError('Failed to load wards, $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWards = false;
        });
      }
    }
  }

  Future<void> _loadWardDetails(String wardId) async {
    setState(() {
      _isLoadingWardDetails = true;
    });
    try {
      final ward = await _wardService.getWardById(wardId);
      if (!mounted) return;
      setState(() {
        _selectedWard = ward;
        _rows = ward.inpatients;
      });
      _applySearch();
    } catch (e) {
      _showError('Failed to load ward details, $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWardDetails = false;
        });
      }
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredRows = _rows;
      });
      return;
    }

    setState(() {
      _filteredRows = _rows
          .where((row) {
            final name = row.name.toLowerCase();
            final bed = row.bedLabel.toLowerCase();
            final id = row.patientId.toLowerCase();
            return name.contains(query) ||
                bed.contains(query) ||
                id.contains(query);
          })
          .toList(growable: false);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openInpatientView(InpatientCensus row) {
    context.router.push(
      InpatientPatientViewRoute(
        admissionId: row.id,
        ward: row.wardName,
        bedNumber: row.bedLabel,
        diagnosis: row.diagnosis,
      ),
    );
  }

  void _openEncounter(InpatientCensus row) {
    final encounterId = row.encounterId;
    if (encounterId == null || encounterId.isEmpty) return;
    if (row.patientId.isEmpty) return;
    context.router.push(
      DoctorEncounterViewRoute(
        encounterId: encounterId,
        patientId: row.patientId,
      ),
    );
  }

  void _openClearance() {
    context.router.push(const AwaitingNursesClearanceRoute());
  }

  void _scrollToList() {
    final ctx = _listKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 220),
      alignment: 0.05,
    );
  }

  String get _occupancyValue {
    final cap = _selectedWard?.capacity ?? 0;
    if (cap <= 0) return '—';
    return '${((_rows.length / cap) * 100).round()}%';
  }

  String get _availableValue {
    final cap = _selectedWard?.capacity ?? 0;
    if (cap <= 0) return '—';
    return '${(cap - _rows.length).clamp(0, cap)}';
  }

  int get _longStayCount => _rows.where((r) => r.daysAdmitted >= 7).length;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDoctor = _staffIsDoctor(ref.watch(authProvider).staff);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < InpatientMetrics.cardBreakpoint;
          final showSideBySide = width >= InpatientMetrics.sidebarBreakpoint;
          final useCards = compact;

          final header = WardCensusHeader(compact: compact);
          final kpis = InpatientKpiRow(
            tiles: [
              InpatientKpiTile(
                icon: Icons.groups_outlined,
                color: InpatientMetrics.iconBlue,
                label: 'Inpatients',
                value: _isLoadingWardDetails && _rows.isEmpty
                    ? '—'
                    : '${_rows.length}',
                caption: _selectedWard?.name ?? 'Select a ward',
              ),
              InpatientKpiTile(
                icon: Icons.pie_chart_outline,
                color: InpatientMetrics.iconTeal,
                label: 'Occupancy',
                value: _occupancyValue,
                caption: (_selectedWard?.capacity ?? 0) > 0
                    ? '${_rows.length} of ${_selectedWard!.capacity} beds'
                    : 'Capacity not set',
              ),
              InpatientKpiTile(
                icon: Icons.bed_outlined,
                color: InpatientMetrics.iconPurple,
                label: 'Available',
                value: _availableValue,
                caption: 'Open beds',
              ),
              InpatientKpiTile(
                icon: Icons.schedule_outlined,
                color: InpatientMetrics.waitAmber,
                label: 'Long stay',
                value: _isLoadingWardDetails && _rows.isEmpty
                    ? '—'
                    : '$_longStayCount',
                caption: 'Admitted 7+ days',
              ),
            ],
          );
          final filters = _CensusFilterBar(
            searchController: _searchController,
            wards: _wards,
            selectedWardId: _selectedWard?.id,
            loadingWards: _isLoadingWards,
            compact: compact,
            onWardChanged: (id) {
              if (id == null) return;
              _loadWardDetails(id);
            },
            onRefresh: _loadWards,
            onAwaitingClearance: _openClearance,
          );

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              const SizedBox(height: 10),
              Expanded(
                child: KeyedSubtree(
                  key: _listKey,
                  child: useCards
                      ? _CensusCardList(
                          rows: _filteredRows,
                          loading: _isLoadingWardDetails,
                          emptyMessage: _emptyMessage,
                          isDoctor: isDoctor,
                          onOpenView: _openInpatientView,
                          onOpenEncounter: _openEncounter,
                        )
                      : _CensusTable(
                          rows: _filteredRows,
                          loading: _isLoadingWardDetails,
                          emptyMessage: _emptyMessage,
                          isDoctor: isDoctor,
                          onOpenView: _openInpatientView,
                          onOpenEncounter: _openEncounter,
                        ),
                ),
              ),
            ],
          );

          final sidebar = WardCensusSidebar(
            wards: _wards,
            selectedWardId: _selectedWard?.id,
            onSelectWard: (w) => _loadWardDetails(w.id),
            onRefresh: () {
              _loadWards();
              _scrollToList();
            },
            onAwaitingClearance: _openClearance,
            loadingWards: _isLoadingWards,
            fillHeight: showSideBySide,
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: sidebar),
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
                      height: 280,
                      child: SingleChildScrollView(child: sidebar),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 10),
                  kpis,
                  const SizedBox(height: 10),
                  filters,
                  const SizedBox(height: 10),
                  SizedBox(
                    height: compact ? 480 : 520,
                    child: useCards
                        ? _CensusCardList(
                            rows: _filteredRows,
                            loading: _isLoadingWardDetails,
                            emptyMessage: _emptyMessage,
                            isDoctor: isDoctor,
                            onOpenView: _openInpatientView,
                            onOpenEncounter: _openEncounter,
                          )
                        : _CensusTable(
                            rows: _filteredRows,
                            loading: _isLoadingWardDetails,
                            emptyMessage: _emptyMessage,
                            isDoctor: isDoctor,
                            onOpenView: _openInpatientView,
                            onOpenEncounter: _openEncounter,
                          ),
                  ),
                  const SizedBox(height: 10),
                  sidebar,
                ],
              );
            },
          );
        },
      ),
    );
  }

  String get _emptyMessage {
    if (_selectedWard == null) {
      return 'Select a ward to view current inpatients.';
    }
    if (_searchController.text.trim().isNotEmpty) {
      return 'No inpatients match this search.';
    }
    return 'No inpatients in this ward.';
  }
}

class _CensusFilterBar extends StatelessWidget {
  const _CensusFilterBar({
    required this.searchController,
    required this.wards,
    required this.selectedWardId,
    required this.loadingWards,
    required this.compact,
    required this.onWardChanged,
    required this.onRefresh,
    required this.onAwaitingClearance,
  });

  final TextEditingController searchController;
  final List<Ward> wards;
  final String? selectedWardId;
  final bool loadingWards;
  final bool compact;
  final ValueChanged<String?> onWardChanged;
  final VoidCallback onRefresh;
  final VoidCallback onAwaitingClearance;

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    IconData? icon,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(6),
              child: HeltySolidIcon(
                icon: icon,
                color: iconColor,
                size: 22,
                iconSize: 13,
                radius: 6,
              ),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  void _openExtras(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + size.height,
        origin.dx + size.width,
        origin.dy,
      ),
      items: [
        if (compact)
          for (final w in wards)
            PopupMenuItem(value: 'ward:${w.id}', child: Text(w.name)),
        const PopupMenuItem(value: 'refresh', child: Text('Refresh wards')),
        const PopupMenuItem(
          value: 'clearance',
          child: Text('Awaiting nurses clearance'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value.startsWith('ward:')) {
        onWardChanged(value.substring(5));
        return;
      }
      switch (value) {
        case 'refresh':
          onRefresh();
        case 'clearance':
          onAwaitingClearance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final search = TextField(
      controller: searchController,
      decoration: _decoration(
        context,
        label: 'Search',
        hint: 'Name, patient ID, or bed…',
        icon: Icons.search,
        iconColor: InpatientMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );

    final wardIds = wards.map((w) => w.id).toSet();
    final wardValue = selectedWardId != null && wardIds.contains(selectedWardId)
        ? selectedWardId
        : null;

    final ward = DropdownButtonFormField<String>(
      key: ValueKey('ward-${wardValue ?? 'none'}'),
      initialValue: wardValue,
      isExpanded: true,
      style: TextStyle(fontSize: 12, color: cs.onSurface),
      decoration: _decoration(
        context,
        label: 'Ward',
        icon: Icons.apartment_outlined,
        iconColor: InpatientMetrics.iconTeal,
      ),
      items: [
        for (final w in wards)
          DropdownMenuItem(value: w.id, child: Text(w.name)),
      ],
      onChanged: loadingWards ? null : onWardChanged,
    );

    final extras = Tooltip(
      message: 'More filters',
      child: InkWell(
        onTap: () => _openExtras(context),
        borderRadius: BorderRadius.circular(8),
        child: const HeltySolidIcon(
          icon: Icons.tune,
          color: InpatientMetrics.iconPurple,
          size: 34,
          iconSize: 16,
          radius: 8,
        ),
      ),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 8),
          extras,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: ward),
        const SizedBox(width: 8),
        extras,
      ],
    );
  }
}

class _CensusTable extends StatelessWidget {
  const _CensusTable({
    required this.rows,
    required this.loading,
    required this.emptyMessage,
    required this.isDoctor,
    required this.onOpenView,
    required this.onOpenEncounter,
  });

  final List<InpatientCensus> rows;
  final bool loading;
  final String emptyMessage;
  final bool isDoctor;
  final ValueChanged<InpatientCensus> onOpenView;
  final ValueChanged<InpatientCensus> onOpenEncounter;

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget headerRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            _head(context, 'PATIENT', flex: 5),
            const SizedBox(width: _colGap),
            _head(context, 'WARD', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'BED', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'REASON', flex: 4),
            const SizedBox(width: _colGap),
            _head(context, 'DAYS', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'ACTIONS', flex: 3, alignEnd: true),
          ],
        ),
      );
    }

    return HeltySurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 720
                    ? 720.0
                    : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        headerRow(),
                        Expanded(
                          child: loading
                              ? const Center(child: CircularProgressIndicator())
                              : rows.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      emptyMessage,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: rows.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: cs.outline.withValues(alpha: 0.08),
                                  ),
                                  itemBuilder: (context, i) {
                                    final row = rows[i];
                                    return ColoredBox(
                                      color: InpatientMetrics.zebraFill(cs, i),
                                      child: InkWell(
                                        onTap: () => onOpenView(row),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            8,
                                            16,
                                            8,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: _PatientCell(row: row),
                                              ),
                                              const SizedBox(width: _colGap),
                                              Expanded(
                                                flex: 2,
                                                child: HeltyEllipsisText(
                                                  text: row.wardName.isEmpty
                                                      ? '—'
                                                      : row.wardName,
                                                ),
                                              ),
                                              const SizedBox(width: _colGap),
                                              Expanded(
                                                flex: 2,
                                                child: HeltyEllipsisChip(
                                                  label: row.bedLabel.isEmpty
                                                      ? '—'
                                                      : row.bedLabel,
                                                  color: InpatientMetrics
                                                      .iconIndigo,
                                                ),
                                              ),
                                              const SizedBox(width: _colGap),
                                              Expanded(
                                                flex: 4,
                                                child: HeltyEllipsisText(
                                                  text:
                                                      row.diagnosis
                                                          .trim()
                                                          .isEmpty
                                                      ? '—'
                                                      : row.diagnosis,
                                                ),
                                              ),
                                              const SizedBox(width: _colGap),
                                              Expanded(
                                                flex: 2,
                                                child: HeltyEllipsisText(
                                                  text: '${row.daysAdmitted} d',
                                                  style: theme
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            InpatientMetrics.losColor(
                                                              row.daysAdmitted,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: _colGap),
                                              Expanded(
                                                flex: 3,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: FittedBox(
                                                    child: _CensusActions(
                                                      row: row,
                                                      isDoctor: isDoctor,
                                                      onOpenView: onOpenView,
                                                      onOpenEncounter:
                                                          onOpenEncounter,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                rows.length == 1 ? '1 inpatient' : '${rows.length} inpatients',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    return Expanded(
      flex: flex,
      child: alignEnd
          ? Align(alignment: Alignment.centerRight, child: text)
          : text,
    );
  }
}

class _CensusCardList extends StatelessWidget {
  const _CensusCardList({
    required this.rows,
    required this.loading,
    required this.emptyMessage,
    required this.isDoctor,
    required this.onOpenView,
    required this.onOpenEncounter,
  });

  final List<InpatientCensus> rows;
  final bool loading;
  final String emptyMessage;
  final bool isDoctor;
  final ValueChanged<InpatientCensus> onOpenView;
  final ValueChanged<InpatientCensus> onOpenEncounter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              return HeltySurfaceCard(
                margin: const EdgeInsets.only(bottom: 10),
                onTap: () => onOpenView(row),
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _PatientCell(row: row)),
                        HeltyEllipsisText(
                          text: '${row.daysAdmitted} d',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: InpatientMetrics.losColor(row.daysAdmitted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HeltyEllipsisText(
                      text: row.diagnosis.trim().isEmpty ? '—' : row.diagnosis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        HeltyStatusChip(
                          label: row.wardName.isEmpty ? '—' : row.wardName,
                          color: InpatientMetrics.iconTeal,
                        ),
                        HeltyStatusChip(
                          label: row.bedLabel.isEmpty
                              ? '—'
                              : 'Bed ${row.bedLabel}',
                          color: InpatientMetrics.iconIndigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CensusActions(
                        row: row,
                        isDoctor: isDoctor,
                        onOpenView: onOpenView,
                        onOpenEncounter: onOpenEncounter,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              rows.length == 1 ? '1 inpatient' : '${rows.length} inpatients',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientCell extends StatelessWidget {
  const _PatientCell({required this.row});

  final InpatientCensus row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nameParts = row.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    return Row(
      children: [
        PatientAvatar(
          avatarUrl: row.avatarUrl,
          firstName: nameParts.isNotEmpty ? nameParts.first : null,
          surname: nameParts.length > 1 ? nameParts.last : null,
          displayName: row.name,
          size: 36,
          backgroundColor: InpatientMetrics.iconPurple,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HeltyEllipsisText(
                text: row.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (row.ageGender.isNotEmpty)
                HeltyEllipsisText(
                  text: row.ageGender,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CensusActions extends StatelessWidget {
  const _CensusActions({
    required this.row,
    required this.isDoctor,
    required this.onOpenView,
    required this.onOpenEncounter,
  });

  final InpatientCensus row;
  final bool isDoctor;
  final ValueChanged<InpatientCensus> onOpenView;
  final ValueChanged<InpatientCensus> onOpenEncounter;

  bool get _canOpenEncounter =>
      isDoctor && row.encounterId != null && row.encounterId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => onOpenView(row),
          style: inpatientCompactOutline(),
          child: const Text('View'),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'view':
                onOpenView(row);
              case 'encounter':
                onOpenEncounter(row);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Open chart')),
            if (_canOpenEncounter)
              const PopupMenuItem(
                value: 'encounter',
                child: Text('Open encounter'),
              ),
          ],
        ),
      ],
    );
  }
}
