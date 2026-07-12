import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/quill_content_helper.dart';
import 'package:helty/src/models/nursing_note_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/nursing_note_service.dart';
import 'package:helty/src/widgets/expandable_rich_content.dart';

@RoutePage()
class InpatientNotesScreen extends StatefulWidget {
  const InpatientNotesScreen({super.key});

  @override
  State<InpatientNotesScreen> createState() => _InpatientNotesScreenState();
}

class _InpatientNotesScreenState extends State<InpatientNotesScreen> {
  late final QuillController _quillController;
  final _service = NursingNoteService();
  final _quillFocusNode = FocusNode();
  final _quillScrollController = ScrollController();
  List<NursingNoteModel> _notes = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;
  String _noteType = 'GENERAL';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic(config: QuillControllerConfig());
  }

  @override
  void dispose() {
    _quillController.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    super.dispose();
  }

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

  void _clearEditor() {
    _quillController.document = Document();
    _quillController.updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  Future<void> _submitReport(BuildContext context, String admissionId) async {
    final plain = plainTextFromStoredContent(
      encodeQuillContent(_quillController),
    );
    if (plain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter report text.')),
      );
      return;
    }
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;
    setState(() => _saving = true);
    try {
      await _service.create(
        admissionId: admissionId,
        noteType: _noteType,
        content: encodeQuillContent(_quillController),
        nurseId: nurseId,
      );
      _clearEditor();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nursing report saved.')),
      );
      await _load(admissionId);
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dioMessage(e))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Future<void> _openEditDialog(
    BuildContext context,
    String admissionId,
    NursingNoteModel note,
  ) async {
    final controller = quillControllerFromStoredContent(note.content);
    final focusNode = FocusNode();
    final scrollController = ScrollController();
    String noteType = note.noteType ?? 'GENERAL';
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Edit nursing report'),
                content: SizedBox(
                  width: inpatientDialogBodyWidth(ctx, preferred: 520),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(noteType),
                          initialValue: noteType,
                          decoration: const InputDecoration(
                            labelText: 'Report type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'GENERAL',
                              child: Text('General'),
                            ),
                            DropdownMenuItem(
                              value: 'INCIDENT',
                              child: Text('Incident'),
                            ),
                            DropdownMenuItem(
                              value: 'SHIFT_SUMMARY',
                              child: Text('Shift summary'),
                            ),
                          ],
                          onChanged: saving
                              ? null
                              : (v) {
                                  if (v != null) setLocal(() => noteType = v);
                                },
                        ),
                        const SizedBox(height: 12),
                        QuillSimpleToolbar(controller: controller),
                        const SizedBox(height: 8),
                        Container(
                          height: 180,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: QuillEditor.basic(
                            controller: controller,
                            focusNode: focusNode,
                            scrollController: scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final plain = plainTextFromStoredContent(
                              encodeQuillContent(controller),
                            );
                            if (plain.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter report text.'),
                                ),
                              );
                              return;
                            }
                            setLocal(() => saving = true);
                            try {
                              await _service.update(
                                admissionId: admissionId,
                                noteId: note.id,
                                noteType: noteType,
                                content: encodeQuillContent(controller),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nursing report updated.'),
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
          );
        },
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
      scrollController.dispose();
    }
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
          child: Text('Open this patient with an admission to view nursing reports.'),
        ),
      );
    }

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'New Nursing Report',
            subtitle: 'Document nursing observations for this admission',
            actions: [
              FilledButton.icon(
                onPressed:
                    _saving ? null : () => _submitReport(context, admissionId),
                icon: const Icon(Icons.add_comment, size: 18),
                label: const Text('Add Report'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_noteType),
                  initialValue: _noteType,
                  decoration: const InputDecoration(labelText: 'Report type'),
                  items: const [
                    DropdownMenuItem(value: 'GENERAL', child: Text('General')),
                    DropdownMenuItem(value: 'INCIDENT', child: Text('Incident')),
                    DropdownMenuItem(
                      value: 'SHIFT_SUMMARY',
                      child: Text('Shift summary'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v != null) setState(() => _noteType = v);
                        },
                ),
                const SizedBox(height: 12),
                QuillSimpleToolbar(controller: _quillController),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: QuillEditor.basic(
                    controller: _quillController,
                    focusNode: _quillFocusNode,
                    scrollController: _quillScrollController,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Reports Timeline',
            subtitle: 'Nursing reports (newest first)',
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_error!, style: TextStyle(color: scheme.error)),
                          TextButton(
                            onPressed: () => _load(admissionId),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : _notes.isEmpty
                        ? ListTile(
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: const Text('No nursing reports yet'),
                            subtitle: const Text(
                              'Add a report above to see it listed here.',
                            ),
                          )
                        : Column(
                            children: _notes
                                .map(
                                  (n) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.noteType ?? 'Report',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        if (_canEditNote(n, scope))
                                          IconButton(
                                            tooltip: 'Edit report',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () => _openEditDialog(
                                              context,
                                              admissionId,
                                              n,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          [
                                            if (n.authorName != null &&
                                                n.authorName!.isNotEmpty)
                                              'Recorded by ${n.authorName}',
                                            if (n.createdAt != null)
                                              DateFormatter.dateTime(
                                                n.createdAt!,
                                              ),
                                            if (n.updatedAt != null &&
                                                n.createdAt != null &&
                                                n.updatedAt!
                                                    .isAfter(n.createdAt!))
                                              'Edited ${DateFormatter.dateTime(n.updatedAt!)}',
                                          ].where((s) => s.isNotEmpty).join(
                                            ' · ',
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        ExpandableRichContent(
                                          content: n.content ?? '',
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
          ),
        ],
      ),
      ),
    );
  }
}
