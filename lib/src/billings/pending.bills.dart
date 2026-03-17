import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

import '../helper/date.formatter.dart';
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
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

  final InvoiceService _invoiceService = InvoiceService();
  bool _isLoading = false;
  String? _error;
  List<Invoice> _invoices = const [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final invoices = await _invoiceService.getInvoices(
        patientId: _filter.patientId,
        status: _filter.status,
        query: _filter.query,
        category: _filter.category,
        from: _filter.from,
        to: _filter.to,
        page: _filter.page,
        limit: _filter.limit,
      );

      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSelect(Invoice invoice) {
    setState(() => selectedInvoice = invoice);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

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
            onFilterChanged:
                (String query, String category, DateTime? from, DateTime? to) {
                  setState(() {
                    _filter = InvoiceFilter(
                      status: 'DRAFT',
                      query: query.isEmpty ? null : query,
                      category: category,
                      from: from,
                      to: to,
                      limit: 500,
                    );
                  });

                  _loadInvoices();
                },
            doRefresh: () {
              _loadInvoices();
            },
            dateFilter: true,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (_error != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Failed to load invoices: $_error',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (_invoices.isEmpty) {
                        return const Center(child: Text('No pending invoices'));
                      }

                      return ListView.builder(
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];

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
                                    '${invoice.patient.firstName} ${invoice.patient.surname}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text("Status: ${invoice.status}"),
                                      Text(
                                        "Initiator: ${invoice.staff['firstName']} ${invoice.staff['lastName']}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormatter.dateTime(
                                          invoice.createdAt,
                                        ),
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

class InvoiceFilter {
  final String? patientId;
  final String? status;
  final String? query;
  final String? category;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int limit;

  const InvoiceFilter({
    this.patientId,
    this.status,
    this.query,
    this.category,
    this.from,
    this.to,
    this.page = 1,
    this.limit = 100,
  });
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

void openCustomModal(
  BuildContext context,
  Invoice invoice,
  String staffId,
) {
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
                  isInvoice: true,
                  hasId: invoice.patientId.isNotEmpty,
                  selectedItems: invoice.invoiceItems,
                  patientId: invoice.patientId,
                  firstName: invoice.patient.firstName,
                  total: invoice.total,
                  staffId: staffId,
                  invoiceId: invoice.id,
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
