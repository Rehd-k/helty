import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/shared/finance_status_colors.dart';
import 'package:intl/intl.dart';

@RoutePage()
class PatientBillingAccountScreen extends ConsumerStatefulWidget {
  const PatientBillingAccountScreen({super.key});

  @override
  ConsumerState<PatientBillingAccountScreen> createState() =>
      _PatientBillingAccountScreenState();
}

class _PatientBillingAccountScreenState
    extends ConsumerState<PatientBillingAccountScreen>
    with SingleTickerProviderStateMixin {
  final InvoiceService _invoiceService = InvoiceService();

  late final TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Invoice> _invoices = const [];
  List<PatientAccountPayment> _payments = const [];

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final selected = ref.read(patientProvider).selectedPatient;
    final patientUuid = selected?.id?.trim();
    if (patientUuid == null || patientUuid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Select a patient to open their billing account.';
        _invoices = const [];
        _payments = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final account = await _invoiceService.getPatientBillingAccount(patientUuid);
      var invoices = account.invoices;
      var payments = account.payments;

      final from = _fromDate;
      final to = _toDate;
      if (from != null || to != null) {
        invoices = invoices.where((inv) {
          final at = inv.createdAt;
          if (from != null && at.isBefore(from)) return false;
          if (to != null && at.isAfter(to)) return false;
          return true;
        }).toList();
        payments = payments.where((p) {
          final at = p.paidAt;
          if (at == null) return true;
          if (from != null && at.isBefore(from)) return false;
          if (to != null && at.isAfter(to)) return false;
          return true;
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _payments = payments;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? AppTimezone.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = DateTime(picked.year, picked.month, picked.day);
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        );
      }
    });
    await _load();
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? AppTimezone.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _toDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
        999,
      );
    });
    await _load();
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _load();
  }

  String _billTypeLabel(Invoice invoice) {
    final type = (invoice.billType ?? '').toUpperCase();
    if (type == 'INPATIENT') {
      final ward = invoice.wardName?.trim();
      return (ward != null && ward.isNotEmpty) ? 'Ward · $ward' : 'Ward';
    }
    return 'OPD';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(patientProvider, (previous, next) {
      final prevId = previous?.selectedPatient?.id;
      final nextId = next.selectedPatient?.id;
      if (prevId != nextId) {
        Future.microtask(() {
          if (mounted) _load();
        });
      }
    });

    final selected = ref.watch(patientProvider).selectedPatient;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final name = selected?.displayName.trim();
    final hospitalId = selected?.patientId.trim();
    final hasDateFilter = _fromDate != null || _toDate != null;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Patient billing account'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Payment history'),
          ],
        ),
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (name == null || name.isEmpty) ? '—' : name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hospitalId == null || hospitalId.isEmpty
                        ? 'No hospital ID'
                        : 'Patient ID: $hospitalId',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickFrom,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          _fromDate == null
                              ? 'From (all)'
                              : 'From ${DateFormatter.medicalDate(_fromDate!)}',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickTo,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          _toDate == null
                              ? 'To (all)'
                              : 'To ${DateFormatter.medicalDate(_toDate!)}',
                        ),
                      ),
                      if (hasDateFilter)
                        TextButton(
                          onPressed: _clearDates,
                          child: const Text('Show all history'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _InvoicesTab(
                          invoices: _invoices,
                          billTypeLabel: _billTypeLabel,
                          onOpenInvoice: (invoice) async {
                            final displayName =
                                selected?.displayName.trim().isNotEmpty == true
                                ? selected!.displayName
                                : invoice.patient.displayName;
                            await context.router.push(
                              PatientBillingRoute(
                                invoiceId: invoice.id,
                                patientName: displayName,
                              ),
                            );
                            if (mounted) _load();
                          },
                        ),
                        _PaymentsTab(
                          payments: _payments,
                          onOpenInvoice: (invoiceId) async {
                            if (invoiceId == null || invoiceId.isEmpty) return;
                            final displayName =
                                selected?.displayName.trim().isNotEmpty == true
                                ? selected!.displayName
                                : 'Patient';
                            await context.router.push(
                              PatientBillingRoute(
                                invoiceId: invoiceId,
                                patientName: displayName,
                              ),
                            );
                            if (mounted) _load();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab({
    required this.invoices,
    required this.billTypeLabel,
    required this.onOpenInvoice,
  });

  final List<Invoice> invoices;
  final String Function(Invoice) billTypeLabel;
  final Future<void> Function(Invoice) onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (invoices.isEmpty) {
      return Center(
        child: Text(
          'No invoices for this patient',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final code = invoice.invoiceDisplayId?.trim().isNotEmpty == true
            ? invoice.invoiceDisplayId!
            : invoice.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onOpenInvoice(invoice),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          billTypeLabel(invoice),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FinanceStatusColors.invoiceStatus(
                            invoice.status,
                            colorScheme,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          invoice.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: FinanceStatusColors.invoiceStatus(
                              invoice.status,
                              colorScheme,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, y').format(invoice.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        invoice.total.toFinancial(isMoney: true),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Paid ${invoice.amountPaid.toFinancial(isMoney: true)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({
    required this.payments,
    required this.onOpenInvoice,
  });

  final List<PatientAccountPayment> payments;
  final Future<void> Function(String? invoiceId) onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (payments.isEmpty) {
      return Center(
        child: Text(
          'No payments recorded for this patient',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final method = payment.method?.trim().isNotEmpty == true
            ? payment.method!
            : payment.source;
        final invoiceLabel = payment.invoiceNumber?.trim().isNotEmpty == true
            ? payment.invoiceNumber!
            : (payment.invoiceId ?? 'Invoice');
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onOpenInvoice(payment.invoiceId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoiceLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        payment.amount.toFinancial(isMoney: true),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  if (payment.paidForSummary != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      payment.paidForSummary!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    payment.paidAt == null
                        ? '—'
                        : DateFormat('MMM d, y h:mm a').format(payment.paidAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
