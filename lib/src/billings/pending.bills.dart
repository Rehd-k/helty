import 'dart:ui';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

import '../helper/date.formatter.dart';
import '../models/invoice.dart';
import '../models/staff_model.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
import '../widgets/filter.patients.dart';
import 'pay.bill.dart';
import 'summary.bills.dart';

bool _staffIsBilling(Staff? staff) {
  if (staff == null) return false;
  final at = staff.accountType?.name.toLowerCase() ?? '';
  if (at == 'billing' || at == 'bills') return true;
  final r = staff.role.toUpperCase();
  return r == 'BILLING_HEAD' ||
      r == 'BILLING_STAFF' ||
      staff.role.toLowerCase() == 'bills';
}

@RoutePage()
class PendingBillsScreen extends ConsumerStatefulWidget {
  const PendingBillsScreen({super.key});

  @override
  PendingBillsState createState() => PendingBillsState();
}

class PendingBillsState extends ConsumerState<PendingBillsScreen> {
  Invoice? selectedInvoice;

  /// Current filter from the search bar and date range.
  InvoiceFilter _filter = const InvoiceFilter(limit: 500, allowIP: false);

  final InvoiceService _invoiceService = InvoiceService();

  /// True until [PatientsFilterWidget] applies defaults (post-frame) and load finishes.
  bool _isLoading = true;
  String? _error;
  List<Invoice> _invoices = const [];
  final Set<String> _deletingInvoiceIds = <String>{};
  final Set<String> _splittingInvoiceIds = <String>{};

  @override
  void initState() {
    super.initState();
    // Do not call _loadInvoices here: [PatientsFilterWidget] notifies once after first
    // frame with status, category, and date range. An eager load used the wrong _filter.
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
        allowIP: _filter.allowIP,
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

  bool _canDeleteInvoice(Invoice invoice, String? currentStaffId) {
    if (currentStaffId == null || currentStaffId.isEmpty) return false;
    return invoice.createdById == currentStaffId || invoice.staffId == currentStaffId;
  }

  String _cleanErrorMessage(Object error, {String fallback = 'Unable to split invoice'}) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return fallback;
    if (raw.startsWith('Exception:')) {
      final cleaned = raw.replaceFirst('Exception:', '').trim();
      return cleaned.isEmpty ? fallback : cleaned;
    }
    return raw;
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    if (_deletingInvoiceIds.contains(invoice.id)) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.id}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _deletingInvoiceIds.add(invoice.id));
    try {
      await _invoiceService.deleteInvoice(invoice.id);
      if (!mounted) return;
      setState(() {
        _invoices = _invoices.where((i) => i.id != invoice.id).toList();
        if (selectedInvoice?.id == invoice.id) {
          selectedInvoice = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e, fallback: 'Unable to delete invoice'))),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingInvoiceIds.remove(invoice.id));
      }
    }
  }

  Future<void> _showSplitInvoiceDialog(Invoice invoice) async {
    if (_splittingInvoiceIds.contains(invoice.id)) return;

    final items = invoice.invoiceItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice has no line items to split')),
      );
      return;
    }

    final selectedItemIds = <String>{};
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final selectableItems = items
                .where((it) => !it.settled && it.amountPaid <= 0.001 && it.id.isNotEmpty)
                .toList();
            final selectableCount = selectableItems.length;
            final allSelectableChosen =
                selectableCount > 0 && selectedItemIds.length == selectableCount;

            Future<void> submitSplit() async {
              if (selectedItemIds.isEmpty || isSubmitting) return;

              if (allSelectableChosen) {
                await showDialog<void>(
                  context: ctx,
                  builder: (warnCtx) => AlertDialog(
                    title: const Text('Cannot split all items'),
                    content: const Text(
                      'Moving all items would leave the original invoice empty. Select fewer items and try again.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(warnCtx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);
              setState(() => _splittingInvoiceIds.add(invoice.id));
              try {
                final result = await _invoiceService.splitInvoice(
                  invoiceId: invoice.id,
                  invoiceItemIds: selectedItemIds.toList(),
                );
                if (!mounted) return;

                setState(() {
                  final updated = <Invoice>[];
                  for (final inv in _invoices) {
                    if (inv.id == invoice.id) {
                      updated.add(result.original);
                      updated.add(result.splitOff);
                    } else {
                      updated.add(inv);
                    }
                  }
                  _invoices = updated;
                  if (selectedInvoice?.id == invoice.id) {
                    selectedInvoice = result.original;
                  }
                });

                if (ctx.mounted) Navigator.of(ctx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invoice split successfully'),
                    action: SnackBarAction(
                      label: 'Open New Invoice',
                      onPressed: () {
                        if (!mounted) return;
                        setState(() => selectedInvoice = result.splitOff);
                      },
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _cleanErrorMessage(e, fallback: 'Unable to split invoice'),
                    ),
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _splittingInvoiceIds.remove(invoice.id));
                }
                if (ctx.mounted) {
                  setDialogState(() => isSubmitting = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Split Invoice'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select line items to move to a new invoice'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          final lineTotal = item.cost * (item.qty ?? 1);
                          final isSelectable =
                              !item.settled && item.amountPaid <= 0.001 && item.id.isNotEmpty;
                          final isSelected = selectedItemIds.contains(item.id);
                          final subtitle = isSelectable
                              ? lineTotal.toFinancial(isMoney: true)
                              : 'Not eligible (paid/settled)';

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: isSelectable && !isSubmitting
                                ? (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedItemIds.add(item.id);
                                      } else {
                                        selectedItemIds.remove(item.id);
                                      }
                                    });
                                  }
                                : null,
                            title: Text(item.name),
                            subtitle: Text(subtitle),
                            secondary: !isSelectable
                                ? const Icon(Icons.lock_outline, color: Colors.grey)
                                : null,
                          );
                        },
                      ),
                    ),
                    if (selectedItemIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Select at least one item to continue.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (allSelectableChosen)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Warning: selecting all eligible lines is not allowed.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedItemIds.isEmpty || isSubmitting ? null : submitSplit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Split'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onInvoiceFilterChanged(
    String query,
    String category,
    DateTime? from,
    DateTime? to,
  ) {
    setState(() {
      _filter = InvoiceFilter(
        status: 'PENDING',
        query: query.isEmpty ? null : query,
        category: category,
        from: from,
        to: to,
        limit: 500,
        allowIP: false,
      );
    });
    _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final currentStaffId = auth.staff?.id;
    return Scaffold(
      body: Column(
        children: [
          PatientsFilterWidget(
            searchCategories: const [
              {'name': 'patientId', 'value': 'Patient ID'},
              {'name': 'services', 'value': 'Services'},
              {'name': 'fullName', 'value': 'Patient Name'},
            ],
            onFilterChanged: _onInvoiceFilterChanged,
            doRefresh: _loadInvoices,
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
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          if (_canDeleteInvoice(invoice, currentStaffId))
                                            ElevatedButton.icon(
                                              onPressed: _deletingInvoiceIds.contains(invoice.id)
                                                  ? null
                                                  : () => _deleteInvoice(invoice),
                                              icon: _deletingInvoiceIds.contains(invoice.id)
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(Icons.delete_outline, size: 16),
                                              label: const Text('Delete'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red.shade600,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(0, 34),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: _splittingInvoiceIds.contains(invoice.id)
                                                ? null
                                                : () => _showSplitInvoiceDialog(invoice),
                                            icon: _splittingInvoiceIds.contains(invoice.id)
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(Icons.call_split, size: 16),
                                            label: const Text('Split'),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 34),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                            ),
                                          ),
                                        ],
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
  final bool allowIP;
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
    this.allowIP = true,
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
      if (_staffIsBilling(auth.staff))
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
                  isInvoice: true,
                  selectedItems: invoice.invoiceItems,
                  patientId: invoice.patientId,
                  firstName: invoice.patient.firstName,
                  lastName: invoice.patient.surname,
                  total: invoice.total,
                  staffId: staffId,
                  invoiceId: invoice.id,
                  preserveInvoiceOnDismiss: true,
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
