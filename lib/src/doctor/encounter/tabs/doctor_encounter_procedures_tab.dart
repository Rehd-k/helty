import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterProceduresTab extends StatefulWidget {
  const DoctorEncounterProceduresTab({super.key});

  @override
  State<DoctorEncounterProceduresTab> createState() =>
      _DoctorEncounterProceduresTabState();
}

class _DoctorEncounterProceduresTabState extends State<DoctorEncounterProceduresTab> {
  final _encounterService = EncounterService();
  final _procedureTypeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();
  bool _consentConfirmed = false;
  bool _saving = false;
  List<Map<String, String>> _procedures = [];
  bool _loaded = false;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void dispose() {
    _procedureTypeCtrl.dispose();
    _notesCtrl.dispose();
    _complicationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc?.proceduresJson != null && enc!.proceduresJson!.isNotEmpty) {
        final list = jsonDecode(enc.proceduresJson!) as List;
        _procedures = list.map((e) => Map<String, String>.from(e as Map)).toList();
      }
      setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _addProcedure() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    final type = _procedureTypeCtrl.text.trim();
    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure type is required')),
      );
      return;
    }
    if (!_consentConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm consent')),
      );
      return;
    }
    setState(() => _saving = true);
    _procedures.add({
      'type': type,
      'consent': 'Yes',
      'notes': _notesCtrl.text.trim(),
      'complications': _complicationsCtrl.text.trim(),
    });
    try {
      await _encounterService.update(scope.encounterId, {
        'proceduresJson': jsonEncode(_procedures),
      });
      if (!mounted) return;
      _procedureTypeCtrl.clear();
      _notesCtrl.clear();
      _complicationsCtrl.clear();
      setState(() {
        _consentConfirmed = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure saved')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
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

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _procedureTypeCtrl,
            decoration: const InputDecoration(
              labelText: 'Procedure type',
              hintText: 'e.g. Suturing, I&D, Injection',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _consentConfirmed,
            title: const Text('Consent confirmed'),
            onChanged: (v) => setState(() => _consentConfirmed = v ?? false),
          ),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _complicationsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Complications (if any)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _addProcedure,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Save procedure'),
          ),
          const SizedBox(height: 24),
          if (_procedures.isNotEmpty) ...[
            Text('Recorded procedures', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._procedures.map((p) => Card(
                  child: ListTile(
                    title: Text(p['type'] ?? ''),
                    subtitle: Text('${p['notes'] ?? ""} ${p['complications']?.isNotEmpty == true ? "• Complications: ${p['complications']}" : ""}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
