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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final scope = InpatientViewScope.of(context);
    final encounterId = scope?.encounterId;
    if (encounterId == null || encounterId.isEmpty) {
      setState(() {
        _orders = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _imagingOrderService.listOrders(encounterId: encounterId);
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

    final columns = [
      'Study',
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
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _orders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No imaging studies for this admission yet.'),
                  )
                : SingleChildScrollView(
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
                          .map((o) => _row(context, o, isDoctor))
                          .toList(),
                    ),
                  ),
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    RadiologyOrder order,
    bool isDoctor,
  ) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    return DataRow(
      cells: [
        DataCell(Text(firstItem?.scanType.name ?? '-')),
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

