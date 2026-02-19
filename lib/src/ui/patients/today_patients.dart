import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/todays.patients.dart';

import '../../widgets/table/reusable_async_table.dart';

@RoutePage()
class TodayPatientsScreen extends StatefulWidget {
  const TodayPatientsScreen({super.key});

  @override
  TodayPatientsScreenState createState() => TodayPatientsScreenState();
}

class TodayPatientsScreenState extends State<TodayPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 2. The API Fetcher Function
  // Updated Fetcher: Returns PagedData<Appointement>
  Future<PagedData<TodaysPatient>> fetchTodaysPatients(
    int start,
    int count,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

    // MOCK DATA logic
    final mockData = List.generate(count, (index) {
      final absoluteIndex = start + index;
      return TodaysPatient(
        id: 'PAT-$absoluteIndex',
        patientId: 'PAT-$absoluteIndex',
        firstName: 'John $absoluteIndex',
        lastName: 'Doe',
        createdAt: DateTime(2024, 01, 10 + absoluteIndex),
        status: absoluteIndex % 3 == 0
            ? 'Confirmed'
            : absoluteIndex % 3 == 1
            ? 'Pending'
            : 'Cancelled',
        linkDetails: 'null',
        invoiceNo: '',
        services: [],
        initiator: '',
        scheme: '',
      );
    });

    // Use PagedData instead of AsyncRowsResponse
    return PagedData(totalCount: 1000, items: mockData);
  }

  // 3. The Action Menu Handler
  void _handleAction(
    String action,
    TodaysPatient patient,
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.firstName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search appointments',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'ID',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_outlined),
            tooltip: 'NO ID',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'View All',
            onPressed: () {},
          ),
        ],
      ),
      body: ReusableAsyncTable<TodaysPatient>(
        fetchData: fetchTodaysPatients,
        idGetter: (patient) => patient.id, // Used for selection logic
        onSelectionChanged: (selected) {
          // print("Selected Appointments: ${selected.length}");
        },

        columns: const [
          DataColumn2(label: Text('ID'), size: ColumnSize.S),
          DataColumn2(label: Text('First Name'), size: ColumnSize.S),
          DataColumn2(label: Text('Last Name'), fixedWidth: 60),
          DataColumn2(label: Text('Status'), size: ColumnSize.M),
          DataColumn2(label: Text('Invoice No'), size: ColumnSize.M),
          DataColumn2(label: Text('Created At'), size: ColumnSize.M),
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
            DataCell(Text(patient.invoiceNo ?? 'N/A')),
            DataCell(Text(patient.createdAt.toString())),

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
