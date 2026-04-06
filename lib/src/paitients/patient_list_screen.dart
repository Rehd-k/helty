import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helper/date.formatter.dart';
import 'patient_model.dart';
import 'patient_providers.dart';
import 'patient_service.dart';
import '../widgets/filter.patients.dart';
import '../widgets/table/reusable_async_table.dart';

@RoutePage()
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientService _patientService = PatientService();

  String _query = '';
  String _filterCategory = 'patientId';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sortBy = 'surname';
  bool _isAscending = false;
  String? _error;

  Future<PagedData<Patient>> _fetchPage(int start, int count) async {
    try {
      final items = await _patientService.fetchPatients(
        query: _query.isEmpty ? null : _query,
        skip: start,
        take: count,
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
      final totalCount = items.length < count
          ? start + items.length
          : start + items.length + 1;
      return PagedData<Patient>(items: items, totalCount: totalCount);
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
      return PagedData<Patient>(items: [], totalCount: 0);
    }
  }

  void _handleAction(String action, Patient patient, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  void _onSortColumn(int columnIndex, bool ascending) {
    const indexToField = <int, String>{
      3: 'surname',
      4: 'firstName',
      5: 'otherName',
      7: 'gender',
      10: 'stateOfOrigin',
      14: 'createdAt',
    };
    final field = indexToField[columnIndex];
    if (field == null) return;
    setState(() {
      if (_sortBy == field) {
        _isAscending = ascending;
      } else {
        _sortBy = field;
        _isAscending = ascending;
      }
    });
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
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() => _error = null);
        },
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
                  },
              doRefresh: () {
                setState(() => _error = null);
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
                child: ReusableAsyncTable<Patient>(
                  key: ValueKey(
                    '$_query|$_filterCategory|'
                    '${_fromDate?.millisecondsSinceEpoch}|${_toDate?.millisecondsSinceEpoch}|'
                    '$_sortBy|$_isAscending',
                  ),
                  rowsPerPage: 20,
                  fetchData: _fetchPage,
                  idGetter: (patient) => patient.id ?? '',
                  onSelectionChanged: (selected) {
                    if (selected.isEmpty) return;
                    ProviderScope.containerOf(context, listen: false)
                        .read(patientProvider.notifier)
                        .selectPatient(selected.first);
                  },
                  columns: [
                    DataColumn2(
                      label: const Text('Patient ID'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: const Text('Card No'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(label: const Text('Title'), size: ColumnSize.L),
                    DataColumn2(
                      label: const Text('Surname'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(
                      label: const Text('First Name'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(
                      label: const Text('Other Name'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(label: const Text('DOB'), size: ColumnSize.L),
                    DataColumn2(
                      label: const Text('Gender'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(
                      label: const Text('Marital Status'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: const Text('Nationality'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: const Text('State'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(
                      label: const Text('Address'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: const Text('Next of Kin'),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(label: const Text('User'), size: ColumnSize.L),
                    DataColumn2(
                      label: const Text('Joined At'),
                      size: ColumnSize.L,
                      onSort: _onSortColumn,
                    ),
                    DataColumn2(
                      label: const Text('Updated At'),
                      size: ColumnSize.L,
                    ),
                    const DataColumn2(label: Text('Action'), fixedWidth: 60),
                  ],
                  rowBuilder: (patient) {
                    return [
                      DataCell(Text(patient.patientId)),
                      DataCell(Text(patient.cardNo)),
                      DataCell(Text(patient.title)),
                      DataCell(Text(patient.surname)),
                      DataCell(Text(patient.firstName)),
                      DataCell(Text(patient.otherName ?? '')),
                      DataCell(Text(DateFormatter.medicalDate(patient.dob))),
                      DataCell(Text(patient.gender)),
                      DataCell(Text(patient.maritalStatus)),
                      DataCell(Text(patient.nationality)),
                      DataCell(Text(patient.stateOfOrigin)),
                      DataCell(Text(patient.permanentAddress)),
                      DataCell(Text(patient.nextOfKinName ?? '')),
                      DataCell(Text(patient.createdBy ?? '')),
                      DataCell(
                        Text(
                          patient.createdAt != null
                              ? DateFormatter.medicalDate(patient.createdAt!)
                              : '—',
                        ),
                      ),
                      DataCell(
                        Text(
                          patient.updatedAt != null
                              ? DateFormatter.medicalDate(patient.updatedAt!)
                              : '—',
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) =>
                              _handleAction(value, patient, context),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ];
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
