import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/emergency/ed_board_metrics.dart';
import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/emergency/models/emergency_visit_model.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/emergency/utils/ed_role_helper.dart';
import 'package:helty/src/emergency/widgets/ed_board_filter_bar.dart';
import 'package:helty/src/emergency/widgets/ed_board_header.dart';
import 'package:helty/src/emergency/widgets/ed_board_kpi_strip.dart';
import 'package:helty/src/emergency/widgets/ed_board_sidebar.dart';
import 'package:helty/src/emergency/widgets/ed_board_table.dart';
import 'package:helty/src/emergency/widgets/ed_board_visit_card.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class EdBoardScreen extends ConsumerStatefulWidget {
  const EdBoardScreen({super.key});

  @override
  ConsumerState<EdBoardScreen> createState() => _EdBoardScreenState();
}

class _EdBoardScreenState extends ConsumerState<EdBoardScreen> {
  final _service = EmergencyService();
  final _searchCtrl = TextEditingController();

  List<EmergencyVisitModel> _visits = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _statusValue = 'all';
  String _esiValue = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _skip = 0;
  int _total = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<EmergencyVisitModel> get _displayedVisits {
    return EdBoardMetrics.applyClientSearch(
      visits: _visits,
      query: _searchQuery,
    );
  }

  String get _emptyMessage {
    if (_searchQuery.isNotEmpty) {
      return 'No visits match the current search.';
    }
    if (_statusValue != 'all' || _esiValue != 'all') {
      return 'No visits match the current filters.';
    }
    return 'No active ED visits.';
  }

  String get _avgWaitLabel {
    final avg = EdBoardMetrics.averageWaitLabel(_displayedVisits);
    return avg ?? '—';
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _skip = 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.listActiveVisits(
        status: _statusValue == 'all' ? null : _statusValue,
        esiLevel: _esiValue == 'all' ? null : int.tryParse(_esiValue),
        fromDate: _fromDate,
        toDate: _toDate,
        skip: _skip,
        take: EdBoardMetrics.rowsPerPage,
      );
      if (!mounted) return;
      final sorted = EdBoardMetrics.sortVisits(result.visits);
      final total = result.total > 0 ? result.total : sorted.length;
      setState(() {
        _visits = sorted;
        _total = total;
        _hasMore = _skip + sorted.length < total;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _goPrev() {
    if (_skip <= 0) return;
    final next = _skip - EdBoardMetrics.rowsPerPage;
    _skip = next < 0 ? 0 : next;
    _load();
  }

  void _goNext() {
    if (!_hasMore) return;
    _skip += EdBoardMetrics.rowsPerPage;
    _load();
  }

  void _openTriage(EmergencyVisitModel visit) {
    context.router.push(
      EdTriageRoute(
        encounterId: visit.encounterId,
        patientId: visit.patientId,
        emergencyVisitId: visit.id != visit.encounterId ? visit.id : null,
      ),
    );
  }

  void _openDoctorWorkspace(EmergencyVisitModel visit) {
    context.router.push(
      DoctorEncounterViewRoute(
        encounterId: visit.encounterId,
        patientId: visit.patientId,
        emergencyVisitId: visit.id != visit.encounterId ? visit.id : null,
      ),
    );
  }

  Future<void> _markDeceased(EmergencyVisitModel visit) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record death in ED?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Record ${visit.patientName ?? 'this patient'} as deceased. '
              'This cannot be undone.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Documentation *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (notesCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Documentation is required.')),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      notesCtrl.dispose();
      return;
    }
    final notes = notesCtrl.text.trim();
    notesCtrl.dispose();

    try {
      await _service.submitDisposition(
        visitId: visit.id,
        encounterId: visit.encounterId,
        payload: EdDispositionPayload(
          disposition: EdDisposition.deceased,
          dispositionNotes: notes,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Death recorded.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _markLwbs(EmergencyVisitModel visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark LWBS?'),
        content: Text(
          'Mark ${visit.patientName ?? 'this patient'} as left without being seen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm LWBS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _service.submitDisposition(
        visitId: visit.id,
        encounterId: visit.encounterId,
        payload: const EdDispositionPayload(
          disposition: EdDisposition.lwbs,
          dispositionNotes: 'Left without being seen',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient marked LWBS.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Widget _queuePanel({
    required bool useCards,
    required AccountType? accountType,
    required bool canTriage,
    required bool canDoctor,
  }) {
    final displayed = _displayedVisits;
    final empty = _error != null && displayed.isEmpty
        ? 'Failed to load ED board: $_error'
        : _emptyMessage;

    if (useCards) {
      return EdBoardVisitCardList(
        visits: displayed,
        skip: _skip,
        loading: _loading && _visits.isEmpty,
        emptyMessage: empty,
        total: _total,
        hasMore: _hasMore,
        pageSize: EdBoardMetrics.rowsPerPage,
        onPrev: _goPrev,
        onNext: _goNext,
        accountType: accountType,
        canTriage: canTriage,
        canDoctor: canDoctor,
        onTriage: _openTriage,
        onOpen: _openDoctorWorkspace,
        onLwbs: _markLwbs,
        onDeceased: _markDeceased,
      );
    }
    return EdBoardTable(
      visits: displayed,
      skip: _skip,
      loading: _loading && _visits.isEmpty,
      emptyMessage: empty,
      total: _total,
      hasMore: _hasMore,
      pageSize: EdBoardMetrics.rowsPerPage,
      onPrev: _goPrev,
      onNext: _goNext,
      accountType: accountType,
      canTriage: canTriage,
      canDoctor: canDoctor,
      onTriage: _openTriage,
      onOpen: _openDoctorWorkspace,
      onLwbs: _markLwbs,
      onDeceased: _markDeceased,
    );
  }

  Widget _sidebar({
    required bool fillHeight,
    required bool canRegister,
  }) {
    return EdBoardSidebar(
      esiCounts: edBoardEsiCounts(_displayedVisits),
      statusCounts: edBoardStatusCounts(_displayedVisits),
      onRegister: () => context.router.push(const EdRegistrationRoute()),
      onRefresh: () => _load(reset: true),
      canRegister: canRegister,
      fillHeight: fillHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountType = ref.watch(authProvider).staff?.accountType;
    final canTriage = EdRoleHelper.canTriage(accountType);
    final canDoctor = EdRoleHelper.canOpenDoctorWorkspace(accountType);
    final canRegister = EdRoleHelper.canRegister(accountType);
    final displayed = _displayedVisits;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < EdBoardMetrics.cardBreakpoint;
          final showSideBySide = width >= EdBoardMetrics.sidebarBreakpoint;
          final useCards = compact;
          final useSnapKpis = width < 520;

          final header = EdBoardHeader(compact: compact);
          final kpis = EdBoardKpiStrip(
            inEd: _loading && _visits.isEmpty ? null : _total,
            criticalEsi: _loading && _visits.isEmpty
                ? null
                : EdBoardMetrics.criticalEsiCount(displayed),
            waitingDoctor: _loading && _visits.isEmpty
                ? null
                : EdBoardMetrics.waitingDoctorCount(displayed),
            avgWaitLabel: _loading && _visits.isEmpty ? '—' : _avgWaitLabel,
            useSnapStrip: useSnapKpis,
          );
          final filters = EdBoardFilterBar(
            searchController: _searchCtrl,
            statusValue: _statusValue,
            onStatusChanged: (value) {
              setState(() => _statusValue = value);
              _load(reset: true);
            },
            esiValue: _esiValue,
            onEsiChanged: (value) {
              setState(() => _esiValue = value);
              _load(reset: true);
            },
            onDateFilterChanged: (query, category, from, to) {
              setState(() {
                _fromDate = from;
                _toDate = to;
              });
              _load(reset: true);
            },
            onDateRefresh: () => _load(reset: true),
            compact: compact,
            fromDate: _fromDate,
            toDate: _toDate,
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
                child: _queuePanel(
                  useCards: useCards,
                  accountType: accountType,
                  canTriage: canTriage,
                  canDoctor: canDoctor,
                ),
              ),
            ],
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _sidebar(
                    fillHeight: true,
                    canRegister: canRegister,
                  ),
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
                      height: 280,
                      child: SingleChildScrollView(
                        child: _sidebar(
                          fillHeight: false,
                          canRegister: canRegister,
                        ),
                      ),
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
                    child: _queuePanel(
                      useCards: useCards,
                      accountType: accountType,
                      canTriage: canTriage,
                      canDoctor: canDoctor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _sidebar(fillHeight: false, canRegister: canRegister),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
