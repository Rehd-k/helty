import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/encounter_service.dart';
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

  List<EncounterModel> _encounters = [];
  final Map<String, Patient> _patientCache = {};
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime? _filterDate;
  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
        _filterDisplayed();
      }
    });
    _loadEncounters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEncounters() async {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not logged in.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Backend may use 'COMPLETED' or 'completed' or 'closed'
      var list = await _encounterService.fetchOutpatientEncounters(
        doctorId: doctorId,
        status: 'COMPLETED',
        take: 200,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (list.isEmpty) {
        list = await _encounterService.fetchOutpatientEncounters(
          doctorId: doctorId,
          status: 'COMPLETED',
          take: 200,
          fromDate: _fromDate,
          toDate: _toDate,
        );
      }
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadPatientsForEncounters(List<EncounterModel> list) async {
    for (final e in list) {
      if (_patientCache.containsKey(e.patientId)) continue;
      try {
        final p = await _patientService.getPatientById(e.patientId);
        if (!mounted) return;
        setState(() => _patientCache[e.patientId] = p);
      } catch (_) {
        // skip failed patient load
      }
    }
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
        return name.contains(q) ||
            complaint.contains(q) ||
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

    if (_loading && _encounters.isEmpty) {
      return Center(
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
      );
    }

    if (_error != null && _encounters.isEmpty) {
      return Center(
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
      );
    }

    final filtered = _filteredEncounters;

    return RefreshIndicator(
      onRefresh: _loadEncounters,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText:
                              'Search by patient name, ID, or chief complaint',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                  // Only update the selected range; do not auto-call the API
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
                    // API will be called explicitly via _loadEncounters
                    // (e.g. pull-to-refresh or Retry button)
                  },
                ),
              ],
            ),
          ),
          if (filtered.isEmpty)
            Expanded(
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
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat.yMMMd().format(closed)} • ${e.primaryIcdDescription ?? e.status}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onTap: () => _openEncounter(e),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
