import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/shared/finance_status_colors.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:intl/intl.dart';

bool _looksLikeUuid(String s) {
  final t = s.trim();
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(t);
}

@RoutePage()
class InpatientBillsListScreen extends ConsumerStatefulWidget {
  const InpatientBillsListScreen({super.key});

  @override
  ConsumerState<InpatientBillsListScreen> createState() =>
      _InpatientBillsListScreenState();
}

class _InpatientBillsListScreenState
    extends ConsumerState<InpatientBillsListScreen> {
  final InvoiceService _invoiceService = InvoiceService();

  bool _isLoading = true;
  String? _error;
  List<Invoice> _invoices = const [];
  bool _creatingBill = false;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selectedPatient = ref.read(patientProvider).selectedPatient;
      final patientUuid = selectedPatient?.id;
      final from = _fromDate;
      final to = _toDate;
      final List<Invoice> invoices;
      if (patientUuid != null && _looksLikeUuid(patientUuid)) {
        invoices = await _invoiceService.getInvoices(
          patientId: patientUuid,
          from: from,
          to: to,
          limit: 500,
        );
      } else {
        invoices = await _invoiceService.getInvoices(
          from: from,
          to: to,
          limit: 500,
        );
      }
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _openServicesForNewBill() async {
    final selected = ref.read(patientProvider).selectedPatient;
    final uuid = selected?.id?.trim();
    if (uuid == null || !_looksLikeUuid(uuid)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a registered patient before adding a bill.'),
        ),
      );
      return;
    }
    setState(() => _creatingBill = true);
    try {
      await ref
          .read(invoiceNotifierProvider.notifier)
          .getOrCreateBillingInvoice(
            patientId: uuid,
            staffId: ref.read(authProvider).staff?.id,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not start billing: $e')));
      }
      return;
    } finally {
      if (mounted) setState(() => _creatingBill = false);
    }
    if (!mounted) return;
    await context.router.push(const RenderServiceRoute());
    if (mounted) _loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(patientProvider, (previous, next) {
      final prevId = previous?.selectedPatient?.id;
      final nextId = next.selectedPatient?.id;
      if (prevId != nextId) {
        Future.microtask(() {
          if (mounted) _loadInvoices();
        });
      }
    });

    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Inpatient Bills'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveToolbar(
              actions: [
                FilledButton.icon(
                  onPressed: (_isLoading || _creatingBill)
                      ? null
                      : _openServicesForNewBill,
                  icon: _creatingBill
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.receipt_long_outlined, size: 20),
                  label: Text(_creatingBill ? 'Opening…' : 'Add bill'),
                ),
              ],
              leading: Text(
                'Opens the services list so you can add lines to this '
                "patient's invoice (a bill is created if needed).",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
            FromToDateFilter(
              doRefresh: _loadInvoices,
              dateFilter: true,
              onFilterChanged:
                  (
                    String query,
                    String category,
                    DateTime? from,
                    DateTime? to,
                  ) {
                    setState(() {
                      _fromDate = from;
                      _toDate = to;
                    });
                    _loadInvoices();
                  },
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(selectedPatient, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Patient? selectedPatient, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    final invoices = _invoices;
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No inpatient bills found for this range',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final displayName = invoice.patient.displayName.trim();
        final patientName =
            displayName.isEmpty || displayName == 'Unknown' ? '—' : displayName;
        return _BillCard(
          invoice: invoice,
          patientName: patientName,
          onTap: () async {
            await context.router.push(
              PatientBillingRoute(
                invoiceId: invoice.id,
                patientName: patientName,
              ),
            );
            if (mounted) _loadInvoices();
          },
          colorScheme: colorScheme,
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.invoice,
    required this.patientName,
    required this.onTap,
    required this.colorScheme,
  });

  final Invoice invoice;
  final String patientName;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
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
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.patient.patientId,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice #${invoice.id.substring(0, invoice.id.length > 8 ? 8 : invoice.id.length)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    invoice.total.toFinancial(isMoney: true),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y').format(invoice.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
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
                        color: _statusColor(invoice.status, colorScheme),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme scheme) =>
      FinanceStatusColors.invoiceStatus(status, scheme);
}
