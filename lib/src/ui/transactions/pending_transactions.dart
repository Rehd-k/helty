import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../models/pendding_transactions.model.dart';
import '../../widgets/table/reusable_async_table.dart';

@RoutePage()
class PendingTransactionsScreen extends StatefulWidget {
  const PendingTransactionsScreen({super.key});

  @override
  PendingTransactionsScreenState createState() =>
      PendingTransactionsScreenState();
}

class PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  String? selectedValue = "Out Patient";

  // 2. The API Fetcher Function
  // Updated Fetcher: Returns PagedData<Appointement>
  Future<PagedData<Transactions>> fetchPendingTransactions(
    int start,
    int count,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Mock delay

    // MOCK DATA logic
    final mockData = List.generate(count, (index) {
      final absoluteIndex = start + index;
      return Transactions(
        transactionId: 'PAT-$absoluteIndex',
        patientName: 'John Doe $absoluteIndex',
        amountDue: 100.0 + absoluteIndex,
        services: [],
        amountPaid: 300,
        ward: '',
        department: '',
        initaitor: '',
        date: DateTime(2024, 01, 10 + absoluteIndex),
        status: '',
      );
    });

    // Use PagedData instead of AsyncRowsResponse
    return PagedData(totalCount: 1000, items: mockData);
  }

  // 3. The Action Menu Handler
  void _handleAction(
    String action,
    Transactions patient,
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action $action performed on ${patient.patientName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transactions'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownMenu<String>(
              label: const Text("Designation"),
              initialSelection: selectedValue,

              dropdownMenuEntries: const [
                DropdownMenuEntry(value: "Out Patient", label: "Out Patient"),
                DropdownMenuEntry(value: "In Patient", label: "In Patient"),
              ],
              onSelected: (value) {
                setState(() => selectedValue = value);
              },
            ),
          ),
        ],
      ),
      body: ReusableAsyncTable<Transactions>(
        fetchData: fetchPendingTransactions,
        idGetter: (patient) =>
            patient.transactionId, // Used for selection logic
        onSelectionChanged: (selected) {
          // print("Selected Appointments: ${selected.length}");
        },

        columns: const [
          DataColumn2(label: Text('TRX ID'), size: ColumnSize.S),
          DataColumn2(label: Text('Name'), size: ColumnSize.S),
          DataColumn2(label: Text('Amount Due'), size: ColumnSize.M),
          DataColumn2(label: Text('Amount Paid'), size: ColumnSize.M),
          DataColumn2(label: Text('Ward'), size: ColumnSize.S),
          DataColumn2(label: Text('Initiator'), size: ColumnSize.S),
          DataColumn2(label: Text('Status'), size: ColumnSize.M),
          DataColumn2(label: Text('Created At'), size: ColumnSize.M),
          DataColumn2(
            label: Text('Action'),
            fixedWidth: 60,
          ), // Fixed width for menu
        ],
        // 5. Build the Rows
        rowBuilder: (patient) {
          return [
            DataCell(Text(patient.transactionId)),
            DataCell(Text(patient.patientName)),
            DataCell(Text(patient.amountDue.toString())),
            DataCell(Text(patient.amountPaid.toString())),
            DataCell(Text(patient.ward)),
            DataCell(Text(patient.initaitor)),
            DataCell(Text(patient.status)),
            DataCell(Text(patient.date.toString())),

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
