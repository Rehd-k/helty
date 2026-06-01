import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/models/ward_round_note_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/ward_round_note_service.dart';

@RoutePage()
class InpatientWardRoundTab extends ConsumerStatefulWidget {
  const InpatientWardRoundTab({super.key});

  @override
  ConsumerState<InpatientWardRoundTab> createState() =>
      _InpatientWardRoundTabState();
}

class _InpatientWardRoundTabState extends ConsumerState<InpatientWardRoundTab> {
  final _wardRoundNoteService = WardRoundNoteService();
  List<WardRoundNoteModel> _notes = [];
  bool _loading = true;
  String? _error;
  String? _lastLoadedAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final admissionId = InpatientViewScope.of(context)?.admissionId;
    if (admissionId != null && admissionId != _lastLoadedAdmissionId) {
      _lastLoadedAdmissionId = admissionId;
      _loadNotes(admissionId);
    }
  }

  Future<void> _loadNotes(String admissionId) async {
    if (admissionId.isEmpty) {
      setState(() {
        _notes = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _wardRoundNoteService.listByAdmission(admissionId);
      if (!mounted) return;
      list.sort((a, b) => b.roundDate.compareTo(a.roundDate));
      setState(() {
        _notes = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showAddNoteDialog() async {
    final admissionId = InpatientViewScope.of(context)?.admissionId;
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admission context missing. Open this patient from Ward Rounds or Inpatients list.')),
      );
      return;
    }
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as a doctor to add a ward round note.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AddWardRoundNoteDialog(
        admissionId: admissionId,
        doctorId: doctorId,
        wardRoundNoteService: _wardRoundNoteService,
      ),
    );
    if (result == true && mounted) {
      final id = InpatientViewScope.of(context)?.admissionId;
      if (id != null) _loadNotes(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final admissionId = InpatientViewScope.of(context)?.admissionId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (admissionId == null || admissionId.isEmpty)
            SectionCard(
              title: 'Ward round notes',
              subtitle: 'Open this patient from Ward Rounds or Inpatients list with an admission to see and add notes.',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No admission context.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          else ...[
            SectionCard(
              title: 'Ward round (progress) notes',
              subtitle: 'SOAP notes for this admission. Doctors can add new notes.',
              actions: [
                FilledButton.icon(
                  onPressed: _loading ? null : _showAddNoteDialog,
                  icon: const Icon(Icons.add_comment, size: 18),
                  label: const Text('Add round note'),
                ),
              ],
              child: _buildNotesContent(theme, colorScheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesContent(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 420;
            final message = Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            );
            final retry = TextButton(
              onPressed: () {
                final id = InpatientViewScope.of(context)?.admissionId;
                if (id != null) _loadNotes(id);
              },
              child: const Text('Retry'),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: message),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: retry),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(child: message),
                retry,
              ],
            );
          },
        ),
      );
    }
    if (_notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No ward round notes yet. Use "Add round note" to document a round.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _notes.map((n) => _NoteTile(note: n)).toList(),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final WardRoundNoteModel note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = '${note.roundDate.year}-${note.roundDate.month.toString().padLeft(2, '0')}-${note.roundDate.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              dateStr,
              if (note.doctorDisplayName != null &&
                  note.doctorDisplayName!.isNotEmpty)
                'Dr ${note.doctorDisplayName}',
            ].join(' · '),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (note.subjective != null && note.subjective!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Subjective', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(note.subjective!, style: theme.textTheme.bodyMedium),
          ],
          if (note.objective != null && note.objective!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Objective', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(note.objective!, style: theme.textTheme.bodyMedium),
          ],
          if (note.assessment != null && note.assessment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Assessment', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(note.assessment!, style: theme.textTheme.bodyMedium),
          ],
          if (note.plan != null && note.plan!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Plan', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            Text(note.plan!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _AddWardRoundNoteDialog extends StatefulWidget {
  const _AddWardRoundNoteDialog({
    required this.admissionId,
    required this.doctorId,
    required this.wardRoundNoteService,
  });

  final String admissionId;
  final String doctorId;
  final WardRoundNoteService wardRoundNoteService;

  @override
  State<_AddWardRoundNoteDialog> createState() => _AddWardRoundNoteDialogState();
}

class _AddWardRoundNoteDialogState extends State<_AddWardRoundNoteDialog> {
  final _subjectiveCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _assessmentCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = _subjectiveCtrl.text.trim();
    final o = _objectiveCtrl.text.trim();
    final a = _assessmentCtrl.text.trim();
    final p = _planCtrl.text.trim();
    if (s.isEmpty && o.isEmpty && a.isEmpty && p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one field.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.wardRoundNoteService.create(
        admissionId: widget.admissionId,
        doctorId: widget.doctorId,
        roundDate: DateTime.now(),
        subjective: s.isEmpty ? null : s,
        objective: o.isEmpty ? null : o,
        assessment: a.isEmpty ? null : a,
        plan: p.isEmpty ? null : p,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add ward round note'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: inpatientDialogBodyWidth(context, preferred: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _subjectiveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Subjective',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _objectiveCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Objective',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _assessmentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Assessment',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _planCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Plan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
