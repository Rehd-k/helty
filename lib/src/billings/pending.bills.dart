import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/providers/invoices_providers.dart';

import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../widgets/filter.patients.dart';
import 'pay.bill.dart';
import 'summary.bills.dart';

@RoutePage()
class PendingBillsScreen extends ConsumerStatefulWidget {
  const PendingBillsScreen({super.key});

  @override
  PendingBillsState createState() => PendingBillsState();
}

class PendingBillsState extends ConsumerState<PendingBillsScreen> {
  Invoice? selectedInvoice;

  /// Current filter from the search bar and date range.
  InvoiceFilter _filter = const InvoiceFilter(limit: 500);

  void _handleSelect(Invoice invoice) {
    setState(() => selectedInvoice = invoice);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final invoicesAsync = ref.watch(invoicesProvider(_filter));

    return Scaffold(
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
            onFilterChanged: (
              String query,
              String category,
              DateTime? from,
              DateTime? to,
            ) {
              setState(() {
                _filter = InvoiceFilter(
                  query: query.isEmpty ? null : query,
                  category: category,
                  from: from,
                  to: to,
                  limit: 500,
                );
              });
            },
            doRefresh: () {
              ref.invalidate(invoicesProvider(_filter));
            },
            dateFilter: true,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: invoicesAsync.when(
                    data: (invoices) {
                      if (invoices.isEmpty) {
                        return const Center(
                          child: Text('No pending invoices'),
                        );
                      }
                      return ListView.builder(
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];

                      return Slidable(
                        key: Key(invoice.id),
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
                          onTap: () => _handleSelect(invoice),
                          onSecondaryTapDown: (details) {
                            _showContextMenu(
                              context,
                              details.globalPosition,
                              invoice,
                              auth,
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
                                invoice.patientId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Status: ${invoice.status}"),
                                  Text(
                                    "Initiator: ${invoice.createdById}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    invoice.createdAt.toIso8601String(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                invoice.total.toFinancial(isMoney: true),
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
                  );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load invoices: $err',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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

void _showContextMenu(
  BuildContext context,
  Offset position,
  Invoice invoice,
  AuthState auth,
  void Function(Invoice) handleSelect,
) async {
  // Position menu with its top-left at the cursor so it appears right next to the mouse.
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx + 1,
      position.dy + 1,
    ),
    items: [
      if (auth.staff?.role == 'bills')
        PopupMenuItem(
          value: 'Make Payment',
          onTap: () => openCustomModal(context, invoice, auth.staff?.id ?? ''),
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

  //   // Menu is now fully dismissed — safe to update state.
  if (selected == 'View Details') {
    handleSelect(invoice);
  }
}

void openCustomModal(BuildContext context, Invoice invoice, String staffId) {
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
                child: PayBill(
                  hasId: invoice.patientId.isNotEmpty,
                  selectedItems: invoice.invoiceItems,
                  patientId: invoice.patientId,
                  firstName: 'Patient Name',
                  total: invoice.total,
                  staffId: staffId,
                ),
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
