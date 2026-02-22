import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice_item.dart';

import '../models/invoice.dart';
import '../models/service_model.dart';
import '../widgets/filter.patients.dart';
import 'summary.bills.dart';

@RoutePage()
class PendingBillsScreen extends StatefulWidget {
  const PendingBillsScreen({super.key});

  @override
  PendingBillsState createState() => PendingBillsState();
}

class PendingBillsState extends State<PendingBillsScreen> {
  // Mock Data List
  List<Invoice> invoices = [
    Invoice(
      id: '1',
      patientId: 'Chidi Okoro',
      createdAt: DateTime.parse('2026-02-20'),
      invoiceItems: [
        InvoiceItem(
          serviceId: "Consultation Fee",
          quantity: 1,
          priceAtTime: 5000,
          id: '',
          invoiceId: '',
        ),
        InvoiceItem(
          serviceId: "Thyfoid (MP)",
          quantity: 1,
          priceAtTime: 2500,
          id: '',
          invoiceId: '',
        ),
        InvoiceItem(
          serviceId: "Paracetamol 500mg",
          quantity: 2,
          priceAtTime: 500,
          id: '',
          invoiceId: '',
        ),
      ],
      status: '',
      createdById: '',
      updatedAt: DateTime.parse('2026-02-20'),
    ),
  ];

  Invoice? selectedInvoice;

  // void _handleSelect(Invoice selectedInvoice) {
  //   setState(() {
  //     this.selectedInvoice = selectedInvoice;
  //   });
  // }

  double calculateAmountDue(List<InvoiceItem> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.priceAtTime),
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
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final patient = invoices[index];

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
                            // _showContextMenu(
                            //   context,
                            //   details.globalPosition,
                            //   patient,
                            //   _handleSelect,
                            // );
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
                                patient.patientId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Status: ${patient.status}"),
                                  Text(
                                    "Initiator: ${patient.createdById}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    patient.createdAt.toIso8601String(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                calculateAmountDue(
                                  patient.invoiceItems,
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
                  child: selectedInvoice == null
                      ? Center(child: Text('Please Select Bill To See Details'))
                      : SummaryBills(invoice: selectedInvoice!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// void _showContextMenu(
//   BuildContext context,
//   Offset position,
//   Invoice invoice,
//   void Function(Invoice) handleSelect,
// ) async {
//   final selected = await showMenu<String>(
//     context: context,
//     position: RelativeRect.fromLTRB(
//       position.dx,
//       position.dy,
//       position.dx,
//       position.dy,
//     ),
//     items: [
//       PopupMenuItem(
//         value: 'Make Payment',
//         onTap: () => openCustomModal(context, selectedItem),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [Icon(Icons.payment_outlined), Text('Make Payment')],
//         ),
//       ),
//       const PopupMenuItem(
//         value: 'Transfer To In-Patient',
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Icon(Icons.move_to_inbox_outlined),
//             Text('Transfer To In-Patient'),
//           ],
//         ),
//       ),
//       const PopupMenuItem(
//         value: 'View Details',
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [Icon(Icons.view_list_outlined), Text('View Details')],
//         ),
//       ),
//       const PopupMenuItem(
//         value: 'Bio Data',
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [Icon(Icons.person_2_outlined), Text('View Bio')],
//         ),
//       ),
//       const PopupMenuItem(
//         value: 'HMO',
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [Icon(Icons.local_post_office_outlined), Text('HMO')],
//         ),
//       ),
//     ],
//   );

//   // Menu is now fully dismissed — safe to update state.
//   if (selected == 'View Details') {
//     handleSelect(patient);
//   }
// }

void openCustomModal(BuildContext context, List<ServiceModel> selectedItems) {
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
                // child: PayBill(selectedItems: selectedItems, patient: null,, total: null,)
                child: Center(),
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
