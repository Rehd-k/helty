import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/quill_content_helper.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/nursing_note_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/nursing_note_service.dart';
import 'package:helty/src/widgets/expandable_rich_content.dart';
import 'package:helty/src/widgets/helty_surface.dart';

const _kNoteTypes = <(String, String)>[
  ('GENERAL', 'General'),
  ('INCIDENT', 'Incident'),
  ('SHIFT_SUMMARY', 'Shift summary'),
];

@RoutePage()
class InpatientNotesScreen extends StatefulWidget {
  const InpatientNotesScreen({super.key});

  @override
  State<InpatientNotesScreen> createState() => _InpatientNotesScreenState();
}

class _InpatientNotesScreenState extends State<InpatientNotesScreen> {
  final _service = NursingNoteService();
  List<NursingNoteModel> _notes = [];
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
          _notes = [];
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
        _notes = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notes = [];
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

  bool _isToday(DateTime? t) {
    if (t == null) return false;
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  bool _canEditNote(NursingNoteModel note, InpatientViewScope? scope) {
    if (scope == null || !scope.isNurse || !scope.isAdmissionActive) {
      return false;
    }
    final staffId = scope.staffId?.trim();
    if (staffId == null || staffId.isEmpty) return false;
    final authorId = note.nurseId?.trim();
    if (authorId == null || authorId.isEmpty) return true;
    return authorId == staffId;
  }

  Future<void> _openComposer({NursingNoteModel? existing}) async {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    if (admissionId == null || admissionId.isEmpty) return;

    String? nurseId;
    if (existing == null) {
      nurseId = requireNurseIdFromScope(context);
      if (nurseId == null) return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NursingReportComposerDialog(
        admissionId: admissionId,
        service: _service,
        existing: existing,
        nurseId: nurseId,
        dioMessage: _dioMessage,
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Nursing report saved.'
                : 'Nursing report updated.',
          ),
        ),
      );
      await _load(admissionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    final canRecord = scope?.readOnly != true;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Open this patient with an admission to view nursing reports.',
          ),
        ),
      );
    }

    final todayCount = _notes.where((n) => _isToday(n.createdAt)).length;
    final incidentCount = _notes
        .where((n) => (n.noteType ?? '').toUpperCase() == 'INCIDENT')
        .length;
    final shiftCount = _notes
        .where((n) => (n.noteType ?? '').toUpperCase() == 'SHIFT_SUMMARY')
        .length;

    return ResponsiveBody(
      expand: true,
      center: false,
      bottomPadding: 8,
      builder: (context, bp) => Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InpatientTabToolbar(
                    icon: Icons.notes_outlined,
                    iconColor: InpatientMetrics.iconPink,
                    title: 'Nursing Report',
                    subtitle: 'Shift notes, incidents, and observations',
                  ),
              const SizedBox(height: 10),
              _NotesKpiStrip(
                loading: _loading,
                total: _notes.length,
                today: todayCount,
                incidents: incidentCount,
                shiftSummaries: shiftCount,
              ),
              const SizedBox(height: 10),
              SectionCard(
                title: 'Reports timeline',
                subtitle: 'Newest first',
                icon: Icons.timeline_outlined,
                iconColor: InpatientMetrics.iconIndigo,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _error != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
                          ),
                          TextButton(
                            onPressed: () => _load(admissionId),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : _notes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          canRecord
                              ? 'No nursing reports yet. Tap New report to add one.'
                              : 'No nursing reports yet.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < _notes.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _NursingReportTile(
                              note: _notes[i],
                              canEdit: _canEditNote(_notes[i], scope),
                              onEdit: () =>
                                  _openComposer(existing: _notes[i]),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                              child: Text(
                                _notes.length == 1
                                    ? '1 report'
                                    : '${_notes.length} reports',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
                ],
              ),
            ),
          ),
          if (canRecord)
            Positioned(
              right: 16,
              bottom: 16,
              child: _NursingReportFab(
                onPressed: () => _openComposer(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NursingReportFab extends StatelessWidget {
  const _NursingReportFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InpatientMetrics.iconPink,
      elevation: 6,
      shadowColor: InpatientMetrics.iconPink.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'New report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesKpiStrip extends StatelessWidget {
  const _NotesKpiStrip({
    required this.loading,
    required this.total,
    required this.today,
    required this.incidents,
    required this.shiftSummaries,
  });

  final bool loading;
  final int total;
  final int today;
  final int incidents;
  final int shiftSummaries;

  String _v(int n) => loading ? '—' : '$n';

  @override
  Widget build(BuildContext context) {
    final items = [
      InpatientKpiTile(
        icon: Icons.notes_outlined,
        color: InpatientMetrics.iconPink,
        label: 'Reports',
        value: _v(total),
        caption: 'This admission',
      ),
      InpatientKpiTile(
        icon: Icons.today_outlined,
        color: InpatientMetrics.iconBlue,
        label: 'Today',
        value: _v(today),
        caption: 'Recorded today',
      ),
      InpatientKpiTile(
        icon: Icons.report_outlined,
        color: InpatientMetrics.waitRed,
        label: 'Incidents',
        value: _v(incidents),
        caption: 'Incident reports',
      ),
      InpatientKpiTile(
        icon: Icons.assignment_outlined,
        color: InpatientMetrics.iconPurple,
        label: 'Shift',
        value: _v(shiftSummaries),
        caption: 'Shift summaries',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: items[i]),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => items[i],
        );
      },
    );
  }
}

class _NursingReportTile extends StatelessWidget {
  const _NursingReportTile({
    required this.note,
    required this.canEdit,
    required this.onEdit,
  });

  final NursingNoteModel note;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final type = (note.noteType ?? 'GENERAL').toUpperCase();
    final meta = [
      if (note.authorName != null && note.authorName!.isNotEmpty)
        'Recorded by ${note.authorName}',
      if (note.createdAt != null) DateFormatter.dateTime(note.createdAt!),
      if (note.updatedAt != null &&
          note.createdAt != null &&
          note.updatedAt!.isAfter(note.createdAt!))
        'Edited ${DateFormatter.dateTime(note.updatedAt!)}',
    ].where((s) => s.isNotEmpty).join(' · ');

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeltySolidIcon(
                icon: _noteTypeIcon(type),
                color: _noteTypeColor(type),
                size: 28,
                iconSize: 15,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeltyStatusChip(
                          label: _noteTypeLabel(type),
                          color: _noteTypeColor(type),
                        ),
                        const Spacer(),
                        if (canEdit)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: OutlinedButton(
                              onPressed: onEdit,
                              style: inpatientCompactOutline(),
                              child: const Text('Edit'),
                            ),
                          ),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      HeltyEllipsisText(
                        text: meta,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ExpandableRichContent(content: note.content ?? ''),
        ],
      ),
    );
  }
}

class _NursingReportComposerDialog extends StatefulWidget {
  const _NursingReportComposerDialog({
    required this.admissionId,
    required this.service,
    required this.dioMessage,
    this.existing,
    this.nurseId,
  });

  final String admissionId;
  final NursingNoteService service;
  final String Function(DioException) dioMessage;
  final NursingNoteModel? existing;
  final String? nurseId;

  @override
  State<_NursingReportComposerDialog> createState() =>
      _NursingReportComposerDialogState();
}

class _NursingReportComposerDialogState
    extends State<_NursingReportComposerDialog> {
  late final QuillController _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late String _noteType;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _noteType = widget.existing?.noteType ?? 'GENERAL';
    _controller = widget.existing == null
        ? QuillController.basic(config: QuillControllerConfig())
        : quillControllerFromStoredContent(widget.existing!.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final plain = plainTextFromStoredContent(encodeQuillContent(_controller));
    if (plain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter report text.')),
      );
      return;
    }

    if (!_isEdit) {
      final nurseId = widget.nurseId?.trim();
      if (nurseId == null || nurseId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in as staff to record documentation.'),
          ),
        );
        return;
      }
      setState(() => _saving = true);
      try {
        await widget.service.create(
          admissionId: widget.admissionId,
          noteType: _noteType,
          content: encodeQuillContent(_controller),
          nurseId: nurseId,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } on DioException catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.dioMessage(e))),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.service.update(
        admissionId: widget.admissionId,
        noteId: widget.existing!.id,
        noteType: _noteType,
        content: encodeQuillContent(_controller),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.dioMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final maxW = size.width < 900 ? size.width - 32 : 840.0;
    final maxH = size.height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: SizedBox(
        width: maxW,
        height: maxH,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HeltySolidIcon(
                    icon: _isEdit
                        ? Icons.edit_outlined
                        : Icons.edit_note_rounded,
                    color: InpatientMetrics.iconPink,
                    size: 34,
                    iconSize: 18,
                    radius: AppTheme.radiusMd,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeltyEllipsisText(
                          text: _isEdit
                              ? 'Edit nursing report'
                              : 'New nursing report',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        HeltyEllipsisText(
                          text: 'Document observations for this admission',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_noteType),
                initialValue: _noteType,
                decoration: const InputDecoration(labelText: 'Report type'),
                items: [
                  for (final item in _kNoteTypes)
                    DropdownMenuItem(value: item.$1, child: Text(item.$2)),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) setState(() => _noteType = v);
                      },
              ),
              const SizedBox(height: 12),
              QuillSimpleToolbar(controller: _controller),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: QuillEditor.basic(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: InpatientMetrics.iconPink,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEdit ? 'Save changes' : 'Add report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _noteTypeLabel(String type) {
  return switch (type.toUpperCase()) {
    'INCIDENT' => 'Incident',
    'SHIFT_SUMMARY' => 'Shift summary',
    _ => 'General',
  };
}

Color _noteTypeColor(String type) {
  return switch (type.toUpperCase()) {
    'INCIDENT' => InpatientMetrics.waitRed,
    'SHIFT_SUMMARY' => InpatientMetrics.iconPurple,
    _ => InpatientMetrics.iconBlue,
  };
}

IconData _noteTypeIcon(String type) {
  return switch (type.toUpperCase()) {
    'INCIDENT' => Icons.report_outlined,
    'SHIFT_SUMMARY' => Icons.assignment_outlined,
    _ => Icons.notes_outlined,
  };
}
