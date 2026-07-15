import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/core/responsive.dart';
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
class DoctorOngoingEncountersScreen extends ConsumerStatefulWidget {
  const DoctorOngoingEncountersScreen({super.key});

  @override
  ConsumerState<DoctorOngoingEncountersScreen> createState() =>
      _DoctorOngoingEncountersScreenState();
}

class _DoctorOngoingEncountersScreenState
    extends ConsumerState<DoctorOngoingEncountersScreen> {
  final _encounterService = EncounterService();
  final _patientService = PatientService();
  final _staffService = StaffService();

  List<EncounterModel> _encounters = [];
  final Map<String, Patient> _patientCache = {};
  final Map<String, String> _doctorNameCache = {};
  bool _loading = true;
  String? _error;
  DateTime? _fromDate;
  DateTime? _toDate;

  /// Physicians: `true` = logged-in doctor only; `false` = all doctors.
  bool _physicianShowMineOnly = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  /// Same criteria as [DoctorCompletedEncountersScreen] / Home physician menu.
  bool _isPhysicianStaff(Staff? staff) {
    if (staff == null) return false;
    final at = staff.accountType?.name.toLowerCase() ?? '';
    final r = staff.staffRole.toLowerCase();
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
      final id = staff.id.trim().isNotEmpty
          ? staff.id.trim()
          : staff.staffId.trim();
      if (id.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Could not determine doctor ID.';
        });
        return;
      }
      doctorIdFilter = id;
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
        status: 'ONGOING',
        fromDate: _fromDate,
        toDate: _toDate,
        take: 200,
      );
      if (!mounted) return;
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      setState(() {
        _encounters = list;
        _loading = false;
      });
      _loadPatientsForEncounters(list);
      if (!_physicianShowMineOnly) {
        _loadDoctorsForEncounters(list);
      }
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

  String _statusLabel(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'ONGOING':
        return 'Ongoing';
      case 'WAITING':
        return 'Waiting';
      case 'IN_CONSULTATION':
        return 'In Consultation';
      default:
        return status;
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    final s = status.toUpperCase();
    switch (s) {
      case 'WAITING':
        return Colors.orange;
      case 'IN_CONSULTATION':
        return scheme.primary;
      case 'ONGOING':
        return scheme.tertiary;
      default:
        return scheme.onSurface;
    }
  }

  void _openEncounter(EncounterModel encounter) {
    context.router.push(
      DoctorEncounterViewRoute(
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
    final showDoctorOnRows =
        showPhysicianScopeToggle && !_physicianShowMineOnly;

    return ResponsiveBody(
      center: false,
      bottomPadding: 24,
      builder: (context, bp) => RefreshIndicator(
        onRefresh: _loadEncounters,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ongoing Encounters',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showPhysicianScopeToggle && !_physicianShowMineOnly
                        ? 'All open OPD encounters. Tap a row to continue.'
                        : 'Your open OPD encounters. Tap a row to continue.',
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
                  FromToDateFilter(
                    doRefresh: () {},
                    dateFilter: true,
                    onFilterChanged:
                        (
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
            _buildListSliver(theme, colorScheme, bp, showDoctorOnRows),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver(
    ThemeData theme,
    ColorScheme colorScheme,
    AppBreakpoints bp,
    bool showDoctorOnRows,
  ) {
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
                'Loading ongoing encounters…',
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

    if (_encounters.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pending_actions_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No ongoing encounters.',
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
      padding: EdgeInsets.only(top: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final e = _encounters[index];
          final patient = _patientCache[e.patientId];
          final name = patient != null
              ? patient.displayName
              : 'Patient ${e.patientId}';
          final statusColor = _statusColor(e.status, colorScheme);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: patient != null
                  ? PatientAvatar.fromPatient(
                      patient,
                      size: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    )
                  : PatientAvatar(
                      firstName: name.trim(),
                      size: 40,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
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
                  if (showDoctorOnRows) ...[
                    const SizedBox(height: 4),
                    Text(
                      _doctorLabel(e),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.yMMMd().add_jm().format(e.startedAt)} • ${e.visitType ?? 'OPD'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              trailing: bp.isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(e.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(e.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
              onTap: () => _openEncounter(e),
            ),
          );
        }, childCount: _encounters.length),
      ),
    );
  }
}
