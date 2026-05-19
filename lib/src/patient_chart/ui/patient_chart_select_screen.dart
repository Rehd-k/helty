import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../helper/date.formatter.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_service.dart';
import '../../widgets/filter.patients.dart';

@RoutePage()
class PatientChartSelectScreen extends StatefulWidget {
  const PatientChartSelectScreen({super.key});

  @override
  State<PatientChartSelectScreen> createState() =>
      _PatientChartSelectScreenState();
}

class _PatientChartSelectScreenState extends State<PatientChartSelectScreen> {
  final PatientService _patientService = PatientService();
  static const int _take = 20;

  String _query = '';
  String _filterCategory = 'patientId';
  DateTime? _fromDate;
  DateTime? _toDate;
  final String _sortBy = 'surname';
  final bool _isAscending = false;
  String? _error;
  final List<Patient> _patients = <Patient>[];
  bool _initialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _refreshPatients();
  }

  Future<void> _refreshPatients() async {
    setState(() {
      _skip = 0;
      _patients.clear();
      _hasMore = true;
      _initialLoading = true;
    });
    await _loadPatientsPage(reset: true);
  }

  Future<void> _loadPatientsPage({bool reset = false}) async {
    if (!reset && (_isLoadingMore || !_hasMore)) return;
    if (!mounted) return;
    setState(() {
      if (!reset) _isLoadingMore = true;
    });
    try {
      final items = await _patientService.fetchPatients(
        query: _query.isEmpty ? null : _query,
        skip: _skip,
        take: _take,
        filterCategory: _filterCategory,
        fromDate: _fromDate,
        toDate: _toDate,
        sortBy: _sortBy,
        isAscending: _isAscending,
        listStatusFilter: PatientListStatusFilter.none,
      );
      if (!mounted) return;
      setState(() {
        _patients.addAll(items);
        _skip += items.length;
        _hasMore = items.length == _take;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _openChart(Patient patient) {
    final uuid = patient.id;
    if (uuid == null || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This patient has no system ID; cannot open chart.'),
        ),
      );
      return;
    }
    context.router.push(PatientChartRoute(patientUuid: uuid));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient chart')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PatientsFilterWidget(
              searchCategories: const [
                {'name': 'patientId', 'value': 'Patient ID'},
                {'name': 'cardNo', 'value': 'Card No'},
                {'name': 'fullName', 'value': 'Patient Name'},
              ],
              dateFilter: false,
              doRefresh: _refreshPatients,
              onFilterChanged: (query, category, from, to) {
                setState(() {
                  _query = query;
                  _filterCategory = category;
                  _fromDate = from;
                  _toDate = to;
                });
                _refreshPatients();
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? const Center(child: Text('No patients found.'))
                    : RefreshIndicator(
                        onRefresh: _refreshPatients,
                        child: ListView.builder(
                          itemCount: _patients.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _patients.length) {
                              if (_isLoadingMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Center(
                                child: TextButton(
                                  onPressed: () => _loadPatientsPage(),
                                  child: const Text('Load more'),
                                ),
                              );
                            }
                            final p = _patients[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  p.surname.isNotEmpty
                                      ? p.surname[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text('${p.surname} ${p.firstName}'),
                              subtitle: Text(
                                '${p.patientId} · ${DateFormatter.medicalDate(p.dob)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openChart(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
