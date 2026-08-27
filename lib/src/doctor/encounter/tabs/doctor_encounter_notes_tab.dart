import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/doctor/encounter/encounter_tab_reload.dart';
import 'package:helty/src/doctor/encounter/widgets/encounter_tab_scroll_shell.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterNotesTab extends StatefulWidget {
  const DoctorEncounterNotesTab({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DoctorEncounterNotesTab> createState() =>
      _DoctorEncounterNotesTabState();
}

class _DoctorEncounterNotesTabState extends State<DoctorEncounterNotesTab> {
  final _encounterService = EncounterService();
  static const _lockAfterMinutes = 15;

  late final TextEditingController _subjectiveCtrl;
  late final TextEditingController _objectiveCtrl;
  late final TextEditingController _assessmentCtrl;
  late final TextEditingController _planCtrl;
  late final TextEditingController _addendumCtrl;

  bool _loading = false;
  bool _loaded = false;
  DateTime? _lockedAt;
  bool _saving = false;

  bool get _isLocked => _lockedAt != null;
  bool _draftLoadScheduled = false;
  int _lastReloadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _subjectiveCtrl = TextEditingController();
    _objectiveCtrl = TextEditingController();
    _assessmentCtrl = TextEditingController();
    _planCtrl = TextEditingController();
    _addendumCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reloadEncounterTabIfTemplateApplied(
      context: context,
      lastReloadGeneration: _lastReloadGeneration,
      updateLastReloadGeneration: (v) => _lastReloadGeneration = v,
      loaded: _loaded,
      reload: _loadDraft,
    );
    if (!_draftLoadScheduled) {
      _draftLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDraft();
      });
    }
  }

  @override
  void dispose() {
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _addendumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc != null) {
        _subjectiveCtrl.text = enc.soapSubjective ?? '';
        _objectiveCtrl.text = enc.soapObjective ?? '';
        _assessmentCtrl.text = enc.soapAssessment ?? '';
        _planCtrl.text = enc.soapPlan ?? '';
        _lockedAt = enc.soapLockedAt;
      }
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _saving = true);
    try {
      await _encounterService.update(
        scope.encounterId,
        encounterPatchWithAmend(scope, {
          'soapSubjective': _subjectiveCtrl.text.trim().isEmpty
              ? null
              : _subjectiveCtrl.text.trim(),
          'soapObjective': _objectiveCtrl.text.trim().isEmpty
              ? null
              : _objectiveCtrl.text.trim(),
          'soapAssessment': _assessmentCtrl.text.trim().isEmpty
              ? null
              : _assessmentCtrl.text.trim(),
          'soapPlan': _planCtrl.text.trim().isEmpty
              ? null
              : _planCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      showEncounterSaveSnackBar(
        context,
        scope: scope,
        ongoingMessage: 'SOAP note saved',
      );
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      showEncounterEditErrorSnackBar(context, e);
      setState(() => _saving = false);
    }
  }

  Future<void> _lockNote() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await _encounterService.update(
        scope.encounterId,
        encounterPatchWithAmend(scope, {
          'soapSubjective': _subjectiveCtrl.text.trim().isEmpty
              ? null
              : _subjectiveCtrl.text.trim(),
          'soapObjective': _objectiveCtrl.text.trim().isEmpty
              ? null
              : _objectiveCtrl.text.trim(),
          'soapAssessment': _assessmentCtrl.text.trim().isEmpty
              ? null
              : _assessmentCtrl.text.trim(),
          'soapPlan': _planCtrl.text.trim().isEmpty
              ? null
              : _planCtrl.text.trim(),
          'soapLockedAt': now.toIso8601String(),
        }),
      );
      if (!mounted) return;
      setState(() {
        _lockedAt = now;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note locked. Only addendum allowed.')),
      );
    } catch (e) {
      if (!mounted) return;
      showEncounterEditErrorSnackBar(context, e);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading && !_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final locked = _isLocked;
    final readOnly = !scope.canEdit;
    final fieldsReadOnly = locked || readOnly;

    return EncounterTabScrollShell(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Note locked (after $_lockAfterMinutes min). Add addendum below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          _soapSection('S — Subjective', _subjectiveCtrl, fieldsReadOnly),
          _soapSection('O — Objective', _objectiveCtrl, fieldsReadOnly),
          _soapSection('A — Assessment', _assessmentCtrl, fieldsReadOnly),
          _soapSection('P — Plan', _planCtrl, fieldsReadOnly),
          if (locked && !readOnly) ...[
            const SizedBox(height: 16),
            Text(
              'Addendum',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addendumCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add addendum (time-stamped)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!locked && !readOnly)
            ResponsiveToolbar(
              actions: [
                FilledButton.icon(
                  onPressed: _saving ? null : _saveDraft,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save draft'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _lockNote,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text('Lock (after $_lockAfterMinutes min)'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _soapSection(String label, TextEditingController ctrl, bool readOnly) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: 4,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: readOnly ? '' : 'Enter $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }
}
