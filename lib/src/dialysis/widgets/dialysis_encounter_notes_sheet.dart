import 'package:flutter/material.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/services/encounter_service.dart';

Future<bool?> showDialysisEncounterNotesSheet({
  required BuildContext context,
  required String encounterId,
  required String status,
  String? chiefComplaint,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _DialysisEncounterNotesSheet(
        encounterId: encounterId,
        status: status,
        chiefComplaint: chiefComplaint,
      ),
    ),
  );
}

class _DialysisEncounterNotesSheet extends StatefulWidget {
  const _DialysisEncounterNotesSheet({
    required this.encounterId,
    required this.status,
    this.chiefComplaint,
  });

  final String encounterId;
  final String status;
  final String? chiefComplaint;

  @override
  State<_DialysisEncounterNotesSheet> createState() =>
      _DialysisEncounterNotesSheetState();
}

class _DialysisEncounterNotesSheetState
    extends State<_DialysisEncounterNotesSheet> {
  final _encounterService = EncounterService();
  final _notesCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isCompleted =>
      widget.status.toUpperCase() == 'COMPLETED';

  bool get _isCancelled =>
      widget.status.toUpperCase() == 'CANCELLED';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enc = await _encounterService.getById(widget.encounterId);
      if (!mounted) return;
      final notes = enc?.triageNotes?.trim();
      _notesCtrl.text = notes ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_isCancelled) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final notes = _notesCtrl.text.trim();
      final body = <String, dynamic>{
        'triageNotes': notes.isEmpty ? null : notes,
      };
      if (_isCompleted) {
        final reason = _reasonCtrl.text.trim();
        if (reason.isNotEmpty) {
          body['editReason'] = reason;
        }
      }

      await _encounterService.update(widget.encounterId, body);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.chiefComplaint?.trim().isNotEmpty == true
        ? widget.chiefComplaint!.trim()
        : 'Encounter notes';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Material(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (_isCancelled)
                Text(
                  'Notes cannot be edited on cancelled encounters.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _notesCtrl,
                  maxLines: 8,
                  enabled: !_isCancelled,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Dialysis / clinical notes for this encounter…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                if (_isCompleted) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Edit reason (recommended for completed)',
                      hintText: 'Why are you updating this encounter?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving || _isCancelled ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save notes'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
