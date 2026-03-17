import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/imaging_order_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/imaging_order_service.dart';

@RoutePage()
class InpatientImagingResultsScreen extends StatefulWidget {
  const InpatientImagingResultsScreen({super.key});

  @override
  State<InpatientImagingResultsScreen> createState() =>
      _InpatientImagingResultsScreenState();
}

class _InpatientImagingResultsScreenState
    extends State<InpatientImagingResultsScreen> {
  final _imagingOrderService = ImagingOrderService();

  List<ImagingOrderModel> _orders = [];
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
      final list = await _imagingOrderService.getByEncounter(encounterId);
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
    ImagingOrderModel order,
    bool isDoctor,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(order.studyName)),
        DataCell(Text(order.area ?? '-')),
        DataCell(Text(order.urgency ?? '-')),
        DataCell(Text(order.status)),
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

