import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/paitients/patient_providers.dart';

// ==========================================
// 1. MODELS (Mock Data Structures)
// ==========================================

enum ChargeCategory { daily, pharmacy, lab, radiology, surgery, other }

class ChargeItem {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final ChargeCategory category;
  final int quantity;

  ChargeItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.quantity = 1,
  });

  double get total => amount * quantity;
}

class PaymentItem {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String receiptNumber;

  PaymentItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    required this.receiptNumber,
  });
}

// ==========================================
// 2. MAIN BILLING SCREEN
// ==========================================

@RoutePage()
class PatientBillingScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const PatientBillingScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<PatientBillingScreen> createState() =>
      _PatientBillingScreenState();
}

class _PatientBillingScreenState extends ConsumerState<PatientBillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payments (no payments in Invoice model; can be extended when API available)
  final List<PaymentItem> _payments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Build charge items from invoice items (for display).
  static List<ChargeItem> _chargesFromInvoices(List<Invoice> invoices) {
    final list = <ChargeItem>[];
    for (final inv in invoices) {
      for (final item in inv.invoiceItems) {
        final qty = item.qty ?? 1;
        list.add(ChargeItem(
          id: '${inv.id}-${item.id}',
          description: item.name,
          amount: item.cost,
          quantity: qty,
          date: inv.createdAt,
          category: ChargeCategory.other,
        ));
      }
    }
    return list;
  }

  // --- Actions ---
  void _showAddActionSheet(
    BuildContext context,
    String effectivePatientId,
    String effectivePatientName,
  ) {
    final selectedPatient = ref.read(patientProvider).selectedPatient;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Add to bill',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.medication_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: const Text('Add drugs'),
                  subtitle: const Text('Medicine sales — saved as invoice for patient'),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(
                      DispenseRoute(
                        patientId: effectivePatientId,
                        patientName: effectivePatientName,
                        id: selectedPatient?.id ?? '',
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.radar, color: Colors.blue.shade800),
                  ),
                  title: const Text('Radiology'),
                  subtitle: const Text('Add radiology services'),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(EnlistPaitientRoute(serviceName: 'Investigation'));
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(Icons.science_outlined, color: Colors.teal.shade800),
                  ),
                  title: const Text('Labs'),
                  subtitle: const Text('Add laboratory services'),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(EnlistPaitientRoute(serviceName: 'Investigation'));
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.receipt_long, color: Colors.orange.shade800),
                  ),
                  title: const Text('Add other bills'),
                  subtitle: const Text('Room charges, daily charges, and other services'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddOtherBillsModal(context, effectivePatientId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    final effectivePatientId = widget.patientId.trim().isEmpty
        ? (selectedPatient?.patientId ?? '')
        : widget.patientId;
    final effectivePatientName = widget.patientName.trim().isEmpty
        ? (selectedPatient != null
            ? '${selectedPatient.firstName} ${selectedPatient.surname}'
            : '')
        : widget.patientName;

    final filter = InvoiceFilter(
      patientId: effectivePatientId.isEmpty ? null : effectivePatientId,
      limit: 200,
    );
    final invoicesAsync = ref.watch(invoicesProvider(filter));

    if (effectivePatientId.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Billing Dashboard'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Select a patient to view billing',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return invoicesAsync.when(
      data: (invoices) {
        final charges = _chargesFromInvoices(invoices);
        final totalCharges =
            charges.fold(0.0, (sum, item) => sum + item.total);
        final totalPayments =
            _payments.fold(0.0, (sum, item) => sum + item.amount);
        final balanceDue = totalCharges - totalPayments;
        return _buildContent(
          context,
          colorScheme,
          effectivePatientId: effectivePatientId,
          effectivePatientName: effectivePatientName,
          charges: charges,
          totalCharges: totalCharges,
          totalPayments: totalPayments,
          balanceDue: balanceDue,
        );
      },
      loading: () => Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Billing Dashboard', style: TextStyle(fontSize: 18)),
              Text(
                'Patient ID: $effectivePatientId',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                effectivePatientName,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Billing Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(err.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme, {
    required String effectivePatientId,
    required String effectivePatientName,
    required List<ChargeItem> charges,
    required double totalCharges,
    required double totalPayments,
    required double balanceDue,
  }) {
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Billing Dashboard', style: TextStyle(fontSize: 18)),
            Text(
              'Patient ID: $effectivePatientId',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Patient: $effectivePatientName',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Invoice',
            onPressed: () {},
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Itemized Charges'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFinancialSummary(
            colorScheme,
            balanceDue: balanceDue,
            totalCharges: totalCharges,
            totalPayments: totalPayments,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChargesTab(colorScheme, charges),
                _buildPaymentsTab(colorScheme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActionSheet(
          context,
          effectivePatientId,
          effectivePatientName,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  void _showAddOtherBillsModal(
    BuildContext context,
    String patientId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddOtherBillsSheet(
        patientId: patientId,
        onClose: () => Navigator.pop(ctx),
        onAdded: () {
          ref.invalidate(invoicesProvider);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildFinancialSummary(
    ColorScheme colorScheme, {
    required double balanceDue,
    required double totalCharges,
    required double totalPayments,
  }) {
    final bool isPaidOff = balanceDue <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance Due',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceDue.toFinancial(isMoney: true),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPaidOff ? Colors.green : colorScheme.error,
                  ),
                ),
                if (isPaidOff)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CLEARED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: colorScheme.outlineVariant),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Charges:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        totalCharges.toFinancial(isMoney: true),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        totalPayments.toFinancial(isMoney: true),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesTab(ColorScheme colorScheme, List<ChargeItem> charges) {
    // Group charges by Category
    final groupedCharges = <ChargeCategory, List<ChargeItem>>{};
    for (var charge in charges) {
      groupedCharges.putIfAbsent(charge.category, () => []).add(charge);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Compulsory & Daily Charges'),
        _buildChargeGroup(colorScheme, groupedCharges[ChargeCategory.daily] ?? []),
        const SizedBox(height: 24),

        _buildSectionHeader('Pharmacy & Medications'),
        _buildChargeGroup(colorScheme, groupedCharges[ChargeCategory.pharmacy] ?? []),
        const SizedBox(height: 24),

        _buildSectionHeader('Laboratory & Diagnostics'),
        _buildChargeGroup(
          colorScheme,
          [
            ...?groupedCharges[ChargeCategory.lab],
            ...?groupedCharges[ChargeCategory.radiology],
          ],
        ),
        _buildSectionHeader('Other'),
        _buildChargeGroup(colorScheme, groupedCharges[ChargeCategory.other] ?? []),
      ],
    );
  }

  Widget _buildChargeGroup(ColorScheme colorScheme, List<ChargeItem> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No charges in this category yet.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              item.description,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(fontSize: 12),
                ),
                if (item.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.total.toFinancial(isMoney: true),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.quantity > 1)
                  Text(
                    '${item.amount.toFinancial(isMoney: true)} each',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentsTab(ColorScheme colorScheme) {
    if (_payments.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
          ),
          color: Colors.green.withValues(alpha: 0.05),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
            title: Text(
              'Receipt: ${payment.receiptNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${_formatDate(payment.date)} • ${payment.method}'),
            trailing: Text(
              payment.amount.toFinancial(isMoney: true),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ==========================================
// Add Other Bills modal (services from backend)
// ==========================================

class _AddOtherBillsSheet extends ConsumerStatefulWidget {
  const _AddOtherBillsSheet({
    required this.patientId,
    required this.onClose,
    required this.onAdded,
  });

  final String patientId;
  final VoidCallback onClose;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddOtherBillsSheet> createState() => _AddOtherBillsSheetState();
}

class _AddOtherBillsSheetState extends ConsumerState<_AddOtherBillsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final servicesAsync = ref.watch(serviceListProvider(_query.isEmpty ? null : _query));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add other bills',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services (room, daily, etc.)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Enter a search term to find services'
                            : 'No services found',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            service.categoryName ?? service.departmentName ?? 'Service',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          trailing: Text(
                            service.cost.toFinancial(isMoney: true),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _addServiceToInvoice(context, service),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addServiceToInvoice(BuildContext context, ServiceModel service) async {
    final qtyCtrl = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(service.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ${service.cost.toFinancial(isMoney: true)}'),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(qtyCtrl.text);
              Navigator.pop(ctx, n != null && n > 0 ? n : 1);
            },
            child: const Text('Add to bill'),
          ),
        ],
      ),
    );
    qtyCtrl.dispose();
    if (qty == null || !mounted) return;
    try {
      final notifier = ref.read(invoiceNotifierProvider.notifier);
      await notifier.create(
        patientId: widget.patientId,
        status: 'PENDING',
        items: [
          {
            'serviceId': service.serviceId,
            'quantity': qty,
            'priceAtTime': service.cost,
          },
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${service.name} x$qty to bill')),
        );
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
