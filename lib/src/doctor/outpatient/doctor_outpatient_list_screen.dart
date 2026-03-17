import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/encounter_service.dart';

import '../../widgets/date.filter.dart';

@RoutePage()
class DoctorOutpatientListScreen extends ConsumerStatefulWidget {
  const DoctorOutpatientListScreen({super.key});

  @override
  ConsumerState<DoctorOutpatientListScreen> createState() =>
      _DoctorOutpatientListScreenState();
}

class _DoctorOutpatientListScreenState
    extends ConsumerState<DoctorOutpatientListScreen> {
  final _encounterService = EncounterService();
  final _patientService = PatientService();

  DateTime? _fromDate = DateTime.now();
  DateTime? _toDate = DateTime.now();
  List<EncounterModel> _encounters = [];
  Map<String, Patient?> _patients = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final staff = ref.read(authProvider).staff;
      final doctorId = staff?.id ?? staff?.staffId ?? 'DOC-1';
      final list = await _encounterService.fetchOutpatientEncounters(
        doctorId: doctorId,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      final patientIds = list.map((e) => e.patientId).toSet().toList();
      final Map<String, Patient?> patients = {};
      for (final id in patientIds) {
        try {
          patients[id] = await _patientService.getPatientById(id);
        } catch (_) {
          patients[id] = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _encounters = list;
        _patients = patients;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Appointments',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Outpatient list — click a row to open encounter.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          FromToDateFilter(
            doRefresh: () => _load(),
            dateFilter: true,
            onFilterChanged:
                (String query, String category, DateTime? from, DateTime? to) {
                  setState(() {
                    _fromDate = from;
                    _toDate = to;
                  });
                  _load();
                },
          ),

          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildTable(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _headerCell('PATIENT NAME'),
                _headerCell('AGE'),
                _headerCell('APPOINTMENT TIME'),
                _headerCell('STATUS'),
                _headerCell('VISIT TYPE'),
                _headerCell('INSURANCE'),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _encounters.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final enc = _encounters[index];
                final patient = _patients[enc.patientId];
                final name = patient != null
                    ? '${patient.firstName} ${patient.surname}'
                    : 'Patient ${enc.patientId}';
                final age = patient != null
                    ? '${DateTime.now().year - patient.dob.year} yrs'
                    : '—';
                final status = enc.status == 'waiting'
                    ? 'Waiting'
                    : enc.status == 'in_consultation'
                    ? 'In Consultation'
                    : 'Done';
                final statusColor = enc.status == 'waiting'
                    ? Colors.orange
                    : enc.status == 'in_consultation'
                    ? colorScheme.primary
                    : Colors.green;

                return InkWell(
                  onTap: () => _openEncounter(context, enc),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            age,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatTime(enc.startedAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            enc.visitType ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            enc.insurance ?? '—',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _openEncounter(BuildContext context, EncounterModel enc) {
    context.router.push(
      DoctorEncounterViewRoute(encounterId: enc.id, patientId: enc.patientId),
    );
  }
}
