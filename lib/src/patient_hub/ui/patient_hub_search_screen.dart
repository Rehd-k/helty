import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../helper/date.formatter.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_service.dart';
import '../../widgets/filter.patients.dart';

@RoutePage()
class PatientHubSearchScreen extends StatefulWidget {
  const PatientHubSearchScreen({super.key});

  @override
  State<PatientHubSearchScreen> createState() => _PatientHubSearchScreenState();
}

class _PatientHubSearchScreenState extends State<PatientHubSearchScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  static const int _take = 20;

  String _query = '';
  String _filterCategory = 'fullName';
  final String _sortBy = 'surname';
  final bool _isAscending = false;
  String? _error;
  final List<Patient> _patients = <Patient>[];
  bool _initialLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value.trim());
      _refreshPatients();
    });
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

  void _openHub(Patient patient) {
    final uuid = patient.id;
    if (uuid == null || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This patient has no system ID; cannot open hub.'),
        ),
      );
      return;
    }
    context.router.push(PatientHubRoute(patientUuid: uuid));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Hub'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.35),
                  cs.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find a patient',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search clinical history without selecting a service patient.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Name, hospital number, phone…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _refreshPatients(),
                ),
                const SizedBox(height: 12),
                PatientsFilterWidget(
                  searchCategories: const [
                    {'name': 'fullName', 'value': 'Patient Name'},
                    {'name': 'patientId', 'value': 'Hospital No.'},
                    {'name': 'nameIdPhonenumber', 'value': 'Name / ID / Phone'},
                  ],
                  dateFilter: false,
                  doRefresh: _refreshPatients,
                  onFilterChanged: (query, category, from, to) {
                    _searchCtrl.text = query;
                    setState(() {
                      _query = query;
                      _filterCategory = category;
                    });
                    _refreshPatients();
                  },
                ),
              ],
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
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'Type to search patients'
                              : 'No patients found.',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
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
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    p.surname.isNotEmpty
                                        ? p.surname[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${p.surname} ${p.firstName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p.patientId} · ${DateFormatter.medicalDate(p.dob)} · ${p.gender}',
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: cs.primary,
                                ),
                                onTap: () => _openHub(p),
                              ),
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
