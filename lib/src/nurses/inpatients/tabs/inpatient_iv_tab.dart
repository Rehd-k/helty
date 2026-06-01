import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/iv_fluid_order_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/iv_fluid_order_service.dart';

@RoutePage()
class InpatientIVScreen extends StatefulWidget {
  const InpatientIVScreen({super.key});

  @override
  State<InpatientIVScreen> createState() => _InpatientIVScreenState();
}

class _InpatientIVScreenState extends State<InpatientIVScreen> {
  final _service = IvFluidOrderService();
  List<IvFluidOrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _orders = [];
          _loading = false;
          _error = null;
          _lastAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastAdmissionId) {
      _lastAdmissionId = id;
      _load(id);
    }
  }

  Future<void> _load(String admissionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list(admissionId);
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  String? _timeRemaining(IvFluidOrderModel o) {
    final end = o.expectedEndTime;
    if (end == null) return null;
    final d = end.difference(DateTime.now());
    if (d.isNegative) return 'Ended';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  Future<void> _openUpdateDialog(BuildContext context) async {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission context missing.')),
      );
      return;
    }

    if (_orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No IV orders for this admission.')),
      );
      return;
    }

    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    var selectedId = _orders.first.id;
    final rateCtrl = TextEditingController(text: _orders.first.rate ?? '');
    String siteCondition = 'Good';
    var swelling = false;
    var stopIV = false;
    final remarksCtrl = TextEditingController();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Update IV'),
            content: SizedBox(
              width: inpatientDialogBodyWidth(ctx, preferred: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedId),
                      initialValue: selectedId,
                      decoration: const InputDecoration(
                        labelText: 'IV order',
                      ),
                      items: _orders
                          .map(
                            (o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(
                                o.fluidType?.isNotEmpty == true
                                    ? o.fluidType!
                                    : o.id,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        final o = _orders.firstWhere((e) => e.id == id);
                        setLocal(() {
                          selectedId = id;
                          rateCtrl.text = o.rate ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Current rate',
                        hintText: 'As documented on chart',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(siteCondition),
                      initialValue: siteCondition,
                      decoration: const InputDecoration(
                        labelText: 'Insertion site condition',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(
                          value: 'Redness',
                          child: Text('Redness'),
                        ),
                        DropdownMenuItem(value: 'Pain', child: Text('Pain')),
                        DropdownMenuItem(
                          value: 'Infiltration',
                          child: Text('Infiltration'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => siteCondition = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: swelling,
                      title: const Text('Swelling noted'),
                      onChanged: (v) => setLocal(() => swelling = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: stopIV,
                      title: const Text('Stop IV'),
                      onChanged: (v) => setLocal(() => stopIV = v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: remarksCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / reason if stopped',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final order =
                            _orders.firstWhere((o) => o.id == selectedId);
                        final rate = rateCtrl.text.trim();
                        if (rate.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter current rate.'),
                            ),
                          );
                          return;
                        }
                        setLocal(() => saving = true);
                        try {
                          var complications = <String>[];
                          if (swelling) complications.add('swelling');
                          await _service.createMonitoring(
                            admissionId: admissionId,
                            orderId: order.id,
                            currentRate: rate,
                            insertionSiteCondition: siteCondition,
                            complications: complications.isEmpty
                                ? null
                                : complications.join(', '),
                            stoppedAt: stopIV ? DateTime.now() : null,
                            reasonStopped: stopIV ? remarksCtrl.text : null,
                            nurseId: nurseId,
                          );
                          if (stopIV) {
                            await _service.patchOrder(
                              admissionId: admissionId,
                              orderId: order.id,
                              status: 'STOPPED',
                              rate: rate,
                            );
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IV update saved.'),
                              ),
                            );
                            await _load(admissionId);
                          }
                        } on DioException catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(_dioMessage(e))),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        } finally {
                          if (ctx.mounted) setLocal(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    rateCtrl.dispose();
    remarksCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission to manage IV lines.'),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Active IV Lines',
        subtitle: 'Fluids running for this inpatient stay',
        actions: [
          OutlinedButton.icon(
            onPressed: () => _openUpdateDialog(context),
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Update IV'),
          ),
        ],
        child: _orders.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No IV fluid orders for this admission.'),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    'Fluid',
                    'Volume',
                    'Rate',
                    'Start Time',
                    'Time Remaining',
                    'Site',
                    'Status',
                    'Ordered by',
                  ]
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
                        (o) => DataRow(
                          cells: [
                            DataCell(Text(o.fluidType ?? '—')),
                            DataCell(Text(o.volume ?? '—')),
                            DataCell(Text(o.rate ?? '—')),
                            DataCell(Text(
                              o.startTime != null
                                  ? DateFormatter.dateTime(o.startTime!)
                                  : '—',
                            )),
                            DataCell(Text(_timeRemaining(o) ?? '—')),
                            const DataCell(Text('—')),
                            DataCell(Text(o.status ?? '—')),
                            DataCell(Text(o.recorderDisplayName ?? '—')),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }
}
