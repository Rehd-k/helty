import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterExaminationTab extends StatefulWidget {
  const DoctorEncounterExaminationTab({super.key});

  @override
  State<DoctorEncounterExaminationTab> createState() =>
      _DoctorEncounterExaminationTabState();
}

class _DoctorEncounterExaminationTabState
    extends State<DoctorEncounterExaminationTab> {
  final _encounterService = EncounterService();
  late final TextEditingController _generalAppearanceCtrl;
  late final TextEditingController _cardiovascularCtrl;
  late final TextEditingController _respiratoryCtrl;
  late final TextEditingController _abdomenCtrl;
  late final TextEditingController _cnsCtrl;
  late final TextEditingController _musculoskeletalCtrl;
  late final TextEditingController _entCtrl;
  late final TextEditingController _skinCtrl;
  late final TextEditingController _notesCtrl;

  bool _loading = false;
  bool _loaded = false;
  Map<String, String?> _vitals = {};

  @override
  void initState() {
    super.initState();
    _generalAppearanceCtrl = TextEditingController();
    _cardiovascularCtrl = TextEditingController();
    _respiratoryCtrl = TextEditingController();
    _abdomenCtrl = TextEditingController();
    _cnsCtrl = TextEditingController();
    _musculoskeletalCtrl = TextEditingController();
    _entCtrl = TextEditingController();
    _skinCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _loadDraft();
    _loadVitals();
  }

  @override
  void dispose() {
    _generalAppearanceCtrl.dispose();
    _cardiovascularCtrl.dispose();
    _respiratoryCtrl.dispose();
    _abdomenCtrl.dispose();
    _cnsCtrl.dispose();
    _musculoskeletalCtrl.dispose();
    _entCtrl.dispose();
    _skinCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVitals() async {
    // Stub: in real app load from vitals API by patientId/encounterId
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() {
      _vitals = {
        'BP': '120/80',
        'HR': '72',
        'Temp': '36.6°C',
        'RR': '16',
        'SpO2': '98%',
      };
    });
  }

  Future<void> _loadDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc?.examinationNotes != null && enc!.examinationNotes!.isNotEmpty) {
        _notesCtrl.text = enc.examinationNotes!;
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
    setState(() => _loading = true);
    final notes = [
      'General: ${_generalAppearanceCtrl.text.trim()}',
      'CVS: ${_cardiovascularCtrl.text.trim()}',
      'Resp: ${_respiratoryCtrl.text.trim()}',
      'Abdomen: ${_abdomenCtrl.text.trim()}',
      'CNS: ${_cnsCtrl.text.trim()}',
      'MSK: ${_musculoskeletalCtrl.text.trim()}',
      'ENT: ${_entCtrl.text.trim()}',
      'Skin: ${_skinCtrl.text.trim()}',
      if (_notesCtrl.text.trim().isNotEmpty) _notesCtrl.text.trim(),
    ].where((e) => e.split(':').last.trim().isNotEmpty).join('\n\n');
    try {
      await _encounterService.update(scope.encounterId, {
        'examinationNotes': notes.isEmpty ? null : notes,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Examination draft saved')),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _loading = false);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vitals.isNotEmpty) ...[
            Text(
              'Vitals (read-only)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _vitals.entries
                  .map(
                    (e) => Chip(
                      label: Text('${e.key}: ${e.value ?? "—"}'),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          _section('General Appearance', _generalAppearanceCtrl),
          _section('Cardiovascular', _cardiovascularCtrl),
          _section('Respiratory', _respiratoryCtrl),
          _section('Abdomen', _abdomenCtrl),
          _section('CNS', _cnsCtrl),
          _section('Musculoskeletal', _musculoskeletalCtrl),
          _section('ENT', _entCtrl),
          _section('Skin', _skinCtrl),
          _section('Additional notes', _notesCtrl, maxLines: 4),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _loading ? null : _saveDraft,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save draft'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, TextEditingController ctrl, {int maxLines = 2}) {
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
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter $label',
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
