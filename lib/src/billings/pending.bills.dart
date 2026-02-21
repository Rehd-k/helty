import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

import '../widgets/filter.patients.dart';
import 'pay.bill.dart';
import 'summary.bills.dart';

class PatientRecord {
  final String id;
  final String name;
  final String serviceFrom;
  final double amountDue;
  final String initiator;
  final String date;
  final List<ServiceItem> details;

  PatientRecord({
    required this.id,
    required this.name,
    required this.serviceFrom,
    required this.amountDue,
    required this.initiator,
    required this.date,
    required this.details,
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
      details: [
        ServiceItem(service: "Consultation Fee", qty: 1, price: 5000),
        ServiceItem(service: "Thyfoid (MP)", qty: 1, price: 2500),
        ServiceItem(service: "Paracetamol 500mg", qty: 2, price: 500),
      ],
    ),
    PatientRecord(
      id: '2',
      name: 'Amina Yusuf',
      serviceFrom: 'Laboratory',
      amountDue: 12500.50,
      initiator: 'Nurse Chioma',
      date: '2026-02-21',
      details: [
        ServiceItem(service: "Consultation Fee", qty: 1, price: 5000),
        ServiceItem(service: "Malaria Test (MP)", qty: 1, price: 2500),
        ServiceItem(service: "Paracetamol 500mg", qty: 2, price: 500),
      ],
    ),
    PatientRecord(
      id: '3',
      name: 'Oluwaseun Ade',
      serviceFrom: 'General Ward',
      amountDue: 5000.00,
      initiator: 'Dr. Smith',
      date: '2026-02-19',
      details: [ServiceItem(service: "Consultation Fee", qty: 1, price: 5000)],
    ),
  ];

  PatientRecord? selectedPatient;

  void _handleSelect(PatientRecord patient) {
    setState(() {
      selectedPatient = patient;
    });
  }

  double calculateAmountDue(List<ServiceItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.qty * item.price));
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
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];

                      return Slidable(
                        key: Key(patient.id),
                        startActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) {},
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),

                            SlidableAction(
                              onPressed: (_) {},
                              backgroundColor: Colors.orange,
                              icon: Icons.archive,
                              label: 'Archive',
                            ),

                            SlidableAction(
                              onPressed: (_) {},
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onSecondaryTapDown: (details) {
                            // pass current patient and callback when showing the menu
                            _showContextMenu(
                              context,
                              details.globalPosition,
                              patient,
                              _handleSelect,
                            );
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
                                calculateAmountDue(
                                  patient.details,
                                ).toFinancial(isMoney: true),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: selectedPatient == null
                      ? Center(child: Text('Please Select Bill To See Details'))
                      : SummaryBills(patient: selectedPatient!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showContextMenu(
  BuildContext context,
  Offset position,
  PatientRecord patient,
  void Function(PatientRecord) handleSelect,
) async {
  // Capture the selected value and act on it AFTER the menu has fully
  // closed. Using onTap fires while the overlay is still animating away,
  // which causes setState to be skipped by Flutter's rendering pipeline.
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      PopupMenuItem(
        value: 'Make Payment',
        onTap: () => openCustomModal(context, patient),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Icon(Icons.payment_outlined), Text('Make Payment')],
        ),
      ),
      const PopupMenuItem(
        value: 'Transfer To In-Patient',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.move_to_inbox_outlined),
            Text('Transfer To In-Patient'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'View Details',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Icon(Icons.view_list_outlined), Text('View Details')],
        ),
      ),
      const PopupMenuItem(
        value: 'Bio Data',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Icon(Icons.person_2_outlined), Text('View Bio')],
        ),
      ),
      const PopupMenuItem(
        value: 'HMO',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Icon(Icons.local_post_office_outlined), Text('HMO')],
        ),
      ),
    ],
  );

  // Menu is now fully dismissed — safe to update state.
  if (selected == 'View Details') {
    handleSelect(patient);
  }
}

void openCustomModal(BuildContext context, PatientRecord patient) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final blur = animation.value * 6.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              // blurred + dimmed backdrop
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  color: Colors.black.withValues(alpha: animation.value * 0.45),
                ),
              ),
              // the modal itself — Material is required by DropdownButton
              // (showGeneralDialog does not inject one automatically)
              Material(
                color: Colors.transparent,
                child: Center(child: PayBill(patient: patient)),
              ),
            ],
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}
