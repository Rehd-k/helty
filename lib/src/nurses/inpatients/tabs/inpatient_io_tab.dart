import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/intake_output_record_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_responsive_row_or_column.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/intake_output_service.dart';

@RoutePage()
class InpatientIOScreen extends StatefulWidget {
  const InpatientIOScreen({super.key});

  @override
  State<InpatientIOScreen> createState() => _InpatientIOScreenState();
}

class _InpatientIOScreenState extends State<InpatientIOScreen> {
  final _service = IntakeOutputService();
  List<IntakeOutputRecordModel> _records = [];
  bool _loading = true;
  String? _error;
  String? _lastLoadedAdmissionId;

  static const _intakeCategories = ['ORAL', 'IV', 'OTHER'];
  static const _outputCategories = [
    'URINE',
    'STOOL',
    'DRAIN',
    'VOMIT',
    'BLOOD',
    'OTHER',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastLoadedAdmissionId != null || _loading) {
        setState(() {
          _records = [];
          _loading = false;
          _error = null;
          _lastLoadedAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastLoadedAdmissionId) {
      _lastLoadedAdmissionId = id;
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
        _records = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _records = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isToday(DateTime? t) {
    if (t == null) return false;
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  double _dailyTotalMl(bool intake) {
    final type = intake ? 'INTAKE' : 'OUTPUT';
    var sum = 0.0;
    for (final r in _records) {
      final rt = (r.type ?? '').toUpperCase();
      if (rt != type) continue;
      final t = r.recordedAt ?? r.createdAt;
      if (!_isToday(t)) continue;
      sum += r.amountMl ?? 0;
    }
    return sum;
  }

  List<IntakeOutputRecordModel> _rowsFor(bool intake) {
    final type = intake ? 'INTAKE' : 'OUTPUT';
    return _records.where((r) => (r.type ?? '').toUpperCase() == type).toList()
      ..sort((a, b) {
        final ta = a.recordedAt ?? a.createdAt;
        final tb = b.recordedAt ?? b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  Future<void> _openAddRecordDialog(BuildContext context, bool isIntake) async {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admission context missing.')),
      );
      return;
    }
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final categories = isIntake ? _intakeCategories : _outputCategories;
    String category = categories.first;
    final amountCtrl = TextEditingController();
    final otherCtrl = TextEditingController();
    var recorded = DateTime.now();
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(isIntake ? 'Add Intake' : 'Add Output'),
                content: SizedBox(
                  width: inpatientDialogBodyWidth(ctx, preferred: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(category),
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setLocal(() {
                                category = v;
                                if (v != 'OTHER') otherCtrl.clear();
                              });
                            }
                          },
                        ),
                        if (category == 'OTHER') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: otherCtrl,
                            decoration: InputDecoration(
                              labelText: isIntake
                                  ? 'Specify other intake'
                                  : 'Specify other output',
                              hintText: 'Enter description',
                            ),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount (ml)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Record time'),
                          subtitle: Text(DateFormatter.dateTime(recorded)),
                          trailing: IconButton(
                            icon: const Icon(Icons.schedule),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: recorded,
                                firstDate: AppTimezone.startOfDay(
                                  AppTimezone.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                ),
                                lastDate: AppTimezone.endOfDay(
                                  AppTimezone.now().add(
                                    const Duration(days: 1),
                                  ),
                                ),
                              );
                              if (d == null || !ctx.mounted) return;
                              final time = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.fromDateTime(recorded),
                              );
                              if (time == null || !ctx.mounted) return;
                              setLocal(() {
                                recorded = AppTimezone.combineDateAndTime(
                                  d,
                                  time,
                                );
                              });
                            },
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
                            final ml = double.tryParse(amountCtrl.text.trim());
                            if (ml == null || ml < 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter a valid amount (ml).'),
                                ),
                              );
                              return;
                            }
                            if (category == 'OTHER' &&
                                otherCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please describe the other category.',
                                  ),
                                ),
                              );
                              return;
                            }
                            setLocal(() => saving = true);
                            try {
                              final otherNotes = otherCtrl.text.trim();
                              await _service.create(
                                admissionId: admissionId,
                                nurseId: nurseId,
                                type: isIntake ? 'INTAKE' : 'OUTPUT',
                                category: category,
                                amountMl: ml,
                                recordedAt: recorded,
                                notes: category == 'OTHER' ? otherNotes : null,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Record saved.'),
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
                              if (ctx.mounted) {
                                setLocal(() => saving = false);
                              }
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
          );
        },
      );
    } finally {
      amountCtrl.dispose();
      otherCtrl.dispose();
    }
  }

  String _categoryLabel(IntakeOutputRecordModel record) {
    final category = (record.category ?? '').toUpperCase();
    if (category == 'OTHER') {
      final notes = record.notes?.trim();
      if (notes != null && notes.isNotEmpty) return notes;
    }
    return record.category ?? '—';
  }

  Widget _buildBalanceSummary(
    BuildContext context, {
    required double intakeTotal,
    required double outputTotal,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final balance = intakeTotal - outputTotal;
    final balanceColor = balance >= 0 ? scheme.primary : scheme.error;

    return SectionCard(
      title: "Today's fluid balance",
      subtitle: 'Intake minus output (local date)',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Intake: ${intakeTotal.toStringAsFixed(0)} ml',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            Text(
              'Output: ${outputTotal.toStringAsFixed(0)} ml',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
            Text(
              'Balance: ${balance.toStringAsFixed(0)} ml',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission to manage I/O.'),
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
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final intakeTotal = _dailyTotalMl(true);
    final outputTotal = _dailyTotalMl(false);

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBalanceSummary(
            context,
            intakeTotal: intakeTotal,
            outputTotal: outputTotal,
          ),
          const SizedBox(height: 16),
          InpatientResponsiveRowOrColumn(
            first: SectionCard(
              title: 'Intake',
              subtitle: 'Fluids and intake for this admission',
              actions: [
                FilledButton.icon(
                  onPressed: () => _openAddRecordDialog(context, true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTable(context, rows: _rowsFor(true)),
                  const SizedBox(height: 12),
                  Text(
                    'Daily total (today): ${intakeTotal.toStringAsFixed(0)} ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            second: SectionCard(
              title: 'Output',
              subtitle: 'Urine, drains and other output',
              actions: [
                FilledButton.icon(
                  onPressed: () => _openAddRecordDialog(context, false),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTable(context, rows: _rowsFor(false)),
                  const SizedBox(height: 12),
                  Text(
                    'Daily total (today): ${outputTotal.toStringAsFixed(0)} ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTable(
    BuildContext context, {
    required List<IntakeOutputRecordModel> rows,
  }) {
    const columns = ['Time', 'Type', 'Category', 'Amount (ml)', 'Recorded by'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: rows
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      DateFormatter.dateTime(
                        r.recordedAt ?? r.createdAt ?? DateTime.now(),
                      ),
                    ),
                  ),
                  DataCell(Text(r.type ?? '—')),
                  DataCell(Text(_categoryLabel(r))),
                  DataCell(Text(r.amountMl?.toStringAsFixed(0) ?? '—')),
                  DataCell(Text(r.nurseDisplayName ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
