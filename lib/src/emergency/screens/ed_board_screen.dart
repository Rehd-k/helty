import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/emergency/models/emergency_visit_model.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/emergency/utils/ed_role_helper.dart';
import 'package:helty/src/emergency/utils/ed_workflow_helper.dart';
import 'package:helty/src/emergency/widgets/ed_status_chip.dart';
import 'package:helty/src/emergency/widgets/esi_badge.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
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

  List<EmergencyVisitModel> _visits = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _service.listActiveVisits();
      if (!mounted) return;
      final sorted = List<EmergencyVisitModel>.from(result.visits)
        ..sort((a, b) {
          final esiA = a.esiLevel ?? 99;
          final esiB = b.esiLevel ?? 99;
          if (esiA != esiB) return esiA.compareTo(esiB);
          return b.computedWaitMinutes.compareTo(a.computedWaitMinutes);
        });
      setState(() {
        _visits = sorted;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accountType = ref.watch(authProvider).staff?.accountType;
    final canTriage = EdRoleHelper.canTriage(accountType);
    final canDoctor = EdRoleHelper.canOpenDoctorWorkspace(accountType);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveToolbar(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ED Board',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active emergency visits — tap refresh to update',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                ),
                if (EdRoleHelper.canRegister(accountType))
                  FilledButton.icon(
                    onPressed: () =>
                        context.router.push(const EdRegistrationRoute()),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                    label: const Text('Register patient'),
                  ),
              ],
            ),
            SizedBox(height: bp.isMobile ? 12 : 16),
            if (_loading && _visits.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _visits.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load ED board: $_error'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_visits.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        size: 48,
                        color: scheme.onSurface.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active ED visits',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ResponsiveDataTable(
                  child: Material(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                        columns: const [
                          DataColumn(label: Text('Patient')),
                          DataColumn(label: Text('ESI')),
                          DataColumn(label: Text('Chief complaint')),
                          DataColumn(label: Text('Arrival')),
                          DataColumn(label: Text('Wait')),
                          DataColumn(label: Text('Doctor')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _visits
                            .map(
                              (v) => _buildRow(
                                v,
                                canTriage: canTriage,
                                canDoctor: canDoctor,
                                accountType: accountType,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(
    EmergencyVisitModel visit, {
    required bool canTriage,
    required bool canDoctor,
    required AccountType? accountType,
  }) {
    final doctorLabel = visit.assignedDoctor?.displayName ??
        visit.encounter?.doctorLabel ??
        '—';
    final arrival = visit.arrivalAt != null
        ? DateFormatter.dateTime(visit.arrivalAt!)
        : '—';
    final wait = '${visit.computedWaitMinutes} min';
    final terminal = EdWorkflowHelper.isTerminal(visit.workflowStatus);
    final showTriage =
        canTriage && EdWorkflowHelper.canShowTriage(visit.workflowStatus);
    final showOpen =
        canDoctor && EdWorkflowHelper.canShowOpenDoctor(visit.workflowStatus);
    final showLwbs = !terminal &&
        EdWorkflowHelper.canMarkLwbs(visit.workflowStatus) &&
        (EdRoleHelper.isNurseOrFrontDesk(accountType) || canDoctor);
    final showDeceased = !terminal &&
        EdWorkflowHelper.canMarkDeceased(visit.workflowStatus) &&
        canDoctor;

    return DataRow(
      cells: [
        DataCell(Text(visit.patientName ?? visit.patientId)),
        DataCell(EsiBadge(esiLevel: visit.esiLevel, compact: true)),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              visit.chiefComplaint ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(arrival)),
        DataCell(Text(wait)),
        DataCell(Text(doctorLabel)),
        DataCell(EdStatusChip(status: visit.workflowStatus, compact: true)),
        DataCell(
          Wrap(
            spacing: 8,
            children: [
              if (showTriage)
                TextButton(
                  onPressed: () => _openTriage(visit),
                  child: const Text('Triage'),
                ),
              if (showOpen)
                TextButton(
                  onPressed: () => _openDoctorWorkspace(visit),
                  child: const Text('Open'),
                ),
              if (showLwbs)
                TextButton(
                  onPressed: () => _markLwbs(visit),
                  child: const Text('LWBS'),
                ),
              if (showDeceased)
                TextButton(
                  onPressed: () => _markDeceased(visit),
                  child: const Text('Deceased'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
