import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/ui/patients/patient_form_screen.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../models/patient_model.dart';
import '../../widgets/table/reusable_async_table.dart';

@RoutePage()
class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  // 2. The API Fetcher Function
  // Updated Fetcher: Returns PagedData<Patient>
  Future<PagedData<Patient>> fetchPatients(int start, int count) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

    // MOCK DATA logic
    final mockData = List.generate(count, (index) {
      final absoluteIndex = start + index;
      return Patient(
        id: 'PAT-$absoluteIndex',
        cardNo: 'CN-${1000 + absoluteIndex}',
        title: absoluteIndex % 2 == 0 ? 'Mr' : 'Mrs',
        surname: 'Doe',
        firstName: 'John $absoluteIndex',
        patientId: '',
        dob: DateTime(2029, 01, 01 + absoluteIndex),
        gender: '',
        maritalStatus: '',
        nationality: '',
        stateOfOrigin: '',
        lga: '',
        town: '',
        permanentAddress: '',
      );
    });

    // Use PagedData instead of AsyncRowsResponse
    return PagedData(totalCount: 1000, items: mockData);
  }

  // 3. The Action Menu Handler
  void _handleAction(String action, Patient patient, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Records")),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton.small(
        child: const Icon(Icons.add),
        onPressed: () {
          showCupertinoModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return PatientFormScreen();
            },
          );
        },
      ),

      body: ReusableAsyncTable<Patient>(
        fetchData: fetchPatients,
        idGetter: (patient) => patient.id, // Used for selection logic
        onSelectionChanged: (selected) {
          // print("Selected Patients: ${selected.length}");
        },
        // 4. Define Columns
        columns: const [
          DataColumn2(label: Text('Patient ID'), size: ColumnSize.S),
          DataColumn2(label: Text('Card No'), size: ColumnSize.S),
          DataColumn2(label: Text('Title'), fixedWidth: 60),
          DataColumn2(label: Text('Surname'), size: ColumnSize.M),
          DataColumn2(label: Text('First Name'), size: ColumnSize.M),
          DataColumn2(label: Text('Other Name'), size: ColumnSize.M),
          DataColumn2(label: Text('DOB'), size: ColumnSize.S),
          DataColumn2(label: Text('Gender'), fixedWidth: 70),
          DataColumn2(label: Text('Marital Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Nationality'), size: ColumnSize.M),
          DataColumn2(label: Text('State'), size: ColumnSize.M),
          DataColumn2(label: Text('Address'), size: ColumnSize.L),
          DataColumn2(label: Text('Next of Kin'), size: ColumnSize.M),
          DataColumn2(label: Text('User'), size: ColumnSize.S),
          DataColumn2(label: Text('Joined At'), size: ColumnSize.M),
          DataColumn2(label: Text('Updated At'), size: ColumnSize.M),
          DataColumn2(
            label: Text('Action'),
            fixedWidth: 60,
          ), // Fixed width for menu
        ],
        // 5. Build the Rows
        rowBuilder: (patient) {
          return [
            DataCell(Text(patient.id)),
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
                onSelected: (value) => _handleAction(value, patient, context),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}
