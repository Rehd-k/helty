import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/services/api_service.dart';

import '../helper/date.formatter.dart';
import 'patient_model.dart';
import 'patient_providers.dart';
import '../widgets/filter.patients.dart';
import '../widgets/table/reusable_async_table.dart';

@RoutePage()
class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListPageState();
}

class _PatientListPageState extends ConsumerState<PatientListScreen> {
  int skip = 0;
  int take = 20;
  ApiService apiService = ApiService();

  void _handleAction(String action, Patient patient, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  void handleSort(int columnIndex, bool ascending) {}

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final n = ref.read(patientProvider.notifier);
      n.setListStatusFilter(PatientListStatusFilter.none);
      n.fetchPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    return Scaffold(
      // appBar: AppBar(title: const Text("Patient Records")),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton.small(
        child: const Icon(Icons.add),
        onPressed: () {
          ref.read(patientProvider.notifier).fetchPatients();
        },
      ),

      body: Column(
        children: [
          PatientsFilterWidget(
            searchCategories: const [
              {'name': 'patientId', 'value': 'Patient ID'},
              {'name': 'cardNo', 'value': 'Card No'},
              {'name': 'services', 'value': 'Services'},
              {'name': 'fullName', 'value': 'Patient Name'},
              {'name': 'transactionId', 'value': 'Transaction ID'},
            ],
            onFilterChanged:
                (String query, String category, DateTime? from, DateTime? to) {
                  ref
                      .read(patientProvider.notifier)
                      .searchPatients(
                        skip,
                        take,
                        query,
                        category,
                        from,
                        to,
                        null,
                        null,
                        null,
                      );
                },
            doRefresh: () => ref.read(patientProvider.notifier).fetchPatients(),
            dateFilter: false,
          ),

          Expanded(
            child: ReusableAsyncTable<Patient>(
              fetchData: (start, count) async {
                start;
                count;
                // return the current patient list (pagination handled externally)
                return PagedData<Patient>(
                  totalCount: state.patients.length,
                  items: state.patients,
                );
              },
              idGetter: (patient) {
                return patient.id ?? '';
              }, // Used for selection logic
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  ref
                      .read(patientProvider.notifier)
                      .selectPatient(selected.first);
                }
              },
              // 4. Define Columns
              columns: [
                DataColumn2(label: Text('Patient ID'), size: ColumnSize.L),
                DataColumn2(label: Text('Card No'), size: ColumnSize.L),
                DataColumn2(label: Text('Title'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Surname'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(
                  label: Text('First Name'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(
                  label: Text('Other Name'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(label: Text('DOB'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Gender'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(label: Text('Marital Status'), size: ColumnSize.L),
                DataColumn2(label: Text('Nationality'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('State'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(label: Text('Address'), size: ColumnSize.L),
                DataColumn2(label: Text('Next of Kin'), size: ColumnSize.L),
                DataColumn2(label: Text('User'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Joined At'),
                  size: ColumnSize.L,
                  onSort: (columnIndex, ascending) {
                    handleSort(columnIndex, ascending);
                  },
                ),
                DataColumn2(label: Text('Updated At'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Action'),
                  fixedWidth: 60,
                ), // Fixed width for menu
              ],
              // 5. Build the Rows
              rowBuilder: (patient) {
                return [
                  DataCell(Text(patient.patientId)), // Patient ID
                  DataCell(Text(patient.cardNo)),
                  DataCell(Text(patient.title)),
                  DataCell(Text(patient.surname)),
                  DataCell(Text(patient.firstName)),
                  DataCell(Text(patient.otherName ?? '')), // Other Name
                  DataCell(Text(DateFormatter.medicalDate(patient.dob))), // DOB
                  DataCell(Text(patient.gender)), // Gender
                  DataCell(Text(patient.maritalStatus)), // Marital
                  DataCell(Text(patient.nationality)), // Nationality
                  DataCell(Text(patient.stateOfOrigin)), // State
                  DataCell(Text(patient.permanentAddress)), // Address
                  DataCell(Text(patient.nextOfKinName ?? '')), // Next of Kin
                  DataCell(Text(patient.createdBy ?? '')), // User
                  DataCell(
                    Text(
                      DateFormatter.medicalDate(
                        patient.createdAt ?? DateTime(DateTime.now() as int),
                      ),
                    ),
                  ), // Join
                  DataCell(
                    Text(
                      DateFormatter.medicalDate(
                        patient.updatedAt ?? DateTime(DateTime.now() as int),
                      ),
                    ),
                  ), // Update
                  // The Action Menu
                  DataCell(
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) =>
                          _handleAction(value, patient, context),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('View')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
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

          // Row(
          //   children: [
          //     ElevatedButton(
          //       onPressed: () {
          //         ref.read(patientProvider.notifier).previousPage();
          //       },
          //       child: const Text("Previous"),
          //     ),
          //     ElevatedButton(
          //       onPressed: () {
          //         ref.read(patientProvider.notifier).nextPage();
          //       },
          //       child: const Text("Next"),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
