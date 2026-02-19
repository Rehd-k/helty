import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/models/appointment_model.dart';

import '../../providers/appointment_providers.dart';
import '../../widgets/table/reusable_async_table.dart';

class Appintment {
  final String id;
  final String firstName;
  final String lastName;
  final String datereported;
  final String appointmentDate;
  final String status;

  Appintment({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.datereported,
    required this.appointmentDate,
    required this.status,
  });

  // Factory to create from JSON
  factory Appintment.fromJson(Map<String, dynamic> json) {
    return Appintment(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      datereported: json['date_reported'],
      appointmentDate: json['appointment_date'],
      status: json['status'],
    );
  }
}

@RoutePage()
class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 2. The API Fetcher Function
  // Updated Fetcher: Returns PagedData<Appintment>
  Future<PagedData<Appintment>> fetchAppointments(int start, int count) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

    // MOCK DATA logic
    final mockData = List.generate(count, (index) {
      final absoluteIndex = start + index;
      return Appintment(
        id: 'APPT-$absoluteIndex',
        firstName: 'John $absoluteIndex',
        lastName: 'Doe',
        datereported: '2024-01-${10 + absoluteIndex}',
        appointmentDate: '2024-02-${15 + absoluteIndex}',
        status: absoluteIndex % 3 == 0
            ? 'Confirmed'
            : absoluteIndex % 3 == 1
            ? 'Pending'
            : 'Cancelled',
      );
    });

    // Use PagedData instead of AsyncRowsResponse
    return PagedData(totalCount: 1000, items: mockData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search appointments',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),
        ReusableAsyncTable<Appointment>(
          fetchData: fetchAppointments,
          idGetter: (appointment) => appointment.id, // Used for selection logic
          onSelectionChanged: (selected) {
            print("Selected Appointments: ${selected.length}");
          },
          // 4. Define Columns
          columns: const [
            DataColumn2(label: Text('ID'), size: ColumnSize.S),
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
              DataCell(Text(patient.patientName)),
              DataCell(Text(patient.status)),
              DataCell(Text(patient.date.toString())),
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
      ],
    );
  }
}
