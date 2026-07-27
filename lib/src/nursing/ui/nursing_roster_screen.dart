import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/nursing_permissions.dart';
import '../../helper/date.formatter.dart';
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
class NursingRosterScreen extends ConsumerStatefulWidget {
  const NursingRosterScreen({super.key});

  @override
  ConsumerState<NursingRosterScreen> createState() =>
      _NursingRosterScreenState();
}

class _NursingRosterScreenState extends ConsumerState<NursingRosterScreen> {
  final _staffService = StaffService();

  DateTime _shiftDate = DateTime.now();
  String? _shiftType;
  String? _nursingUnit;
  bool _loading = true;
  String? _error;
  List<NursingRosterEntry> _entries = [];
  NursingRosterSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAndLoad());
  }

  void _initAndLoad() {
    final staff = ref.read(authProvider).staff;
    final bootstrap = ref.read(nursingBootstrapDataProvider);
    if (!canManageShiftRoster(staff, bootstrap)) {
      setState(() {
        _loading = false;
        _error = 'You do not have permission to manage shift rosters.';
      });
      return;
    }
    if (!isMatron(staff) && bootstrap?.nursingUnit != null) {
      _nursingUnit = bootstrap!.nursingUnit;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(nursingApiServiceProvider);
      final results = await Future.wait([
        service.listRosters(
          nursingUnit: _nursingUnit,
          shiftDate: _shiftDate,
          shiftType: _shiftType,
        ),
        service.getRosterSummary(
          nursingUnit: _nursingUnit,
          shiftDate: _shiftDate,
          shiftType: _shiftType,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<NursingRosterEntry>;
        _summary = results[1] as NursingRosterSummary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _shiftDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _shiftDate = picked);
      _load();
    }
  }

  Future<void> _showEntryDialog({NursingRosterEntry? existing}) async {
    final staff = ref.read(authProvider).staff;
    final matron = isMatron(staff);

    var nurseId = existing?.nurseId ?? '';
    var nursingUnit = existing?.nursingUnit ?? _nursingUnit ?? 'OPD';
    var shiftType = existing?.shiftType ?? 'MORNING';
    var notes = existing?.notes ?? '';
    var wardId = existing?.wardId;
    List<Staff> nurseOptions = [];
    List<Ward> allWards = [];

    try {
      final allStaff = await _staffService.fetchStaff(limit: 200);
      final byId = <String, Staff>{};
      for (final s in allStaff.where(isNursingStaff)) {
        byId[s.id] = s;
      }
      if (existing != null &&
          existing.nurseId.isNotEmpty &&
          !byId.containsKey(existing.nurseId)) {
        final name = existing.nurseName ?? existing.nurseId;
        final parts = name.trim().split(RegExp(r'\s+'));
        byId[existing.nurseId] = Staff(
          id: existing.nurseId,
          staffId: existing.nurseId,
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          staffRole: 'INPATIENT_NURSE',
        );
      }
      nurseOptions = byId.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      allWards = await ref.read(wardServiceProvider).fetchWards();
    } catch (_) {}

    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add roster entry' : 'Edit roster',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue:
                            nurseId.isNotEmpty &&
                                nurseOptions.any((s) => s.id == nurseId)
                            ? nurseId
                            : null,
                        decoration: const InputDecoration(labelText: 'Nurse'),
                        items: nurseOptions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => nurseId = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      if (matron)
                        DropdownButtonFormField<String>(
                          initialValue: nursingUnit,
                          decoration: const InputDecoration(
                            labelText: 'Nursing unit',
                          ),
                          items: NursingUnit.values
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u.apiValue,
                                  child: Text(u.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(
                            () => nursingUnit = v ?? nursingUnit,
                          ),
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
                            setDialogState(() => shiftType = v ?? shiftType),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final wardOptions = wardsForNursingUnit(
                            nursingUnit,
                            allWards,
                          );
                          final wardIds = wardOptions.map((w) => w.id).toSet();
                          final selectedWardId =
                              wardId != null && wardIds.contains(wardId)
                              ? wardId
                              : null;
                          return DropdownButtonFormField<String?>(
                            key: ValueKey(
                              'roster-ward-$selectedWardId-$nursingUnit',
                            ),
                            initialValue: selectedWardId,
                            decoration: const InputDecoration(
                              labelText: 'Ward (optional)',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No ward'),
                              ),
                              ...wardOptions.map(
                                (w) => DropdownMenuItem<String?>(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              ),
                            ],
                            onChanged: (v) => setDialogState(() => wardId = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: notes,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        onChanged: (v) => notes = v,
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
                  onPressed: nurseId.isEmpty
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;

    final service = ref.read(nursingApiServiceProvider);
    final entry = NursingRosterEntry(
      id: existing?.id ?? '',
      nurseId: nurseId,
      nursingUnit: nursingUnit,
      shiftDate: _shiftDate,
      shiftType: shiftType,
      wardId: wardId,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      if (existing == null) {
        await service.createRoster(entry);
      } else {
        await service.updateRoster(existing.id, entry);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Roster saved')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteEntry(NursingRosterEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete roster entry?'),
        content: Text(
          'Remove ${entry.nurseName ?? entry.nurseId} from roster?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(nursingApiServiceProvider).deleteRoster(entry.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _formatRole(String? role) {
    if (role == null || role.trim().isEmpty) return '';
    return role
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatWardType(String? type) {
    if (type == null || type.trim().isEmpty) return '';
    return _formatRole(type);
  }

  Widget _rosterEntryTile(NursingRosterEntry e, bool canManage) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final unitLabel =
        NursingUnit.fromString(e.nursingUnit)?.label ?? e.nursingUnit;
    final shiftLabel =
        ShiftType.fromString(e.shiftType)?.label ?? e.shiftType;
    final shiftDate = DateFormatter.medicalDate(e.shiftDate);
    final nurseTitle = e.nurseName ?? e.nurseId;
    final nurseRole = _formatRole(e.nurseRole);
    final initials = nurseTitle.trim().isNotEmpty
        ? nurseTitle
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .map((p) => p[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    final wardParts = <String>[
      if (e.wardName?.isNotEmpty == true) e.wardName!,
      if (e.wardType?.isNotEmpty == true) _formatWardType(e.wardType),
      if (e.departmentName?.isNotEmpty == true) e.departmentName!,
    ];

    final shiftParts = <String>[
      if (shiftLabel.isNotEmpty) '$shiftLabel shift',
      shiftDate,
      if (unitLabel.isNotEmpty) unitLabel,
    ];

    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Text(initials),
      ),
      title: Text(
        nurseTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nurseRole.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(nurseRole, style: muted),
            ),
          if (wardParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(wardParts.join(' · '), style: muted),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(shiftParts.join(' · '), style: muted),
          ),
          if (e.assignedByName?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  'Scheduled by ${e.assignedByName}',
                  if (e.createdAt != null)
                    DateFormatter.dateTime(e.createdAt!),
                ].join(' · '),
                style: muted,
              ),
            ),
          if (e.notes?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Notes: ${e.notes}', style: muted),
            ),
        ],
      ),
      trailing: canManage
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEntryDialog(existing: e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteEntry(e),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final bootstrap = ref.watch(nursingBootstrapDataProvider);
    final canManage = canManageShiftRoster(staff, bootstrap);
    final matron = isMatron(staff);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift roster'),
        actions: [
          if (canManage)
            IconButton(
              onPressed: () => _showEntryDialog(),
              icon: const Icon(Icons.add),
              tooltip: 'Add entry',
            ),
        ],
      ),
      body: !canManage
          ? Center(child: Text(_error ?? 'Access denied'))
          : ResponsiveBody(
              center: false,
              builder: (context, bp) => Column(
                children: [
                  Padding(
                    padding: EdgeInsets.zero,
                    child: ResponsiveToolbar(
                      actions: [
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_shiftDate.year}-${_shiftDate.month.toString().padLeft(2, '0')}-${_shiftDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      DropdownButton<String?>(
                        value: _shiftType,
                        hint: const Text('All shifts'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All shifts'),
                          ),
                          ...ShiftType.values.map(
                            (s) => DropdownMenuItem(
                              value: s.apiValue,
                              child: Text(s.label),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _shiftType = v);
                          _load();
                        },
                      ),
                      if (matron)
                        DropdownButton<String?>(
                          value: _nursingUnit,
                          hint: const Text('All units'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All units'),
                            ),
                            ...NursingUnit.values.map(
                              (u) => DropdownMenuItem(
                                value: u.apiValue,
                                child: Text(u.label),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _nursingUnit = v);
                            _load();
                          },
                        ),
                      if (_summary != null)
                        Chip(
                          label: Text(
                            'Scheduled ${_summary!.scheduled} · '
                            'On duty ${_summary!.onDuty} · '
                            'Gap ${_summary!.coverageGap}',
                          ),
                        ),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _entries.isEmpty && !_loading
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No roster entries')),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return _rosterEntryTile(_entries[index], canManage);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
