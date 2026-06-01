import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/monitoring_chart_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/monitoring_chart_service.dart';

@RoutePage()
class InpatientMonitoringScreen extends StatefulWidget {
  const InpatientMonitoringScreen({super.key});

  @override
  State<InpatientMonitoringScreen> createState() =>
      _InpatientMonitoringScreenState();
}

class _InpatientMonitoringScreenState extends State<InpatientMonitoringScreen> {
  final _service = MonitoringChartService();
  List<MonitoringChartModel> _charts = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;

  String _chartType = 'GCS';

  final _gcsEye = TextEditingController();
  final _gcsVerbal = TextEditingController();
  final _gcsMotor = TextEditingController();
  final _jsonValue = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _gcsEye.dispose();
    _gcsVerbal.dispose();
    _gcsMotor.dispose();
    _jsonValue.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _charts = [];
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
        _charts = list;
        _loading = false;
      });
      _prefillFromLatest();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _charts = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _prefillFromLatest() {
    final forType = _charts
        .where((c) => (c.chartType ?? '').toUpperCase() == _chartType)
        .toList();
    forType.sort((a, b) {
      final ta = a.createdAt;
      final tb = b.createdAt;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    final latest = forType.isEmpty ? null : forType.first;
    final v = latest?.value;
    if (_chartType == 'GCS' && v != null) {
      _gcsEye.text = '${v['eye'] ?? v['Eye'] ?? ''}'.trim();
      _gcsVerbal.text = '${v['verbal'] ?? v['Verbal'] ?? ''}'.trim();
      _gcsMotor.text = '${v['motor'] ?? v['Motor'] ?? ''}'.trim();
      _jsonValue.clear();
    } else if (v != null) {
      _jsonValue.text = const JsonEncoder.withIndent('  ').convert(v);
      _gcsEye.clear();
      _gcsVerbal.clear();
      _gcsMotor.clear();
    } else {
      _gcsEye.clear();
      _gcsVerbal.clear();
      _gcsMotor.clear();
      _jsonValue.clear();
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  Future<void> _save(String admissionId) async {
    Map<String, dynamic> value;
    if (_chartType == 'GCS') {
      final e = int.tryParse(_gcsEye.text.trim());
      final ve = int.tryParse(_gcsVerbal.text.trim());
      final m = int.tryParse(_gcsMotor.text.trim());
      if (e == null || ve == null || m == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter valid GCS eye, verbal, and motor scores.'),
          ),
        );
        return;
      }
      value = {'eye': e, 'verbal': ve, 'motor': m};
    } else {
      final raw = _jsonValue.text.trim();
      if (raw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter JSON value for this chart.')),
        );
        return;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          throw FormatException('Root must be a JSON object');
        }
        value = Map<String, dynamic>.from(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid JSON: $e')),
        );
        return;
      }
    }

    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    setState(() => _saving = true);
    try {
      await _service.create(
        admissionId: admissionId,
        chartType: _chartType,
        value: value,
        nurseId: nurseId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart entry saved.')),
      );
      await _load(admissionId);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_dioMessage(e))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            'Open this patient with an admission for monitoring charts.',
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
            Text(_error!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final forType = _charts
        .where((c) => (c.chartType ?? '').toUpperCase() == _chartType)
        .toList()
      ..sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Monitoring',
        subtitle: 'Structured charts (GCS, neuro, cardiac, seizure)',
        actions: [
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(admissionId),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save entry'),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(_chartType),
              initialValue: _chartType,
              decoration: const InputDecoration(labelText: 'Chart type'),
              items: const [
                DropdownMenuItem(value: 'GCS', child: Text('GCS')),
                DropdownMenuItem(value: 'NEURO', child: Text('NEURO')),
                DropdownMenuItem(value: 'CARDIAC', child: Text('CARDIAC')),
                DropdownMenuItem(value: 'SEIZURE', child: Text('SEIZURE')),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _chartType = v);
                      _prefillFromLatest();
                    },
            ),
            const SizedBox(height: 16),
            if (_chartType == 'GCS') ...[
              LayoutBuilder(
                builder: (context, c) {
                  final stack = c.maxWidth < 480;
                  final eye = TextField(
                    controller: _gcsEye,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Eye',
                      border: OutlineInputBorder(),
                    ),
                  );
                  final verbal = TextField(
                    controller: _gcsVerbal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Verbal',
                      border: OutlineInputBorder(),
                    ),
                  );
                  final motor = TextField(
                    controller: _gcsMotor,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Motor',
                      border: OutlineInputBorder(),
                    ),
                  );
                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        eye,
                        const SizedBox(height: 8),
                        verbal,
                        const SizedBox(height: 8),
                        motor,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: eye),
                      const SizedBox(width: 8),
                      Expanded(child: verbal),
                      const SizedBox(width: 8),
                      Expanded(child: motor),
                    ],
                  );
                },
              ),
            ] else ...[
              TextField(
                controller: _jsonValue,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Value (JSON object)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: '{"key": "value"}',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Recent entries ($_chartType)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (forType.isEmpty)
              Text(
                'No entries yet for this chart type.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              )
            else
              ...forType.take(8).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          [
                            if (c.createdAt != null)
                              DateFormatter.dateTime(c.createdAt!),
                            if (c.recorderDisplayName != null &&
                                c.recorderDisplayName!.isNotEmpty)
                              'by ${c.recorderDisplayName}',
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          c.value == null
                              ? '—'
                              : const JsonEncoder.withIndent('  ')
                                  .convert(c.value),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
