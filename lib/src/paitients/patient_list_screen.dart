import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.gr.dart';
import '../helper/date.formatter.dart';
import 'patient_model.dart';
import 'patient_providers.dart';
import 'patient_service.dart';
import '../widgets/filter.patients.dart';

@RoutePage()
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
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
      if (_error != null && mounted) {
        setState(() => _error = null);
      }
      if (!mounted) return;
      setState(() {
        _patients.addAll(items);
        _skip += items.length;
        _hasMore = items.length == _take;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patients: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                setState(() => _error = null);
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _initialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleAction(String action, Patient patient) async {
    if (action == 'view') {
      _showPatientDetailsDialog(patient);
      return;
    }
    if (action == 'edit') {
      await context.router.push(PatientFormRoute(patient: patient));
      if (!mounted) return;
      await _refreshPatients();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete is not available from this view yet.'),
      ),
    );
  }

  void _showPatientDetailsDialog(Patient patient) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final admitted = patientStatusIsAdmitted(patient.status);
        return AlertDialog(
          title: Text('${patient.surname} ${patient.firstName}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Patient ID', patient.patientId),
                  _detailRow('Card No', patient.cardNo),
                  _detailRow('Title', patient.title),
                  _detailRow(
                    'Date of Birth',
                    DateFormatter.medicalDate(patient.dob),
                  ),
                  _detailRow('Gender', patient.gender),
                  _detailRow('Marital Status', patient.maritalStatus),
                  _detailRow('Nationality', patient.nationality),
                  _detailRow('State', patient.stateOfOrigin),
                  _detailRow('LGA', patient.lga),
                  _detailRow('Town', patient.town),
                  _detailRow('Religion', patient.religion ?? '—'),
                  _detailRow(
                    'Preferred Language',
                    patient.preferredLanguage ?? '—',
                  ),
                  _detailRow('Profession', patient.profession ?? '—'),
                  _detailRow('Phone', patient.phoneNumber ?? '—'),
                  _detailRow('Email', patient.email ?? '—'),
                  _detailRow('Address', patient.permanentAddress),
                  _detailRow(
                    'Address of Residence',
                    patient.addressOfResidence ?? '—',
                  ),
                  const Divider(height: 22),
                  _detailRow('Next of Kin', patient.nextOfKinName ?? '—'),
                  _detailRow(
                    'Next of Kin Phone',
                    patient.nextOfKinPhone ?? '—',
                  ),
                  _detailRow(
                    'Next of Kin Address',
                    patient.nextOfKinAddress ?? '—',
                  ),
                  _detailRow(
                    'Relationship',
                    patient.nextOfKinRelationship ?? '—',
                  ),
                  const Divider(height: 22),
                  _detailRow(
                    'HMO',
                    patient.hmoProvider != null
                        ? '${patient.hmoProvider!.name}'
                              '${patient.hmoProvider!.code != null && patient.hmoProvider!.code!.isNotEmpty ? ' (${patient.hmoProvider!.code})' : ''}'
                              '${patient.hmo != null && patient.hmo!.isNotEmpty ? ' · code: ${patient.hmo}' : ''}'
                        : (patient.hmo ?? '—'),
                  ),
                  _detailRow('Status', patient.status ?? '—'),
                  _detailRow('Admitted', admitted ? 'Yes' : 'No'),
                  if (admitted) ...[
                    _detailRow('Ward', patient.ward ?? '—'),
                    _detailRow('Bed Number', patient.bedNumber ?? '—'),
                    _detailRow(
                      'Admission Date',
                      patient.admissionDate != null
                          ? DateFormatter.medicalDate(patient.admissionDate!)
                          : '—',
                    ),
                  ],
                  const Divider(height: 22),
                  _detailRow(
                    'Created At',
                    patient.createdAt != null
                        ? DateFormatter.medicalDate(patient.createdAt!)
                        : '—',
                  ),
                  _detailRow('Created By', patient.createdBy ?? '—'),
                  _detailRow(
                    'Updated At',
                    patient.updatedAt != null
                        ? DateFormatter.medicalDate(patient.updatedAt!)
                        : '—',
                  ),
                  _detailRow('Updated By', patient.updatedBy ?? '—'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _handleAction('edit', patient);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Patient'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient, ColorScheme colorScheme) {
    final admitted = patientStatusIsAdmitted(patient.status);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.surname} ${patient.firstName} ${patient.otherName ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${patient.patientId}  •  Card: ${patient.cardNo}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(patient.status ?? 'UNKNOWN'),
                      avatar: Icon(
                        admitted ? Icons.bed : Icons.local_hospital_outlined,
                        size: 16,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'View patient',
                      onPressed: () => _handleAction('view', patient),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Edit patient',
                      onPressed: () => _handleAction('edit', patient),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('DOB: ${DateFormatter.medicalDate(patient.dob)}'),
                Text('Gender: ${patient.gender}'),
                Text('Phone: ${patient.phoneNumber ?? '—'}'),
              ],
            ),
            if (admitted) ...[
              const Divider(height: 20),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  Text('Ward: ${patient.ward ?? '—'}'),
                  Text('Bed: ${patient.bedNumber ?? '—'}'),
                  Text(
                    'Admitted: ${patient.admissionDate != null ? DateFormatter.medicalDate(patient.admissionDate!) : '—'}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Patient records'),
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Refresh list',
        onPressed: _refreshPatients,
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(
                _error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(Icons.error_outline, color: colorScheme.error),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Dismiss'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PatientsFilterWidget(
              searchCategories: const [
                {'name': 'patientId', 'value': 'Patient ID'},
                {'name': 'cardNo', 'value': 'Card No'},
                {'name': 'services', 'value': 'Services'},
                {'name': 'fullName', 'value': 'Patient Name'},
                {'name': 'transactionId', 'value': 'Transaction ID'},
              ],
              onFilterChanged:
                  (
                    String query,
                    String category,
                    DateTime? from,
                    DateTime? to,
                  ) {
                    setState(() {
                      _error = null;
                      _query = query;
                      _filterCategory = category;
                      _fromDate = from;
                      _toDate = to;
                    });
                    _refreshPatients();
                  },
              doRefresh: () {
                _refreshPatients();
              },
              dateFilter: false,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Material(
                color: colorScheme.surface,
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: _initialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _patients.isEmpty
                    ? const Center(
                        child: Text('No patient record found for this filter.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _patients.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _patients.length) {
                            if (!_hasMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text('You have reached the end.'),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                              child: FilledButton.icon(
                                onPressed: _isLoadingMore
                                    ? null
                                    : _loadPatientsPage,
                                icon: _isLoadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more),
                                label: Text(
                                  _isLoadingMore
                                      ? 'Loading more...'
                                      : 'Load More',
                                ),
                              ),
                            );
                          }
                          final patient = _patients[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              ProviderScope.containerOf(context, listen: false)
                                  .read(patientProvider.notifier)
                                  .selectPatient(patient);
                            },
                            child: _buildPatientCard(patient, colorScheme),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
