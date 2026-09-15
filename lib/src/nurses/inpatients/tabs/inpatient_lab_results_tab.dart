import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:helty/src/services/lab_order_service.dart';
import 'package:printing/printing.dart';

@RoutePage()
class InpatientLabResultsScreen extends StatefulWidget {
  const InpatientLabResultsScreen({super.key});

  @override
  State<InpatientLabResultsScreen> createState() =>
      _InpatientLabResultsScreenState();
}

class _InpatientLabResultsScreenState extends State<InpatientLabResultsScreen> {
  final _labOrderService = LabOrderService();
  final _labApi = LabApiService();

  List<LabOrderModel> _orders = [];
  bool _loading = true;
  bool _printing = false;
  String? _printingOrderId;

  /// `false` = all labs for patient (default). `true` = this encounter only.
  bool _encounterOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final scope = InpatientViewScope.of(context);
    final patientId = scope?.patientId;
    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _orders = const [];
        _loading = false;
      });
      return;
    }
    final encounterId = scope?.encounterId;
    final encounterScoped =
        _encounterOnly && encounterId != null && encounterId.isNotEmpty;
    if (_encounterOnly && !encounterScoped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _encounterOnly = false);
      });
    }
    setState(() => _loading = true);
    try {
      final list = await _labOrderService.listForScope(
        patientId: patientId,
        encounterId: encounterId,
        encounterOnly: encounterScoped,
      );
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orders = const [];
        _loading = false;
      });
    }
  }

  Future<void> _printOrder(LabOrderModel row) async {
    final orderId = row.printableLabOrderId?.trim();
    if (orderId == null || orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No printable lab order linked to this request.'),
        ),
      );
      return;
    }
    setState(() => _printingOrderId = row.id);
    try {
      final order = await _labApi.getOrderById(orderId);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async {
          final bytes = await buildLabOrderPdf(order, format);
          return Uint8List.fromList(bytes);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) setState(() => _printingOrderId = null);
    }
  }

  Future<void> _printAllPatientResults() async {
    final scope = InpatientViewScope.of(context);
    final patientId = scope?.patientId.trim();
    if (patientId == null || patientId.isEmpty) return;

    setState(() => _printing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await _labApi.getOrders(patientId: patientId, take: 100);
      final entries = <({LabOrder order, LabOrderItem item})>[];
      LabOrderPatient? patient;
      for (final order in response.data) {
        patient ??= order.patient;
        for (final item in order.items) {
          if (labOrderItemHasPrintableResults(item)) {
            entries.add((order: order, item: item));
          }
        }
      }
      if (entries.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No printable lab results for this patient.'),
          ),
        );
        return;
      }
      patient ??= LabOrderPatient(id: patientId);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async {
          final bytes = await buildLabPatientItemsPdf(
            patient: patient!,
            entries: entries,
            format: format,
          );
          return Uint8List.fromList(bytes);
        },
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final isDoctor = scope?.isDoctor ?? false;
    final hasEncounter =
        scope?.encounterId != null && scope!.encounterId!.isNotEmpty;
    final showVisitCol = !_encounterOnly && hasEncounter;

    final resulted = _orders.where((o) {
      final lines = o.resultLines;
      return (lines != null && lines.isNotEmpty) ||
          (o.resultValues != null && o.resultValues!.isNotEmpty);
    }).length;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InpatientTabToolbar(
              icon: Icons.biotech_outlined,
              iconColor: InpatientMetrics.iconTeal,
              title: 'Lab Results',
              subtitle: 'Investigations for this patient',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: _loading || _printing
                      ? null
                      : _printAllPatientResults,
                  icon: _printing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Print results'),
                  style: inpatientCompactFill(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InpatientKpiRow(
              tiles: [
                InpatientKpiTile(
                  icon: Icons.biotech_outlined,
                  color: InpatientMetrics.iconTeal,
                  label: 'Orders',
                  value: _loading ? '—' : '${_orders.length}',
                  caption: _encounterOnly ? 'This encounter' : 'This patient',
                ),
                InpatientKpiTile(
                  icon: Icons.check_circle_outline,
                  color: InpatientMetrics.waitGreen,
                  label: 'Resulted',
                  value: _loading ? '—' : '$resulted',
                  caption: 'With values',
                ),
                InpatientKpiTile(
                  icon: Icons.hourglass_empty,
                  color: InpatientMetrics.waitAmber,
                  label: 'Pending',
                  value: _loading ? '—' : '${_orders.length - resulted}',
                  caption: 'Awaiting results',
                ),
              ],
            ),
            const SizedBox(height: 10),
            SectionCard(
              title: 'Lab orders',
              subtitle: 'Read-only view of investigations',
              icon: Icons.science_outlined,
              iconColor: InpatientMetrics.iconTeal,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasEncounter) ...[
                    LayoutBuilder(
                      builder: (context, c) {
                        final narrow = c.maxWidth < 520;
                        return SegmentedButton<bool>(
                          segments: narrow
                              ? const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('All'),
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('Visit'),
                                  ),
                                ]
                              : const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('All patient'),
                                    icon: Icon(Icons.person_outline, size: 16),
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('This encounter'),
                                    icon: Icon(
                                      Icons.event_note_outlined,
                                      size: 16,
                                    ),
                                  ),
                                ],
                          selected: {_encounterOnly},
                          onSelectionChanged: (s) {
                            if (s.isEmpty) return;
                            setState(() => _encounterOnly = s.first);
                            _load();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    InpatientChartTable(
                      columns: [
                        const InpatientChartColumn('TEST', flex: 3),
                        if (showVisitCol)
                          const InpatientChartColumn('VISIT', flex: 2),
                        const InpatientChartColumn('PRIORITY'),
                        const InpatientChartColumn('STATUS'),
                        const InpatientChartColumn('RESULT', flex: 3),
                        const InpatientChartColumn(
                          'ACTIONS',
                          flex: 3,
                          alignEnd: true,
                        ),
                      ],
                      rowCount: _orders.length,
                      emptyMessage: _encounterOnly
                          ? 'No lab results for this encounter yet.'
                          : 'No lab results for this patient yet.',
                      minWidth: 920,
                      footerLabel: _orders.length == 1
                          ? '1 order'
                          : '${_orders.length} orders',
                      cellBuilder: (context, index) => _labCells(
                        context,
                        _orders[index],
                        isDoctor,
                        showVisitCol: showVisitCol,
                        admissionEncounterId: scope?.encounterId,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _labStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('RESULT') || s.contains('COMPLETE') || s.contains('FINAL')) {
      return InpatientMetrics.waitGreen;
    }
    if (s.contains('CANCEL')) return InpatientMetrics.waitRed;
    if (s.contains('PEND') || s.contains('ORDER') || s.contains('COLLECT')) {
      return InpatientMetrics.waitAmber;
    }
    return InpatientMetrics.iconIndigo;
  }

  String _labResultPreview(LabOrderModel order) {
    final lines = order.resultLines;
    if (lines != null && lines.isNotEmpty) {
      return lines
          .take(3)
          .map((l) => '${l.label}: ${l.valueWithUnit}')
          .join(' · ');
    }
    final legacy = order.resultValues;
    if (legacy != null && legacy.isNotEmpty) {
      return legacy.entries
          .take(3)
          .map((e) => '${e.key}: ${e.value}')
          .join(' · ');
    }
    return '—';
  }

  List<Widget> _labCells(
    BuildContext context,
    LabOrderModel order,
    bool isDoctor, {
    required bool showVisitCol,
    String? admissionEncounterId,
  }) {
    final lines = order.resultLines;
    final hasResults =
        (lines != null && lines.isNotEmpty) ||
        (order.resultValues != null && order.resultValues!.isNotEmpty);
    final canPrint =
        (order.printableLabOrderId?.isNotEmpty ?? false) && hasResults;
    final printingThis = _printingOrderId == order.id;
    final onThisAdmission =
        admissionEncounterId != null &&
        admissionEncounterId.isNotEmpty &&
        order.encounterId == admissionEncounterId;

    final actions = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasResults)
            OutlinedButton(
              onPressed: () => showLabOrderResultsDialog(context, order: order),
              style: inpatientCompactOutline(),
              child: const Text('View'),
            ),
          if (canPrint) ...[
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: printingThis || _printing
                  ? null
                  : () => _printOrder(order),
              style: inpatientCompactOutline(),
              child: printingThis
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Print'),
            ),
          ],
          if (isDoctor) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'To order new labs, use the doctor encounter investigations tab.',
                    ),
                  ),
                );
              },
              child: const Text('Order'),
            ),
          ],
        ],
      ),
    );

    return [
      HeltyEllipsisText(text: order.testType),
      if (showVisitCol)
        HeltyStatusChip(
          label: onThisAdmission ? 'This admission' : 'Other',
          color: onThisAdmission
              ? InpatientMetrics.iconTeal
              : InpatientMetrics.iconIndigo,
        ),
      HeltyEllipsisText(text: order.priority ?? '—'),
      HeltyStatusChip(
        label: order.status.trim().isEmpty ? '—' : order.status,
        color: _labStatusColor(order.status),
      ),
      HeltyEllipsisText(text: _labResultPreview(order)),
      actions,
    ];
  }
}
