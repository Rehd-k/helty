import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/handover_report_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/services/handover_summary_builder.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/handover_report_service.dart';

@RoutePage()
class InpatientHandoverScreen extends StatefulWidget {
  const InpatientHandoverScreen({super.key});

  @override
  State<InpatientHandoverScreen> createState() =>
      _InpatientHandoverScreenState();
}

class _InpatientHandoverScreenState extends State<InpatientHandoverScreen> {
  final _summaryCtrl = TextEditingController();
  final _handoverService = HandoverReportService();
  final _summaryBuilder = HandoverSummaryBuilder();
  List<HandoverReportModel> _reports = [];
  bool _loading = true;
  bool _locked = false;
  bool _generating = false;
  String? _error;
  String? _lastAdmissionId;
  String _shiftType = 'MORNING';
  bool _submitting = false;

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _reports = [];
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
      _locked = false;
    });
    try {
      final list = await _handoverService.list(admissionId);
      list.sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reports = [];
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

  Future<void> _generateSummary(String admissionId) async {
    setState(() => _generating = true);
    try {
      final summary = await _summaryBuilder.buildTodaySummary(
        admissionId: admissionId,
        shiftType: _shiftType,
      );
      if (!mounted) return;
      setState(() {
        _summaryCtrl.text = summary;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not build handover summary: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _submit(String admissionId) async {
    final text = _summaryCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a handover summary.')),
      );
      return;
    }
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    setState(() => _submitting = true);
    try {
      await _handoverService.create(
        admissionId: admissionId,
        shiftType: _shiftType,
        summary: text,
        nurseId: nurseId,
      );
      if (!mounted) return;
      setState(() => _locked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Handover submitted.')),
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
      if (mounted) setState(() => _submitting = false);
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
          child: Text('Open this patient with an admission for handover.'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Shift Handover',
            subtitle:
                'Summarise this patient\'s status for the next nurse on duty',
            actions: [
              if (_locked)
                TextButton(
                  onPressed: () => setState(() {
                    _locked = false;
                    _summaryCtrl.clear();
                  }),
                  child: const Text('New handover'),
                ),
              if (!_locked && !_loading)
                FilledButton.icon(
                  onPressed: _submitting || _generating
                      ? null
                      : () => _generateSummary(admissionId),
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Shift Handover'),
                ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_locked) ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(_shiftType),
                    initialValue: _shiftType,
                    decoration: const InputDecoration(labelText: 'Shift'),
                    items: const [
                      DropdownMenuItem(
                        value: 'MORNING',
                        child: Text('Morning'),
                      ),
                      DropdownMenuItem(
                        value: 'AFTERNOON',
                        child: Text('Afternoon'),
                      ),
                      DropdownMenuItem(
                        value: 'NIGHT',
                        child: Text('Night'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (v) {
                            if (v != null) setState(() => _shiftType = v);
                          },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _summaryCtrl,
                  maxLines: 10,
                  readOnly: _locked,
                  decoration: const InputDecoration(
                    hintText:
                        'Vitals trend, meds given and pending, critical notes...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _locked
                      ? Text(
                          'Handover submitted. Add another from a new shift if needed.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        )
                      : FilledButton(
                          onPressed:
                              _submitting ? null : () => _submit(admissionId),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Previous handovers',
            subtitle: 'Recorded for this admission',
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: () => _load(admissionId),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : _reports.isEmpty
                        ? const Text('No handover reports yet.')
                        : Column(
                            children: _reports.map((r) {
                              final when = r.createdAt != null
                                  ? DateFormatter.dateTime(r.createdAt!)
                                  : '—';
                              final by = r.recorderDisplayName;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  [
                                    r.shiftType ?? 'Shift',
                                    when,
                                    if (by != null && by.isNotEmpty)
                                      'by $by',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  r.displayBody,
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
          ),
        ],
      ),
    );
  }
}
