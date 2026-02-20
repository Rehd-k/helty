import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.gr.dart';
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

  void _handleAction(String action, Patient patient, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  void makeCallAgain() {
    print('object');
    ref.read(patientProvider.notifier).fetchPatients();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(patientProvider.notifier).fetchPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    log(state.patients.toList().toString());
    return Scaffold(
      // appBar: AppBar(title: const Text("Patient Records")),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton.small(
        child: const Icon(Icons.add),
        onPressed: () {
          context.router.push(PatientFormRoute());
        },
      ),

      body: Column(
        children: [
          PatientsFilterWidget(
            searchCategories: const [
              'Patient ID',
              'Card No',
              'Surname',
              'First Name',
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
            doRefresh: makeCallAgain,
          ),
          IconButton(
            onPressed: () => ref.read(patientProvider.notifier).fetchPatients(),
            icon: Icon(Icons.refresh),
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
                log(patient.toString());
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
              columns: const [
                DataColumn2(label: Text('Patient ID'), size: ColumnSize.L),
                DataColumn2(label: Text('Card No'), size: ColumnSize.L),
                DataColumn2(label: Text('Title'), size: ColumnSize.L),
                DataColumn2(label: Text('Surname'), size: ColumnSize.L),
                DataColumn2(label: Text('First Name'), size: ColumnSize.L),
                DataColumn2(label: Text('Other Name'), size: ColumnSize.L),
                DataColumn2(label: Text('DOB'), size: ColumnSize.L),
                DataColumn2(label: Text('Gender'), size: ColumnSize.L),
                DataColumn2(label: Text('Marital Status'), size: ColumnSize.L),
                DataColumn2(label: Text('Nationality'), size: ColumnSize.L),
                DataColumn2(label: Text('State'), size: ColumnSize.L),
                DataColumn2(label: Text('Address'), size: ColumnSize.L),
                DataColumn2(label: Text('Next of Kin'), size: ColumnSize.L),
                DataColumn2(label: Text('User'), size: ColumnSize.L),
                DataColumn2(label: Text('Joined At'), size: ColumnSize.L),
                DataColumn2(label: Text('Updated At'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Action'),
                  fixedWidth: 60,
                ), // Fixed width for menu
              ],
              // 5. Build the Rows
              rowBuilder: (patient) {
                return [
                  DataCell(Text(patient.patientId ?? '')), // Patient ID
                  DataCell(Text(patient.cardNo)),
                  DataCell(Text(patient.title)),
                  DataCell(Text(patient.surname)),
                  DataCell(Text(patient.firstName)),
                  const DataCell(Text("-")), // Other Name
                  const DataCell(Text("01/01/1990")), // DOB
                  const DataCell(Text("M")), // Gender
                  const DataCell(Text("Single")), // Marital
                  const DataCell(Text("Nigerian")), // Nationality
                  const DataCell(Text("Lagos")), // State
                  const DataCell(Text("123 Street")), // Address
                  const DataCell(Text("Jane Doe")), // Next of Kin
                  const DataCell(Text("Admin")), // User
                  const DataCell(Text("2023-01-01")), // Join
                  const DataCell(Text("2023-01-02")), // Update
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
