import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/staff_service.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:intl/intl.dart';

@RoutePage()
class DoctorCompletedEncountersScreen extends ConsumerStatefulWidget {
  const DoctorCompletedEncountersScreen({super.key});

  @override
  ConsumerState<DoctorCompletedEncountersScreen> createState() =>
      _DoctorCompletedEncountersScreenState();
}

class _DoctorCompletedEncountersScreenState
    extends ConsumerState<DoctorCompletedEncountersScreen> {
  final _encounterService = EncounterService();
  final _patientService = PatientService();
  final _staffService = StaffService();

  List<EncounterModel> _encounters = [];
  final Map<String, Patient> _patientCache = {};
  final Map<String, String> _doctorNameCache = {};
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime? _filterDate;
  /// Must match [FromToDateFilter] defaults (start/end of calendar day).
  DateTime? _fromDate;
  DateTime? _toDate;

  /// Physicians only: `false` = all completed (no doctorId); `true` = filter by logged-in doctor.
  bool _physicianShowMineOnly = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
        _filterDisplayed();
      }
    });
    // Do not call [_loadEncounters] here: [FromToDateFilter] mounts on first
    // build and notifies via post-frame callback. Previously the loading gate
    // hid the filter until after the first fetch, so that notify fired twice
    // and reloaded the list (infinite “loading” / duplicate fetches).
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Same criteria as [HomeScreen] physician menu — toggles "mine only" on completed list.
  bool _isPhysicianStaff(Staff? staff) {
    if (staff == null) return false;
    final at = staff.accountType?.name.toLowerCase() ?? '';
    final r = staff.role.toLowerCase();
    return at == 'physician' ||
        at == 'consultant' ||
        at == 'inpatient_doctor' ||
        r == 'doctor' ||
        r == 'consultant' ||
        r == 'resident' ||
        r == 'intern' ||
        r == 'junior_resident' ||
        r == 'senior_resident' ||
        r == 'chief_resident' ||
        r == 'medical_student';
  }

  Future<void> _loadEncounters() async {
    final staff = ref.read(authProvider).staff;
    if (staff == null) {
      setState(() {
        _loading = false;
        _error = 'Not logged in.';
      });
      return;
    }

    final physician = _isPhysicianStaff(staff);
    final String? doctorIdFilter;
    if (physician && _physicianShowMineOnly) {
      final id = staff.id.trim();
      doctorIdFilter = id.isNotEmpty ? id : null;
    } else {
      doctorIdFilter = null;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _encounterService.fetchOutpatientEncounters(
        doctorId: doctorIdFilter,
        status: 'COMPLETED',
        take: 200,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (!mounted) return;
      list.sort(
        (a, b) =>
            (b.closedAt ?? b.startedAt).compareTo(a.closedAt ?? a.startedAt),
      );
      setState(() {
        _encounters = list;
        _loading = false;
      });
      _loadPatientsForEncounters(list);
      _loadDoctorsForEncounters(list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPatientsForEncounters(List<EncounterModel> list) async {
    final ids = <String>{};
    for (final e in list) {
      if (!_patientCache.containsKey(e.patientId)) {
        ids.add(e.patientId);
      }
    }
    if (ids.isEmpty) return;
    final updates = <String, Patient>{};
    for (final id in ids) {
      try {
        final p = await _patientService.getPatientById(id);
        updates[id] = p;
      } catch (_) {
        // skip failed patient load
      }
      if (!mounted) return;
    }
    if (updates.isNotEmpty && mounted) {
      setState(() => _patientCache.addAll(updates));
    }
  }

  Future<void> _loadDoctorsForEncounters(List<EncounterModel> list) async {
    final ids = <String>{};
    for (final e in list) {
      if (e.doctorDisplayName?.trim().isNotEmpty == true) continue;
      final id = e.doctorId.trim();
      if (id.isEmpty || _doctorNameCache.containsKey(id)) continue;
      ids.add(id);
    }
    if (ids.isEmpty) return;
    final updates = <String, String>{};
    for (final id in ids) {
      try {
        final staff = await _staffService.getStaffById(id);
        updates[id] = staff.fullName;
      } catch (_) {
        // skip failed staff load
      }
      if (!mounted) return;
    }
    if (updates.isNotEmpty && mounted) {
      setState(() => _doctorNameCache.addAll(updates));
    }
  }

  String _doctorLabel(EncounterModel encounter) {
    final nested = encounter.doctorDisplayName?.trim();
    if (nested != null && nested.isNotEmpty) return 'Dr $nested';
    final cached = _doctorNameCache[encounter.doctorId.trim()];
    if (cached != null && cached.isNotEmpty) return 'Dr $cached';
    final id = encounter.doctorId.trim();
    return id.isNotEmpty ? id : '—';
  }

  void _filterDisplayed() {
    setState(() {});
  }

  List<EncounterModel> get _filteredEncounters {
    var list = _encounters;
    if (_filterDate != null) {
      final d = _filterDate!;
      list = list.where((e) {
        final closed = e.closedAt ?? e.startedAt;
        return closed.year == d.year &&
            closed.month == d.month &&
            closed.day == d.day;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final patient = _patientCache[e.patientId];
        final name = patient != null
            ? '${patient.firstName} ${patient.surname}'.toLowerCase()
            : e.patientId.toLowerCase();
        final complaint = (e.chiefComplaint ?? '').toLowerCase();
        final doctor = _doctorLabel(e).toLowerCase();
        return name.contains(q) ||
            complaint.contains(q) ||
            doctor.contains(q) ||
            e.patientId.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  void _openEncounter(EncounterModel encounter) {
    context.router.push(
      DoctorCompletedEncounterViewRoute(
        encounterId: encounter.id,
        patientId: encounter.patientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final staff = ref.watch(authProvider.select((s) => s.staff));
    final showPhysicianScopeToggle = _isPhysicianStaff(staff);

    final filtered = _filteredEncounters;

    Widget listSliver() {
      if (_loading && _encounters.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Loading completed encounters…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (_error != null && _encounters.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadEncounters,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (filtered.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  _encounters.isEmpty
                      ? 'No completed encounters yet.'
                      : 'No matches for search or date filter.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = filtered[index];
              final patient = _patientCache[e.patientId];
              final name = patient != null
                  ? '${patient.title} ${patient.firstName} ${patient.surname}'
                  : 'Patient ${e.patientId}';
              final closed = e.closedAt ?? e.startedAt;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    name.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        e.chiefComplaint?.isNotEmpty == true
                            ? e.chiefComplaint!
                            : 'No chief complaint recorded',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _doctorLabel(e),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.yMMMd().format(closed)} • ${e.primaryIcdDescription ?? e.status}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.editMeta?.hasEdits == true)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: const Text('Edited'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  onTap: () => _openEncounter(e),
                ),
              );
            },
            childCount: filtered.length,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEncounters,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completed Encounters',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View past encounter details. Tap a row to open.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (showPhysicianScopeToggle) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('All'),
                            icon: Icon(Icons.groups_outlined, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Mine'),
                            icon: Icon(Icons.person_outline, size: 18),
                          ),
                        ],
                        selected: {_physicianShowMineOnly},
                        onSelectionChanged: (s) {
                          if (s.isEmpty) return;
                          setState(() => _physicianShowMineOnly = s.first);
                          _loadEncounters();
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText:
                                'Search by patient, doctor, ID, or chief complaint',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _filterDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null && mounted) {
                            setState(() => _filterDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _filterDate != null
                              ? DateFormat.yMMMd().format(_filterDate!)
                              : 'Filter by date',
                        ),
                      ),
                      if (_filterDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _filterDate = null),
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear date filter',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  FromToDateFilter(
                    doRefresh: () {},
                    dateFilter: true,
                    onFilterChanged: (
                      String query,
                      String category,
                      DateTime? from,
                      DateTime? to,
                    ) {
                      setState(() {
                        _fromDate = from;
                        _toDate = to;
                      });
                      _loadEncounters();
                    },
                  ),
                ],
              ),
            ),
          ),
          listSliver(),
        ],
      ),
    );
  }
}
