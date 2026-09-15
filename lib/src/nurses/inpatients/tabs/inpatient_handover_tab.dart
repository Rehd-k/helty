import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/handover_report_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/services/handover_summary_builder.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/widgets/helty_surface.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Handover submitted.')));
      await _load(admissionId);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_dioMessage(e))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
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

    final canRecord =
        scope?.isAdmissionActive == true && scope?.isNurse == true;
    final now = DateTime.now();
    final today = _reports.where((r) {
      final t = r.createdAt;
      if (t == null) return false;
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).length;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InpatientTabToolbar(
              icon: Icons.handshake_outlined,
              iconColor: InpatientMetrics.iconPurple,
              title: 'Handover',
              subtitle: 'Shift summary for the next nurse',
              actions: [
                if (_locked)
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _locked = false;
                      _summaryCtrl.clear();
                    }),
                    style: inpatientCompactOutline(),
                    child: const Text('New handover'),
                  ),
                if (!_locked && !_loading)
                  FilledButton.icon(
                    onPressed: !canRecord || _submitting || _generating
                        ? null
                        : () => _generateSummary(admissionId),
                    icon: _generating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Generate'),
                    style: inpatientCompactFill(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            InpatientKpiRow(
              tiles: [
                InpatientKpiTile(
                  icon: Icons.handshake_outlined,
                  color: InpatientMetrics.iconPurple,
                  label: 'Handovers',
                  value: _loading ? '—' : '${_reports.length}',
                  caption: 'This admission',
                ),
                InpatientKpiTile(
                  icon: Icons.today_outlined,
                  color: InpatientMetrics.iconBlue,
                  label: 'Today',
                  value: _loading ? '—' : '$today',
                  caption: 'Submitted today',
                ),
              ],
            ),
            const SizedBox(height: 10),
            SectionCard(
              title: 'Shift handover',
              subtitle: 'Summarise status for the next nurse on duty',
              icon: Icons.edit_note_outlined,
              iconColor: InpatientMetrics.iconPurple,
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
                        DropdownMenuItem(value: 'NIGHT', child: Text('Night')),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) {
                              if (v != null) setState(() => _shiftType = v);
                            },
                    ),
                    const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _locked
                        ? Text(
                            'Handover submitted. Add another from a new shift if needed.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          )
                        : FilledButton(
                            onPressed: !canRecord || _submitting
                                ? null
                                : () => _submit(admissionId),
                            style: inpatientCompactFill(),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
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
            const SizedBox(height: 10),
            SectionCard(
              title: 'Previous handovers',
              subtitle: 'Recorded for this admission',
              icon: Icons.history,
              iconColor: InpatientMetrics.iconIndigo,
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
                      children: [
                        for (var i = 0; i < _reports.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          HeltySurfaceCard(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HeltyStatusChip(
                                      label: _reports[i].shiftType ?? 'Shift',
                                      color: InpatientMetrics.iconPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: HeltyEllipsisText(
                                        text: [
                                          if (_reports[i].createdAt != null)
                                            DateFormatter.dateTime(
                                              _reports[i].createdAt!,
                                            ),
                                          if ((_reports[i]
                                                      .recorderDisplayName ??
                                                  '')
                                              .isNotEmpty)
                                            'by ${_reports[i].recorderDisplayName}',
                                        ].join(' · '),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _reports[i].displayBody,
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
