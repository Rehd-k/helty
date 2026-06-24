import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/lab_order_service.dart';

@RoutePage()
class InpatientLabResultsScreen extends StatefulWidget {
  const InpatientLabResultsScreen({super.key});

  @override
  State<InpatientLabResultsScreen> createState() =>
      _InpatientLabResultsScreenState();
}

class _InpatientLabResultsScreenState extends State<InpatientLabResultsScreen> {
  final _labOrderService = LabOrderService();

  List<LabOrderModel> _orders = [];
  bool _loading = true;

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
      if (isDoctor) 'Doctor actions',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Lab Results',
        subtitle: 'Read-only view of investigations',
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
