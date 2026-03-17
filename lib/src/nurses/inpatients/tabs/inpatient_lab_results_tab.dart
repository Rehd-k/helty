import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
      final list = await _labOrderService.getByEncounter(encounterId);
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
      'Test',
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
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _orders.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No lab results for this admission yet.'),
              )
            : SingleChildScrollView(
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
                  rows: _orders.map((o) => _row(context, o, isDoctor)).toList(),
                ),
              ),
      ),
    );
  }

  DataRow _row(BuildContext context, LabOrderModel order, bool isDoctor) {
    final resultSummary =
        order.resultValues != null && order.resultValues!.isNotEmpty
        ? order.resultValues!.entries
              .take(3)
              .map((e) => '${e.key}: ${e.value}')
              .join(' • ')
        : '-';

    return DataRow(
      cells: [
        DataCell(Text(order.testType)),
        DataCell(Text(order.priority ?? '-')),
        DataCell(Text(order.status)),
        DataCell(Text(resultSummary)),
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
