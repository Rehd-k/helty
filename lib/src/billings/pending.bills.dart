import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

import '../widgets/filter.patients.dart';

// 1. The Mock Model
class PatientRecord {
  final String id;
  final String name;
  final String serviceFrom;
  final double amountDue;
  final String initiator;
  final String date;

  PatientRecord({
    required this.id,
    required this.name,
    required this.serviceFrom,
    required this.amountDue,
    required this.initiator,
    required this.date,
  });
}

@RoutePage()
class PendingBillsScreen extends StatefulWidget {
  const PendingBillsScreen({super.key});

  @override
  PendingBillsState createState() => PendingBillsState();
}

class PendingBillsState extends State<PendingBillsScreen> {
  // Mock Data List
  List<PatientRecord> patients = [
    PatientRecord(
      id: '1',
      name: 'Chidi Okoro',
      serviceFrom: 'Radiology',
      amountDue: 25000.00,
      initiator: 'Dr. Benson',
      date: '2026-02-20',
    ),
    PatientRecord(
      id: '2',
      name: 'Amina Yusuf',
      serviceFrom: 'Laboratory',
      amountDue: 12500.50,
      initiator: 'Nurse Chioma',
      date: '2026-02-21',
    ),
    PatientRecord(
      id: '3',
      name: 'Oluwaseun Ade',
      serviceFrom: 'General Ward',
      amountDue: 5000.00,
      initiator: 'Dr. Smith',
      date: '2026-02-19',
    ),
  ];

  // 3. Mock Functions
  void _handleRemove(String id) {
    setState(() {
      patients.removeWhere((p) => p.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record removed successfully'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleEdit(PatientRecord patient) {
    // This is the "Something Else" action (Swipe Right)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening editor for ${patient.name}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                (
                  String query,
                  String category,
                  DateTime? from,
                  DateTime? to,
                ) {},
            doRefresh: () {},
          ),
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];

                return Dismissible(
                  key: Key(patient.id),
                  // Swipe Right (Edit)
                  background: Container(
                    color: Colors.blue.shade400,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  // Swipe Left (Delete)
                  secondaryBackground: Container(
                    color: Colors.red.shade600,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      _handleRemove(patient.id);
                      return true; // Dismisses the widget
                    } else {
                      _handleEdit(patient);
                      return false; // Slides back, does not dismiss
                    }
                  },
                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        patient.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Service: ${patient.serviceFrom}"),
                          Text(
                            "Initiator: ${patient.initiator}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient.date,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: Text(
                        "₦${patient.amountDue.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
