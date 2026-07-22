import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../core/widgets/patient_avatar.dart';
import '../../helper/date.formatter.dart';
import '../../auth/nursing_permissions.dart';
import '../../models/staff_model.dart';
import '../../models/ward_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_providers.dart';
import '../../services/staff_service.dart';
import 'package:helty/src/core/responsive.dart';
import '../models/nursing_models.dart';
import '../providers/nursing_providers.dart';
import '../ward_matching.dart';

@RoutePage()
class NursingAssignmentsScreen extends ConsumerStatefulWidget {
  const NursingAssignmentsScreen({super.key});

  @override
  ConsumerState<NursingAssignmentsScreen> createState() =>
      _NursingAssignmentsScreenState();
}

class _NursingAssignmentsScreenState
    extends ConsumerState<NursingAssignmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _staffService = StaffService();

  bool _loadingInpatient = true;
  bool _loadingOutpatient = true;
  String? _errorInpatient;
  String? _errorOutpatient;
  List<InpatientNurseAssignment> _inpatient = [];
  List<OutpatientNurseAssignment> _outpatient = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadInpatient(), _loadOutpatient()]);
  }

  Future<void> _loadInpatient() async {
    setState(() {
      _loadingInpatient = true;
      _errorInpatient = null;
    });
    try {
      final bootstrap = ref.read(nursingBootstrapDataProvider);
      final res = await ref
          .read(nursingApiServiceProvider)
          .listInpatientAssignments(nursingUnit: bootstrap?.nursingUnit);
      if (!mounted) return;
      setState(() {
        _inpatient = res.assignments;
        _loadingInpatient = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorInpatient = e.toString();
        _loadingInpatient = false;
      });
    }
  }

  Future<void> _loadOutpatient() async {
    setState(() {
      _loadingOutpatient = true;
      _errorOutpatient = null;
    });
    try {
      final bootstrap = ref.read(nursingBootstrapDataProvider);
      final res = await ref
          .read(nursingApiServiceProvider)
          .listOutpatientAssignments(nursingUnit: bootstrap?.nursingUnit);
      if (!mounted) return;
      setState(() {
        _outpatient = res.assignments;
        _loadingOutpatient = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorOutpatient = e.toString();
        _loadingOutpatient = false;
      });
    }
  }

  Future<void> _deleteInpatient(InpatientNurseAssignment a) async {
    final staff = ref.read(authProvider).staff;
    final bootstrap = ref.read(nursingBootstrapDataProvider);
    if (!canAssignInpatientPatients(staff, bootstrap)) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(nursingApiServiceProvider)
          .deleteInpatientAssignment(
            admissionId: a.admissionId,
            assignmentId: a.id,
          );
      _loadInpatient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteOutpatient(OutpatientNurseAssignment a) async {
    final staff = ref.read(authProvider).staff;
    final bootstrap = ref.read(nursingBootstrapDataProvider);
    if (!canAssignOutpatientPatients(staff, bootstrap)) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(nursingApiServiceProvider)
          .deleteOutpatientAssignment(a.id);
      _loadOutpatient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _createInpatientAssignment() async {
    final staff = ref.read(authProvider).staff;
    final bootstrap = ref.read(nursingBootstrapDataProvider);
    if (!canAssignInpatientPatients(staff, bootstrap)) return;

    var nurseId = staff?.id ?? '';
    var shiftType = 'MORNING';
    var wardId = '';
    var admissionId = '';
    List<Ward> wardOptions = [];
    List<InpatientCensus> patients = [];
    List<Staff> nurseOptions = [];
    var loadingPatients = false;

    try {
      final allWards = await ref.read(wardServiceProvider).fetchWards();
      if (isMatron(staff)) {
        wardOptions = wardsForNursingUnit(bootstrap?.nursingUnit, allWards);
      } else if (isChargeNurse(staff)) {
        wardOptions = selectableWardsForChargeNurseRole(
          staff!.staffRole,
          allWards,
        );
      } else {
        wardOptions = wardsForNursingUnit(bootstrap?.nursingUnit, allWards);
      }
      wardOptions =
          wardOptions
              .where((w) => w.name.trim().toUpperCase() != 'OPD')
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      if (wardOptions.isNotEmpty) {
        wardId = wardOptions.first.id;
        final ward = await ref.read(wardServiceProvider).getWardById(wardId);
        patients = ward.inpatients;
      }

      final allStaff = await _staffService.fetchStaff(limit: 200);
      final byId = <String, Staff>{};
      for (final s in allStaff.where(isNursingStaff)) {
        byId[s.id] = s;
      }
      nurseOptions = byId.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      if (nurseId.isNotEmpty && !byId.containsKey(nurseId)) {
        nurseId = nurseOptions.isNotEmpty ? nurseOptions.first.id : '';
      }
    } catch (_) {}

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          Future<void> onWardChanged(String? id) async {
            if (id == null || id.isEmpty) {
              setDialog(() {
                wardId = '';
                admissionId = '';
                patients = [];
              });
              return;
            }
            setDialog(() {
              wardId = id;
              admissionId = '';
              loadingPatients = true;
            });
            try {
              final ward = await ref.read(wardServiceProvider).getWardById(id);
              if (!ctx.mounted) return;
              setDialog(() {
                patients = ward.inpatients;
                loadingPatients = false;
              });
            } catch (_) {
              if (!ctx.mounted) return;
              setDialog(() {
                patients = [];
                loadingPatients = false;
              });
            }
          }

          final selectedWardId =
              wardId.isNotEmpty && wardOptions.any((w) => w.id == wardId)
              ? wardId
              : null;
          final selectedAdmissionId =
              admissionId.isNotEmpty && patients.any((p) => p.id == admissionId)
              ? admissionId
              : null;
          final selectedNurseId =
              nurseId.isNotEmpty && nurseOptions.any((s) => s.id == nurseId)
              ? nurseId
              : null;

          return AlertDialog(
            title: const Text('Assign inpatient nurse'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedWardId,
                      decoration: const InputDecoration(labelText: 'Ward'),
                      items: wardOptions
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name),
                            ),
                          )
                          .toList(),
                      onChanged: wardOptions.isEmpty ? null : onWardChanged,
                    ),
                    const SizedBox(height: 12),
                    if (loadingPatients)
                      const LinearProgressIndicator(minHeight: 2)
                    else
                      DropdownButtonFormField<String>(
                        key: ValueKey('admission-$wardId-${patients.length}'),
                        initialValue: selectedAdmissionId,
                        decoration: InputDecoration(
                          labelText: 'Admitted patient',
                          hintText: patients.isEmpty
                              ? 'No admitted patients in this ward'
                              : null,
                        ),
                        items: patients
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.bedLabel.isNotEmpty
                                      ? '${p.name} · Bed ${p.bedLabel}'
                                      : p.name,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: patients.isEmpty
                            ? null
                            : (v) => setDialog(
                                () => admissionId = v ?? admissionId,
                              ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedNurseId,
                      decoration: const InputDecoration(labelText: 'Nurse'),
                      items: nurseOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: nurseOptions.isEmpty
                          ? null
                          : (v) => setDialog(() => nurseId = v ?? nurseId),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: shiftType,
                      decoration: const InputDecoration(labelText: 'Shift'),
                      items: ShiftType.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.apiValue,
                              child: Text(s.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialog(() => shiftType = v ?? shiftType),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: admissionId.isEmpty || nurseId.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || admissionId.isEmpty) return;

    try {
      await ref
          .read(nursingApiServiceProvider)
          .createInpatientAssignment(
            admissionId: admissionId,
            nurseId: nurseId,
            shiftDate: DateTime.now(),
            shiftType: shiftType,
          );
      _loadInpatient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final bootstrap = ref.watch(nursingBootstrapDataProvider);
    final canInpatient = canAssignInpatientPatients(staff, bootstrap);
    final canOutpatient = canAssignOutpatientPatients(staff, bootstrap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient assignments'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Inpatient'),
            Tab(text: 'Outpatient'),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: _tabs.index == 0 && canInpatient
          ? FloatingActionButton(
              onPressed: _createInpatientAssignment,
              child: const Icon(Icons.add),
            )
          : null,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => TabBarView(
          controller: _tabs,
          children: [_inpatientTab(canInpatient), _outpatientTab(canOutpatient)],
        ),
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null || status.trim().isEmpty) return '';
    final lower = status.trim().toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _inpatientAssignmentTile(InpatientNurseAssignment a, bool canDelete) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final shiftLabel =
        ShiftType.fromString(a.shiftType)?.label ?? a.shiftType ?? '';
    final unitLabel =
        NursingUnit.fromString(a.nursingUnit)?.label ?? a.nursingUnit ?? '';
    final shiftDate = a.shiftDate != null
        ? DateFormatter.medicalDate(a.shiftDate!)
        : null;

    final locationParts = <String>[
      if (a.wardName?.isNotEmpty == true) a.wardName!,
      if (a.bedLabel?.isNotEmpty == true) 'Bed ${a.bedLabel}',
      if (a.admissionStatus?.isNotEmpty == true)
        _formatStatus(a.admissionStatus),
    ];

    final shiftParts = <String>[
      if (shiftLabel.isNotEmpty) '$shiftLabel shift',
      if (shiftDate != null) shiftDate,
      if (unitLabel.isNotEmpty) unitLabel,
    ];

    final patientTitle = a.patientName ?? a.admissionId;
    final nameParts = patientTitle
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    return ListTile(
      isThreeLine: true,
      leading: PatientAvatar(
        avatarUrl: a.avatarUrl,
        firstName: nameParts.isNotEmpty ? nameParts.first : null,
        surname: nameParts.length > 1 ? nameParts.last : null,
        displayName: patientTitle,
        size: 40,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      title: Text(
        patientTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (a.patientNumber?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Patient ID ${a.patientNumber}', style: muted),
            ),
          if (locationParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(locationParts.join(' · '), style: muted),
            ),
          if (shiftParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(shiftParts.join(' · '), style: muted),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Assigned nurse: ${a.nurseName ?? a.nurseId}',
              style: muted,
            ),
          ),
          if (a.assignedByName?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  'Assigned by ${a.assignedByName}',
                  if (a.assignedAt != null)
                    DateFormatter.dateTime(a.assignedAt!),
                ].join(' · '),
                style: muted,
              ),
            ),
        ],
      ),
      trailing: canDelete
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteInpatient(a),
            )
          : null,
      onTap: a.admissionId.isNotEmpty
          ? () => context.router.push(
              InpatientPatientViewRoute(admissionId: a.admissionId),
            )
          : null,
    );
  }

  Widget _inpatientTab(bool canDelete) {
    if (_loadingInpatient) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorInpatient != null) {
      return Center(child: Text(_errorInpatient!));
    }
    if (_inpatient.isEmpty) {
      return const Center(child: Text('No inpatient assignments'));
    }
    return RefreshIndicator(
      onRefresh: _loadInpatient,
      child: ListView.separated(
        itemCount: _inpatient.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _inpatientAssignmentTile(_inpatient[index], canDelete);
        },
      ),
    );
  }

  Widget _outpatientTab(bool canDelete) {
    if (_loadingOutpatient) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorOutpatient != null) {
      return Center(child: Text(_errorOutpatient!));
    }
    if (_outpatient.isEmpty) {
      return const Center(child: Text('No outpatient assignments'));
    }
    return RefreshIndicator(
      onRefresh: _loadOutpatient,
      child: ListView.separated(
        itemCount: _outpatient.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = _outpatient[index];
          return ListTile(
            title: Text(a.patientName ?? a.invoiceId),
            subtitle: Text(
              '${a.nursingUnit ?? ''} · ${a.nurseName ?? a.nurseId} · ${a.serviceName ?? ''}',
            ),
            trailing: canDelete
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteOutpatient(a),
                  )
                : null,
          );
        },
      ),
    );
  }
}
