import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/patient_chart/models/patient_chart_models.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/patient_chart/services/patient_chart_service.dart';

/// Bottom sheet listing prior encounters for the same patient.
class PatientPreviousEncountersSheet extends StatefulWidget {
  const PatientPreviousEncountersSheet({
    super.key,
    required this.patientId,
    required this.currentEncounterId,
  });

  final String patientId;
  final String currentEncounterId;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    required String currentEncounterId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => PatientPreviousEncountersSheet(
          patientId: patientId,
          currentEncounterId: currentEncounterId,
        ),
      ),
    );
  }

  @override
  State<PatientPreviousEncountersSheet> createState() =>
      _PatientPreviousEncountersSheetState();
}

class _PatientPreviousEncountersSheetState
    extends State<PatientPreviousEncountersSheet> {
  final _service = PatientChartService();
  static const _pageSize = 30;

  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
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
      final response = await _service.getChart(
        widget.patientId,
        include: const [PatientChartSectionKeys.encounters],
        limit: _pageSize,
        skip: reset ? 0 : _skip,
      );
      if (!mounted) return;

      final fetched = response.section(PatientChartSectionKeys.encounters);
      final filtered = fetched
          .where(
            (e) =>
                e['id']?.toString() != widget.currentEncounterId &&
                e['encounterId']?.toString() != widget.currentEncounterId,
          )
          .toList();

      filtered.sort((a, b) {
        final da = _encounterDate(a);
        final db = _encounterDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(filtered);
        } else {
          _items.addAll(filtered);
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

  DateTime? _encounterDate(Map<String, dynamic> item) {
    for (final key in [
      'closedAt',
      'startedAt',
      'encounterDate',
      'createdAt',
    ]) {
      final dt = DateTime.tryParse(item[key]?.toString() ?? '');
      if (dt != null) return dt;
    }
    return null;
  }

  String _encounterId(Map<String, dynamic> item) =>
      item['id']?.toString() ?? item['encounterId']?.toString() ?? '';

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
    final id = _encounterId(item);
    if (id.isEmpty) return;

    final status = item['status']?.toString().toUpperCase() ?? '';
    if (status != 'COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only completed encounters can be opened for review.'),
        ),
      );
      return;
    }

    Navigator.pop(context);
    context.router.push(
      DoctorCompletedEncounterViewRoute(
        encounterId: id,
        patientId: widget.patientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Previous encounters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Past visits for this patient. Tap a completed encounter to open it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _load(reset: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _items.isEmpty
                ? Center(
                    child: Text(
                      'No previous encounters found.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return Center(
                          child: _loadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                )
                              : TextButton(
                                  onPressed: () => _load(reset: false),
                                  child: const Text('Load more'),
                                ),
                        );
                      }

                      final item = _items[index];
                      final date = _encounterDate(item);
                      final complaint = item['chiefComplaint']?.toString().trim();
                      final status = item['status']?.toString() ?? '';
                      final diagnosis = item['primaryIcdDescription']
                              ?.toString()
                              .trim() ??
                          item['primaryDiagnosis']?.toString().trim();
                      final type = item['encounterType']?.toString();
                      final completed = status.toUpperCase() == 'COMPLETED';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            complaint != null && complaint.isNotEmpty
                                ? complaint
                                : 'Encounter',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (date != null)
                                Text(DateFormatter.dateTime(date)),
                              Text(_doctorLabel(item)),
                              if (diagnosis != null && diagnosis.isNotEmpty)
                                Text(
                                  diagnosis,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(status.isEmpty ? '—' : status),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  if (type != null && type.isNotEmpty)
                                    Chip(
                                      label: Text(type),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: completed
                              ? const Icon(Icons.chevron_right)
                              : null,
                          isThreeLine: true,
                          onTap: completed ? () => _openEncounter(item) : null,
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
