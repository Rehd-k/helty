import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
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
      final response = await _labApi.getOrders(
        patientId: patientId,
        take: 100,
      );
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
          const SnackBar(content: Text('No printable lab results for this patient.')),
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

    final columns = [
      'Test',
      if (showVisitCol) 'Visit',
      'Priority',
      'Status',
      'Result Summary',
      'Print',
      if (isDoctor) 'Doctor actions',
    ];

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: SectionCard(
          title: 'Lab Results',
          subtitle: 'Read-only view of investigations',
          actions: [
            FilledButton.tonalIcon(
              onPressed: _loading || _printing ? null : _printAllPatientResults,
              icon: _printing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print results'),
            ),
          ],
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
                                icon: Icon(Icons.event_note_outlined, size: 16),
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
                const SizedBox(height: 12),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _encounterOnly
                        ? 'No lab results for this encounter yet.'
                        : 'No lab results for this patient yet.',
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: columns
                        .map(
                          (c) => DataColumn(
                            label: Text(
                              c,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                        .toList(),
                    rows: _orders
                        .map(
                          (o) => _row(
                            context,
                            o,
                            isDoctor,
                            showVisitCol: showVisitCol,
                            admissionEncounterId: scope?.encounterId,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    LabOrderModel order,
    bool isDoctor, {
    required bool showVisitCol,
    String? admissionEncounterId,
  }) {
    final lines = order.resultLines;
    final hasResults = (lines != null && lines.isNotEmpty) ||
        (order.resultValues != null && order.resultValues!.isNotEmpty);
    final canPrint = (order.printableLabOrderId?.isNotEmpty ?? false) &&
        hasResults;
    final printingThis = _printingOrderId == order.id;

    final onThisAdmission = admissionEncounterId != null &&
        admissionEncounterId.isNotEmpty &&
        order.encounterId == admissionEncounterId;

    return DataRow(
      onSelectChanged: hasResults
          ? (_) => showLabOrderResultsDialog(context, order: order)
          : null,
      cells: [
        DataCell(Text(order.testType)),
        if (showVisitCol)
          DataCell(
            Text(
              onThisAdmission ? 'This admission' : 'Other',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onThisAdmission
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            ),
          ),
        DataCell(Text(order.priority ?? '-')),
        DataCell(Text(order.status)),
        DataCell(_ResultSummaryCell(order: order)),
        DataCell(
          IconButton(
            tooltip: canPrint ? 'Print result' : 'No printable result',
            onPressed: canPrint && !printingThis && !_printing
                ? () => _printOrder(order)
                : null,
            icon: printingThis
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined, size: 20),
          ),
        ),
        if (isDoctor)
          DataCell(
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
              child: const Text('Order lab tests'),
            ),
          ),
      ],
    );
  }
}

class _ResultSummaryCell extends StatelessWidget {
  const _ResultSummaryCell({required this.order});

  final LabOrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = order.resultLines;

    if (lines != null && lines.isNotEmpty) {
      final preview = lines.take(3).toList();
      return Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < preview.length; i++) ...[
              if (i > 0) const TextSpan(text: ' • '),
              TextSpan(
                text: '${preview[i].label}: ${preview[i].valueWithUnit}',
                style: labResultIsAbnormal(
                  resolveLabReferenceEvaluation(
                    value: preview[i].value,
                    referenceRange: preview[i].referenceRange,
                    serverEvaluation: preview[i].referenceEvaluation,
                  ),
                )
                    ? TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      )
                    : null,
              ),
            ],
          ],
        ),
      );
    }

    final legacy = order.resultValues;
    if (legacy != null && legacy.isNotEmpty) {
      final entries = legacy.entries.take(3).toList();
      return Text(
        entries.map((e) => '${e.key}: ${e.value}').join(' • '),
      );
    }

    return const Text('-');
  }
}
