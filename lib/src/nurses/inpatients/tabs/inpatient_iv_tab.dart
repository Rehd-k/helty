import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/iv_fluid_order_model.dart';
import 'package:helty/src/models/iv_monitoring_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/iv_fluid_order_service.dart';

const _fluidPresets = <String>[
  'Normal Saline 0.9%',
  'Dextrose 5% (D5W)',
  'Dextrose 5% in Normal Saline (D5NS)',
  "Ringer's Lactate",
  '0.45% NaCl (Half Normal Saline)',
  'Other',
];

@RoutePage()
class InpatientIVScreen extends StatefulWidget {
  const InpatientIVScreen({super.key});

  @override
  State<InpatientIVScreen> createState() => _InpatientIVScreenState();
}

class _InpatientIVScreenState extends State<InpatientIVScreen> {
  final _service = IvFluidOrderService();
  List<IvFluidOrderModel> _orders = [];
  List<IvMonitoringModel> _monitorings = [];
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
          _monitorings = [];
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
      final histories = list.isEmpty
          ? <List<IvMonitoringModel>>[]
          : await Future.wait(
              list.map(
                (o) => _service.listMonitorings(
                  admissionId: admissionId,
                  orderId: o.id,
                ),
              ),
            );
      final monitorings = histories.expand((rows) => rows).toList()
        ..sort(
          (a, b) => (b.recordedAt ?? DateTime(0)).compareTo(
            a.recordedAt ?? DateTime(0),
          ),
        );
      if (!mounted) return;
      setState(() {
        _orders = list;
        _monitorings = monitorings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _monitorings = [];
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

  DateTime _calcExpectedEndTime(DateTime start, int volume, int rate) {
    if (rate <= 0) return start;
    final minutes = (volume / rate * 60).round();
    return start.add(Duration(minutes: minutes));
  }

  Future<DateTime?> _pickDateTime(
    BuildContext ctx,
    DateTime initial, {
    required void Function(DateTime picked) onPicked,
  }) async {
    final d = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: AppTimezone.startOfDay(
        AppTimezone.now().subtract(const Duration(days: 30)),
      ),
      lastDate: AppTimezone.endOfDay(
        AppTimezone.now().add(const Duration(days: 365)),
      ),
    );
    if (d == null || !ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !ctx.mounted) return null;
    final picked = AppTimezone.combineDateAndTime(d, time);
    onPicked(picked);
    return picked;
  }

  Widget _dateTimeTile({
    required BuildContext ctx,
    required String title,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(DateFormatter.dateTime(value)),
      trailing: IconButton(icon: const Icon(Icons.schedule), onPressed: onTap),
    );
  }

  Future<void> _openCreateOrderDialog(BuildContext context) async {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission context missing.')),
      );
      return;
    }
    if (scope?.isAdmissionActive != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This admission is not active; IV orders cannot be placed.',
          ),
        ),
      );
      return;
    }

    var fluidPreset = _fluidPresets.first;
    final customFluidCtrl = TextEditingController();
    final volumeCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    DateTime startTime = AppTimezone.now();
    DateTime expectedEndTime = AppTimezone.now();
    var endTimeManual = false;
    var saving = false;

    void recalcEnd(void Function(void Function()) setLocal) {
      if (endTimeManual) return;
      final volume = int.tryParse(volumeCtrl.text.trim());
      final rate = int.tryParse(rateCtrl.text.trim());
      if (volume == null || rate == null || rate <= 0) return;
      setLocal(() {
        expectedEndTime = _calcExpectedEndTime(startTime, volume, rate);
      });
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Add IV order'),
            content: SizedBox(
              width: inpatientDialogBodyWidth(ctx, preferred: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(fluidPreset),
                      initialValue: fluidPreset,
                      decoration: const InputDecoration(
                        labelText: 'Fluid type',
                      ),
                      items: _fluidPresets
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setLocal(() => fluidPreset = v);
                      },
                    ),
                    if (fluidPreset == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: customFluidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Custom fluid type',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: volumeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Volume (mL)',
                      ),
                      onChanged: (_) => recalcEnd(setLocal),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rate (mL/hr)',
                      ),
                      onChanged: (_) => recalcEnd(setLocal),
                    ),
                    const SizedBox(height: 12),
                    _dateTimeTile(
                      ctx: ctx,
                      title: 'Start time',
                      value: startTime,
                      onTap: () async {
                        await _pickDateTime(
                          ctx,
                          startTime,
                          onPicked: (picked) {
                            setLocal(() {
                              startTime = picked;
                              endTimeManual = false;
                            });
                            recalcEnd(setLocal);
                          },
                        );
                      },
                    ),
                    _dateTimeTile(
                      ctx: ctx,
                      title: 'Expected end time',
                      value: expectedEndTime,
                      onTap: () async {
                        await _pickDateTime(
                          ctx,
                          expectedEndTime,
                          onPicked: (picked) {
                            setLocal(() {
                              expectedEndTime = picked;
                              endTimeManual = true;
                            });
                          },
                        );
                      },
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
                        final fluidType = fluidPreset == 'Other'
                            ? customFluidCtrl.text.trim()
                            : fluidPreset;
                        final volume = int.tryParse(volumeCtrl.text.trim());
                        final rate = int.tryParse(rateCtrl.text.trim());
                        if (fluidType.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a fluid type.'),
                            ),
                          );
                          return;
                        }
                        if (volume == null || volume < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid volume (mL).'),
                            ),
                          );
                          return;
                        }
                        if (rate == null || rate <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid rate (mL/hr).'),
                            ),
                          );
                          return;
                        }
                        if (!expectedEndTime.isAfter(startTime)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Expected end time must be after start time.',
                              ),
                            ),
                          );
                          return;
                        }
                        setLocal(() => saving = true);
                        try {
                          await _service.create(
                            admissionId: admissionId,
                            fluidType: fluidType,
                            volume: volume,
                            rate: rate,
                            startTime: startTime,
                            expectedEndTime: expectedEndTime,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IV order created.'),
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
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text('$e')));
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
                    : const Text('Create order'),
              ),
            ],
          );
        },
      ),
    );

    customFluidCtrl.dispose();
    volumeCtrl.dispose();
    rateCtrl.dispose();
  }

  Future<void> _openManageOrderDialog(BuildContext context) async {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission context missing.')),
      );
      return;
    }
    if (scope?.isAdmissionActive != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This admission is not active; IV orders cannot be managed.',
          ),
        ),
      );
      return;
    }
    if (_orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No IV orders for this admission.')),
      );
      return;
    }

    final defaultOrder = _orders.firstWhere(
      (o) => (o.status ?? 'ACTIVE').toUpperCase() == 'ACTIVE',
      orElse: () => _orders.first,
    );
    var selectedId = defaultOrder.id;
    var status = (defaultOrder.status ?? 'ACTIVE').toUpperCase();
    final rateCtrl = TextEditingController(text: defaultOrder.rate ?? '');
    DateTime expectedEndTime =
        defaultOrder.expectedEndTime ?? AppTimezone.now();
    var saving = false;

    IvFluidOrderModel selectedOrder() =>
        _orders.firstWhere((o) => o.id == selectedId);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Manage IV order'),
            content: SizedBox(
              width: inpatientDialogBodyWidth(ctx, preferred: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedId),
                      initialValue: selectedId,
                      decoration: const InputDecoration(labelText: 'IV order'),
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
                          status = (o.status ?? 'ACTIVE').toUpperCase();
                          rateCtrl.text = o.rate ?? '';
                          expectedEndTime =
                              o.expectedEndTime ?? AppTimezone.now();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(status),
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETED',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'STOPPED',
                          child: Text('Stopped'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setLocal(() => status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prescribed rate (mL/hr)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dateTimeTile(
                      ctx: ctx,
                      title: 'Expected end time',
                      value: expectedEndTime,
                      onTap: () async {
                        await _pickDateTime(
                          ctx,
                          expectedEndTime,
                          onPicked: (picked) {
                            setLocal(() => expectedEndTime = picked);
                          },
                        );
                      },
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
                        final order = selectedOrder();
                        final rate = int.tryParse(rateCtrl.text.trim());
                        if (rate == null || rate < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid rate (mL/hr).'),
                            ),
                          );
                          return;
                        }
                        setLocal(() => saving = true);
                        try {
                          final origStatus = (order.status ?? 'ACTIVE')
                              .toUpperCase();
                          final origRate = int.tryParse(order.rate ?? '');
                          final origEnd = order.expectedEndTime;

                          final newStatus = status != origStatus
                              ? status
                              : null;
                          final newRate = rate != origRate ? rate : null;
                          final newEnd =
                              origEnd == null || expectedEndTime != origEnd
                              ? expectedEndTime
                              : null;

                          if (newStatus == null &&
                              newRate == null &&
                              newEnd == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('No changes to save.'),
                              ),
                            );
                            setLocal(() => saving = false);
                            return;
                          }

                          await _service.patchOrder(
                            admissionId: admissionId,
                            orderId: order.id,
                            status: newStatus,
                            rate: newRate,
                            expectedEndTime: newEnd,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IV order updated.'),
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
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text('$e')));
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
                    : const Text('Save changes'),
              ),
            ],
          );
        },
      ),
    );

    rateCtrl.dispose();
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
                      decoration: const InputDecoration(labelText: 'IV order'),
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
                      keyboardType: TextInputType.number,
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
                        final order = _orders.firstWhere(
                          (o) => o.id == selectedId,
                        );
                        final rate = int.tryParse(rateCtrl.text.trim());
                        if (rate == null || rate < 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter a valid current rate (mL/hr).',
                              ),
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
                              const SnackBar(content: Text('IV update saved.')),
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
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text('$e')));
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

  String _fluidLabelForOrder(String orderId) {
    for (final o in _orders) {
      if (o.id == orderId) {
        return o.fluidType?.isNotEmpty == true ? o.fluidType! : orderId;
      }
    }
    return orderId;
  }

  String _formatStoppedSummary(IvMonitoringModel m) {
    final parts = <String>[];
    if (m.stoppedAt != null) {
      parts.add(DateFormatter.dateTime(m.stoppedAt!));
    }
    if (m.reasonStopped?.trim().isNotEmpty == true) {
      parts.add(m.reasonStopped!.trim());
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  Widget _buildOrdersTable(BuildContext context) {
    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No IV fluid orders for this admission.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns:
            [
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  DataCell(
                    Text(
                      o.startTime != null
                          ? DateFormatter.dateTime(o.startTime!)
                          : '—',
                    ),
                  ),
                  DataCell(Text(_timeRemaining(o) ?? '—')),
                  DataCell(Text(o.latestSiteCondition ?? '—')),
                  DataCell(Text(o.status ?? '—')),
                  DataCell(Text(o.recorderDisplayName ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context) {
    if (_monitorings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No IV monitoring entries for this admission.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns:
            [
                  'Recorded',
                  'IV fluid',
                  'Rate (mL/hr)',
                  'Site condition',
                  'Complications',
                  'Stopped',
                  'Nurse',
                ]
                .map(
                  (c) => DataColumn(
                    label: Text(
                      c,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
        rows: _monitorings
            .map(
              (m) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      m.recordedAt != null
                          ? DateFormatter.dateTime(m.recordedAt!)
                          : '—',
                    ),
                  ),
                  DataCell(Text(_fluidLabelForOrder(m.ivOrderId))),
                  DataCell(Text(m.currentRate?.toString() ?? '—')),
                  DataCell(Text(m.insertionSiteCondition ?? '—')),
                  DataCell(Text(m.complications ?? '—')),
                  DataCell(Text(_formatStoppedSummary(m))),
                  DataCell(Text(m.nurseDisplayName ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Open this patient with an admission to manage IV lines.',
          ),
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

    final isDoctor = scope?.isDoctor ?? false;
    final isNurse = scope?.isNurse ?? false;
    final admissionActive = scope?.isAdmissionActive ?? false;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: InpatientResponsiveRowOrColumn(
        first: SectionCard(
          title: 'IV Fluid Orders',
          subtitle:
              'Prescribed fluids and running lines for this inpatient stay',
          actions: [
            if (isDoctor && admissionActive)
              FilledButton.icon(
                onPressed: () => _openCreateOrderDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add IV order'),
              ),
            if (isDoctor && admissionActive && _orders.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _openManageOrderDialog(context),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Manage IV'),
              ),
            if (isNurse)
              OutlinedButton.icon(
                onPressed: _orders.isEmpty
                    ? null
                    : () => _openUpdateDialog(context),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Update IV'),
              ),
          ],
          child: _buildOrdersTable(context),
        ),
        second: SectionCard(
          title: 'IV Monitoring History',
          subtitle: 'Chronological record of IV line checks and updates',
          child: _buildHistoryTable(context),
        ),
      ),
      ),
    );
  }
}
