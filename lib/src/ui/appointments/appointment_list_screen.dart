import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/models/appointment_model.dart';

import '../../widgets/filter.patients.dart';
import '../../widgets/table/reusable_async_table.dart';

@RoutePage()
class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() =>
      _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  Future<PagedData<Appointment>> fetchAppointments(int start, int count) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

    // MOCK DATA logic
    final mockData = List.generate(count, (index) {
      final absoluteIndex = start + index;
      return Appointment(
        id: 'APPT-$absoluteIndex',
        firstName: 'John $absoluteIndex',
        lastName: 'Doe',
        appointmentDate: DateTime(2024, 02, 15 + absoluteIndex),
        createdAt: DateTime(2024, 01, 10 + absoluteIndex),
        status: absoluteIndex % 3 == 0
            ? 'Confirmed'
            : absoluteIndex % 3 == 1
            ? 'Pending'
            : 'Cancelled',
        patientId: 'PAT-$absoluteIndex',
      );
    });

    // Use PagedData instead of AsyncRowsResponse
    return PagedData(totalCount: 1000, items: mockData);
  }

  // 3. The Action Menu Handler
  void _handleAction(String action, Appointment patient, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                // ref
                //     .read(patientProvider.notifier)
                //     .searchPatients(
                //       skip,
                //       take,
                //       query,
                //       category,
                //       from,
                //       to,
                //       null,
                //       null,
                //       null,
                //     );
              },
          doRefresh: () {},
        ),

        Expanded(
          child: ReusableAsyncTable<Appointment>(
            fetchData: fetchAppointments,
            idGetter: (appointment) =>
                appointment.id, // Used for selection logic
            onSelectionChanged: (selected) {
              // print("Selected Appointments: ${selected.length}");
            },
            // 4. Define Columns
            columns: const [
              DataColumn2(label: Text('ID'), size: ColumnSize.S),
              DataColumn2(label: Text('First Name'), size: ColumnSize.S),
              DataColumn2(label: Text('Last Name'), fixedWidth: 60),
              DataColumn2(label: Text('Status'), size: ColumnSize.M),
              DataColumn2(label: Text('Date Reported'), size: ColumnSize.M),
              DataColumn2(label: Text('Appointment Date'), size: ColumnSize.M),
              DataColumn2(
                label: Text('Action'),
                fixedWidth: 60,
              ), // Fixed width for menu
            ],
            // 5. Build the Rows
            rowBuilder: (patient) {
              return [
                DataCell(Text(patient.id)),
                DataCell(Text(patient.firstName)),
                DataCell(Text(patient.lastName)),
                DataCell(Text(patient.status)),
                DataCell(Text(patient.appointmentDate.toString())),
                DataCell(Text(patient.createdAt.toString())),

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
      ],
    );
  }
}
