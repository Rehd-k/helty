import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

@RoutePage()
class InpatientImagingResultsScreen extends StatefulWidget {
  const InpatientImagingResultsScreen({super.key});

  @override
  State<InpatientImagingResultsScreen> createState() =>
      _InpatientImagingResultsScreenState();
}

class _InpatientImagingResultsScreenState
    extends State<InpatientImagingResultsScreen> {
  final _imagingOrderService = RadiologyService();

  List<RadiologyOrder> _orders = [];
  bool _loading = true;

  /// `false` = all imaging for patient (default). `true` = this encounter only.
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
      final list = await _imagingOrderService.listOrders(
        patientId: encounterScoped ? null : patientId,
        encounterId: encounterScoped ? encounterId : null,
        take: 100,
      );
      if (!mounted) return;
      setState(() {
        _orders = list.orders;
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
      'Study',
      if (showVisitCol) 'Visit',
      'Area',
      'Urgency',
      'Status',
      if (isDoctor) 'Doctor actions',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Imaging & Radiology',
        subtitle: 'Read-only view of imaging studies',
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
                      ? 'No imaging studies for this encounter yet.'
                      : 'No imaging studies for this patient yet.',
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
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
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
    RadiologyOrder order,
    bool isDoctor, {
    required bool showVisitCol,
    String? admissionEncounterId,
  }) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final onThisAdmission = admissionEncounterId != null &&
        admissionEncounterId.isNotEmpty &&
        order.encounterId == admissionEncounterId;
    return DataRow(
      cells: [
        DataCell(Text(firstItem?.scanType.displayLabel ?? '-')),
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
        DataCell(Text(firstItem?.bodyPart ?? '-')),
        DataCell(Text(firstItem?.priority.name ?? '-')),
        DataCell(Text(order.status.name)),
        if (isDoctor)
          DataCell(
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'To order imaging, use the doctor encounter imaging tab.',
                    ),
                  ),
                );
              },
              child: const Text('Order imaging'),
            ),
          ),
      ],
    );
  }
}

