import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_order_results_dialog.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/widgets/helty_surface.dart';

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

    final completed = _orders
        .where((o) => o.status == RadiologyOrderStatus.COMPLETED)
        .length;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InpatientTabToolbar(
              icon: Icons.photo_camera_outlined,
              iconColor: InpatientMetrics.iconIndigo,
              title: 'Imaging',
              subtitle: 'Radiology studies for this patient',
            ),
            const SizedBox(height: 10),
            InpatientKpiRow(
              tiles: [
                InpatientKpiTile(
                  icon: Icons.photo_camera_outlined,
                  color: InpatientMetrics.iconIndigo,
                  label: 'Studies',
                  value: _loading ? '—' : '${_orders.length}',
                  caption: _encounterOnly ? 'This encounter' : 'This patient',
                ),
                InpatientKpiTile(
                  icon: Icons.check_circle_outline,
                  color: InpatientMetrics.waitGreen,
                  label: 'Completed',
                  value: _loading ? '—' : '$completed',
                  caption: 'Reported / done',
                ),
                InpatientKpiTile(
                  icon: Icons.hourglass_empty,
                  color: InpatientMetrics.waitAmber,
                  label: 'Open',
                  value: _loading ? '—' : '${_orders.length - completed}',
                  caption: 'Pending or active',
                ),
              ],
            ),
            const SizedBox(height: 10),
            SectionCard(
              title: 'Imaging studies',
              subtitle: 'Read-only view of radiology orders',
              icon: Icons.image_outlined,
              iconColor: InpatientMetrics.iconIndigo,
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
                        const InpatientChartColumn('STUDY', flex: 3),
                        if (showVisitCol)
                          const InpatientChartColumn('VISIT', flex: 2),
                        const InpatientChartColumn('AREA', flex: 2),
                        const InpatientChartColumn('URGENCY'),
                        const InpatientChartColumn('STATUS'),
                        const InpatientChartColumn(
                          'ACTIONS',
                          flex: 2,
                          alignEnd: true,
                        ),
                      ],
                      rowCount: _orders.length,
                      emptyMessage: _encounterOnly
                          ? 'No imaging studies for this encounter yet.'
                          : 'No imaging studies for this patient yet.',
                      minWidth: 860,
                      footerLabel: _orders.length == 1
                          ? '1 study'
                          : '${_orders.length} studies',
                      cellBuilder: (context, index) => _imagingCells(
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

  Color _imagingStatusColor(RadiologyOrderStatus status) {
    return switch (status) {
      RadiologyOrderStatus.COMPLETED => InpatientMetrics.waitGreen,
      RadiologyOrderStatus.CANCELLED => InpatientMetrics.waitRed,
      RadiologyOrderStatus.ACTIVE => InpatientMetrics.iconBlue,
      RadiologyOrderStatus.PENDING => InpatientMetrics.waitAmber,
    };
  }

  List<Widget> _imagingCells(
    BuildContext context,
    RadiologyOrder order,
    bool isDoctor, {
    required bool showVisitCol,
    String? admissionEncounterId,
  }) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final onThisAdmission =
        admissionEncounterId != null &&
        admissionEncounterId.isNotEmpty &&
        order.encounterId == admissionEncounterId;

    return [
      HeltyEllipsisText(text: firstItem?.scanType.displayLabel ?? '—'),
      if (showVisitCol)
        HeltyStatusChip(
          label: onThisAdmission ? 'This admission' : 'Other',
          color: onThisAdmission
              ? InpatientMetrics.iconTeal
              : InpatientMetrics.iconIndigo,
        ),
      HeltyEllipsisText(text: firstItem?.bodyPart ?? '—'),
      HeltyEllipsisText(text: firstItem?.priority.name ?? '—'),
      HeltyStatusChip(
        label: order.status.name,
        color: _imagingStatusColor(order.status),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () => showRadiologyOrderResultsDialog(
                context,
                service: _imagingOrderService,
                order: order,
              ),
              style: inpatientCompactOutline(),
              child: const Text('View'),
            ),
            if (isDoctor) ...[
              const SizedBox(width: 6),
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
                child: const Text('Order'),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}
