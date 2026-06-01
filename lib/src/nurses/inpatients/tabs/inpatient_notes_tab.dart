import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/nursing_note_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/nursing_note_service.dart';

@RoutePage()
class InpatientNotesScreen extends StatefulWidget {
  const InpatientNotesScreen({super.key});

  @override
  State<InpatientNotesScreen> createState() => _InpatientNotesScreenState();
}

class _InpatientNotesScreenState extends State<InpatientNotesScreen> {
  final _noteCtrl = TextEditingController();
  final _service = NursingNoteService();
  List<NursingNoteModel> _notes = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;
  String _noteType = 'GENERAL';
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
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

  Future<void> _submitNote(BuildContext context, String admissionId) async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter note text.')),
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
        content: text,
        nurseId: nurseId,
      );
      _noteCtrl.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved.')),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission to view notes.'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'New Nursing Note',
            subtitle: 'Narrative note for this admission',
            actions: [
              FilledButton.icon(
                onPressed: _saving ? null : () => _submitNote(context, admissionId),
                icon: const Icon(Icons.add_comment, size: 18),
                label: const Text('Add Note'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(_noteType),
                  initialValue: _noteType,
                  decoration: const InputDecoration(labelText: 'Note type'),
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
                TextField(
                  controller: _noteCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter nursing note...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Notes Timeline',
            subtitle: 'Nursing notes (newest first)',
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
                            title: const Text('No notes recorded yet'),
                            subtitle: const Text(
                              'Add a note above to see it listed here.',
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
                                    title: Text(
                                      n.noteType ?? 'Note',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                          ].where((s) => s.isNotEmpty).join(
                                            ' · ',
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n.content ?? ''),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
          ),
        ],
      ),
    );
  }
}
