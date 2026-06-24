import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/dialysis/utils/dialysis_patient_encounters_utils.dart';
import 'package:helty/src/dialysis/widgets/dialysis_encounter_notes_sheet.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/patient_chart/models/patient_chart_models.dart';
import 'package:helty/src/patient_chart/services/patient_chart_service.dart';

const _pageSize = 30;

@RoutePage()
class DialysisPatientEncountersScreen extends StatefulWidget {
  const DialysisPatientEncountersScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  /// Patient UUID used by chart / encounter APIs.
  final String patientId;
  final String? patientName;

  @override
  State<DialysisPatientEncountersScreen> createState() =>
      _DialysisPatientEncountersScreenState();
}

class _DialysisPatientEncountersScreenState
    extends State<DialysisPatientEncountersScreen> {
  final _service = PatientChartService();

  final List<Map<String, dynamic>> _encounters = [];
  DialysisEncounterStatusFilter _filterStatus = DialysisEncounterStatusFilter.all;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  String? _error;

  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    final (start, end) = defaultDialysisEncounterDateRange();
    _dateRange = DateTimeRange(start: start, end: end);
    _load(reset: true);
  }

  (DateTime, DateTime) _queryBounds() {
    final r = _dateRange;
    return (
      DateTime(r.start.year, r.start.month, r.start.day),
      DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
    await _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _skip = 0;
        _hasMore = true;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final (from, to) = _queryBounds();
      final response = await _service.getChart(
        widget.patientId,
        include: const [PatientChartSectionKeys.encounters],
        limit: _pageSize,
        skip: reset ? 0 : _skip,
        fromDate: from,
        toDate: to,
      );
      if (!mounted) return;

      final fetched = response.section(PatientChartSectionKeys.encounters);
      final sorted = sortEncountersNewestFirst(fetched);

      setState(() {
        if (reset) {
          _encounters
            ..clear()
            ..addAll(sorted);
        } else {
          _encounters.addAll(sorted);
        }
        _skip = (reset ? 0 : _skip) + _pageSize;
        _hasMore = fetched.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEncounters {
    final (from, to) = _queryBounds();
    final byDate = filterEncountersByDateRange(_encounters, from, to);
    return filterEncountersByStatus(byDate, _filterStatus);
  }

  String _doctorLabel(Map<String, dynamic> item) {
    final doctor = item['doctor'];
    if (doctor is Map) {
      final nested = doctor['displayName']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return 'Dr $nested';
      final name = [
        doctor['firstName'],
        doctor['lastName'],
        doctor['surname'],
      ].whereType<String>().join(' ').trim();
      if (name.isNotEmpty) return 'Dr $name';
    }
    final flat = item['doctorDisplayName']?.toString().trim();
    if (flat != null && flat.isNotEmpty) return 'Dr $flat';
    return '—';
  }

  void _openEncounter(Map<String, dynamic> item) {
    final id = encounterIdFromMap(item);
    if (id.isEmpty) return;

    final status = item['status']?.toString().toUpperCase() ?? '';
    if (status == 'ONGOING') {
      context.router.push(
        DoctorEncounterViewRoute(
          encounterId: id,
          patientId: widget.patientId,
        ),
      );
      return;
    }
    if (status == 'COMPLETED') {
      context.router.push(
        DoctorCompletedEncounterViewRoute(
          encounterId: id,
          patientId: widget.patientId,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'CANCELLED'
              ? 'This encounter was cancelled.'
              : 'This encounter cannot be opened.',
        ),
      ),
    );
  }

  Future<void> _openNotes(Map<String, dynamic> item) async {
    final id = encounterIdFromMap(item);
    if (id.isEmpty) return;

    final status = item['status']?.toString() ?? '';
    if (status.toUpperCase() == 'CANCELLED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot add notes to cancelled encounters.')),
      );
      return;
    }

    final saved = await showDialysisEncounterNotesSheet(
      context: context,
      encounterId: id,
      status: status,
      chiefComplaint: item['chiefComplaint']?.toString(),
    );
    if (saved == true) {
      await _load(reset: true);
    }
  }

  String _dateRangeLabel() {
    final start = DateFormatter.medicalDate(_dateRange.start);
    final end = DateFormatter.medicalDate(_dateRange.end);
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.patientName?.trim().isNotEmpty == true
        ? widget.patientName!.trim()
        : 'Patient encounters';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () => _load(reset: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _load(reset: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Encounters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Filter by date, open an encounter, or add notes directly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range_rounded),
                        label: Text(_dateRangeLabel()),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in [
                            (DialysisEncounterStatusFilter.all, 'All'),
                            (DialysisEncounterStatusFilter.ongoing, 'Ongoing'),
                            (DialysisEncounterStatusFilter.completed, 'Completed'),
                            (DialysisEncounterStatusFilter.cancelled, 'Cancelled'),
                          ])
                            _StatusChip(
                              label: entry.$2,
                              selected: _filterStatus == entry.$1,
                              onTap: () =>
                                  setState(() => _filterStatus = entry.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_filteredEncounters.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No encounters for this patient in the selected range.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._filteredEncounters.map((item) {
                          final date = encounterDateFromMap(item);
                          final complaint =
                              item['chiefComplaint']?.toString().trim();
                          final status = item['status']?.toString() ?? '';
                          final diagnosis = item['primaryIcdDescription']
                                  ?.toString()
                                  .trim() ??
                              item['primaryDiagnosis']?.toString().trim();
                          final type = item['encounterType']?.toString();
                          final canOpen = status.toUpperCase() == 'ONGOING' ||
                              status.toUpperCase() == 'COMPLETED';
                          final canNotes =
                              status.toUpperCase() != 'CANCELLED';
                          final notesPreview = encounterNotesPreviewFromMap(item);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: canOpen ? () => _openEncounter(item) : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  complaint != null &&
                                                          complaint.isNotEmpty
                                                      ? complaint
                                                      : 'Encounter',
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (date != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    DateFormatter.dateTime(
                                                      date,
                                                    ),
                                                  ),
                                                ],
                                                Text(_doctorLabel(item)),
                                                if (diagnosis != null &&
                                                    diagnosis.isNotEmpty)
                                                  Text(
                                                    diagnosis,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (canOpen)
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            label: Text(
                                              status.isEmpty ? '—' : status,
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          if (type != null && type.isNotEmpty)
                                            Chip(
                                              label: Text(type),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          if (notesPreview != null)
                                            Chip(
                                              avatar: const Icon(
                                                Icons.notes_rounded,
                                                size: 16,
                                              ),
                                              label: const Text('Has notes'),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                        ],
                                      ),
                                      if (notesPreview != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          notesPreview,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      if (canNotes) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FilledButton.tonalIcon(
                                            onPressed: () => _openNotes(item),
                                            icon: Icon(
                                              notesPreview != null
                                                  ? Icons.edit_note_rounded
                                                  : Icons.note_add_outlined,
                                            ),
                                            label: Text(
                                              notesPreview != null
                                                  ? 'Update notes'
                                                  : 'Add notes',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      if (_hasMore &&
                          _filterStatus == DialysisEncounterStatusFilter.all)
                        Center(
                          child: _loadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                )
                              : TextButton(
                                  onPressed: () => _load(reset: false),
                                  child: const Text('Load more'),
                                ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}
