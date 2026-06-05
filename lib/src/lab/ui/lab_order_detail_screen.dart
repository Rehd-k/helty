import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:helty/src/lab/ui/lab_record_sample_sheet.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

@RoutePage()
class LabOrderDetailScreen extends ConsumerStatefulWidget {
  const LabOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<LabOrderDetailScreen> createState() =>
      _LabOrderDetailScreenState();
}

class _LabOrderDetailScreenState extends ConsumerState<LabOrderDetailScreen> {
  LabOrder? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(labApiServiceProvider)
          .getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Order not found',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final hasAnyResults = order.items.any((i) => i.results.isNotEmpty);
    final isHeadOfLab =
        (staff?.staffRole.toLowerCase() == 'admin') ||
        (staff?.accountType?.name.toLowerCase() == 'laboratory' ||
            staff?.accountType?.name.toLowerCase() == 'lab');

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          if (hasAnyResults)
            IconButton(
              tooltip: 'Print',
              icon: const Icon(Icons.print_rounded),
              onPressed: () => _printOrder(order),
            ),
          if (hasAnyResults)
            IconButton(
              tooltip: 'Share as PDF',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _shareOrder(order),
            ),
          PopupMenuButton<LabOrderStatus>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (status) async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              try {
                await ref
                    .read(labApiServiceProvider)
                    .updateOrderStatus(order.id, status);
                if (!mounted) return;
                _load();
              } catch (e) {
                if (mounted && messenger != null) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            itemBuilder: (context) => LabOrderStatus.values
                .map(
                  (s) => PopupMenuItem(value: s, child: Text(_statusLabel(s))),
                )
                .toList(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderInfoCard(order: order),
              const SizedBox(height: 24),
              Text(
                'Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...order.items.map(
                (item) => _OrderItemCard(
                  item: item,
                  orderStatus: order.status,
                  onCollectSample: () => _showRecordSample(context, item),
                  onEnterResults: () => _openResultEntry(context, item),
                  isHeadOfLab: isHeadOfLab,
                ),
              ),
              if (isHeadOfLab &&
                  hasAnyResults &&
                  order.status != LabOrderStatus.verified) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _verifyOrder(context, order),
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Mark results as verified'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordSample(BuildContext context, LabOrderItem item) {
    final staff = ref.read(currentStaffProvider);
    if (staff == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not logged in as staff')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LabRecordSampleSheet(
        orderItem: item,
        staffId: staff.id,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  void _openResultEntry(BuildContext context, LabOrderItem item) {
    context.router
        .push(LabResultEntryRoute(orderId: _order!.id, orderItemId: item.id))
        .then((_) => _load());
  }

  Future<void> _verifyOrder(BuildContext context, LabOrder order) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(labApiServiceProvider)
          .updateOrderStatus(order.id, LabOrderStatus.verified);
      if (!mounted) return;
      _load();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Order marked as verified')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _printOrder(LabOrder order) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final bytes = await buildLabOrderPdf(order, format);
        return Uint8List.fromList(bytes);
      },
    );
  }

  Future<void> _shareOrder(LabOrder order) async {
    final bytes = await buildLabOrderPdf(order, PdfPageFormat.a4);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'lab_order_${order.id}.pdf',
    );
  }

  static String _statusLabel(LabOrderStatus s) {
    switch (s) {
      case LabOrderStatus.pending:
        return 'Pending';
      case LabOrderStatus.sampleCollected:
        return 'Sample collected';
      case LabOrderStatus.processing:
        return 'Processing';
      case LabOrderStatus.completed:
        return 'Completed';
      case LabOrderStatus.verified:
        return 'Verified';
    }
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final LabOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status.apiValue.replaceAll('_', ' '),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Patient',
              value: order.patient?.displayName ?? '—',
            ),
            _InfoRow(label: 'Doctor', value: order.doctor?.displayName ?? '—'),
            if (order.createdAt != null)
              _InfoRow(
                label: 'Created',
                value: order.createdAt!.toIso8601String().split('T').first,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
    required this.orderStatus,
    required this.onCollectSample,
    required this.onEnterResults,
    required this.isHeadOfLab,
  });

  final LabOrderItem item;
  final LabOrderStatus orderStatus;
  final VoidCallback onCollectSample;
  final VoidCallback onEnterResults;
  final bool isHeadOfLab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final testName = item.testVersion?.test?.name ?? 'Test';
    final sampleType = item.testVersion?.test?.sampleType ?? '';
    final hasSample = item.sample != null;
    final reportResults = item.results
        .where((r) => !r.hiddenFromReport)
        .toList();
    final hasStoredResults = item.results.isNotEmpty;
    final hasVisibleReportLines = reportResults.isNotEmpty;
    final fields = item.fields ?? item.testVersion?.fields ?? [];
    final fieldMap = {for (final f in fields) f.id: f};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sampleType.isNotEmpty)
                        Text(
                          sampleType,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSample)
                  Chip(
                    label: const Text('Sample'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                if (hasStoredResults)
                  Chip(
                    label: const Text('Results'),
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasVisibleReportLines)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...reportResults.map((r) {
                      final field = r.field ?? fieldMap[r.fieldId];
                      final label = field?.label ?? r.fieldId;
                      final unit = field?.unit;
                      final ref = field?.referenceRange;
                      final eval = r.referenceEvaluation;
                      final abnormal = labResultIsAbnormal(eval);
                      final flagLabel = labReferenceFlagShortLabel(eval);
                      final valueColor = labReferenceValueColor(theme, eval);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.value,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: valueColor,
                                      fontWeight: abnormal
                                          ? FontWeight.w700
                                          : null,
                                    ),
                                  ),
                                  if (flagLabel != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      labReferenceFlagLabel(eval)!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                unit ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                ref ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              )
            else if (hasStoredResults)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Results on file; all parameters hidden from this report.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!hasSample)
                  FilledButton.tonal(
                    onPressed: onCollectSample,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Record sample'),
                  ),
                OutlinedButton(
                  onPressed: onEnterResults,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    hasStoredResults ? 'Edit results' : 'Enter results',
                  ),
                ),
                if (hasVisibleReportLines && isHeadOfLab)
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Review'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
