import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/icd10_model.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/icd10_service.dart';

@RoutePage()
class DoctorEncounterDiagnosisTab extends StatefulWidget {
  const DoctorEncounterDiagnosisTab({super.key});

  /// Stored as [Icd10Model.code] when the doctor enters a narrative diagnosis
  /// instead of choosing an ICD-10 row.
  static const String customDiagnosisCode = 'OTHER';

  @override
  State<DoctorEncounterDiagnosisTab> createState() =>
      _DoctorEncounterDiagnosisTabState();
}

class _DoctorEncounterDiagnosisTabState
    extends State<DoctorEncounterDiagnosisTab> {
  final _encounterService = EncounterService();
  final _icd10Service = Icd10Service();
  final _primarySearchCtrl = TextEditingController();

  Icd10Model? _primary;
  final List<Icd10Model> _secondaries = [];
  List<Icd10Model> _searchResults = [];
  bool _searching = false;
  bool _loading = false;
  bool _loaded = false;
  bool _saving = false;
  bool _draftLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftLoadScheduled) {
      _draftLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDraft();
      });
    }
  }

  @override
  void dispose() {
    _primarySearchCtrl.dispose();
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
        if (enc.primaryIcdCode != null && enc.primaryIcdDescription != null) {
          _primary = Icd10Model(
            code: enc.primaryIcdCode!,
            description: enc.primaryIcdDescription!,
          );
        }
        if (enc.secondaryDiagnosesJson != null &&
            enc.secondaryDiagnosesJson!.isNotEmpty) {
          try {
            final list = jsonDecode(enc.secondaryDiagnosesJson!) as List;
            _secondaries.clear();
            for (final e in list) {
              final m = e as Map<String, dynamic>;
              _secondaries.add(
                Icd10Model(
                  code: m['code'] as String,
                  description: m['description'] as String? ?? '',
                ),
              );
            }
          } catch (_) {}
        }
      }
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    final results = await _icd10Service.search(q);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  Future<void> _save() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    if (_primary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary diagnosis is required (ICD-10 or Other)'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final secondaryJson = jsonEncode(
        _secondaries
            .map((e) => {'code': e.code, 'description': e.description})
            .toList(),
      );

      await _encounterService.saveDiagnosis(scope.encounterId, {
        'primaryIcdCode': _primary!.code,
        'primaryIcdDescription': _primary!.description,
        'secondaryDiagnosesJson': secondaryJson,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diagnosis saved')));
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Primary diagnosis (required)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _primarySearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search ICD-10 by code or description',
              prefixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (v) => _runSearch(v),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomPrimaryDialog(context),
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: const Text('Other — custom diagnosis'),
            ),
          ),
          if (_primary != null) ...[
            const SizedBox(height: 8),
            ListTile(
              tileColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                _primary!.code == DoctorEncounterDiagnosisTab.customDiagnosisCode
                    ? 'Custom diagnosis'
                    : _primary!.code,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              subtitle: Text(_primary!.description),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _primary = null),
              ),
            ),
          ],
          if (_searchResults.isNotEmpty && _primary == null) ...[
            const SizedBox(height: 8),
            ..._searchResults
                .take(8)
                .map(
                  (e) => ListTile(
                    title: Text(
                      e.code,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      e.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() {
                      _primary = e;
                      _primarySearchCtrl.clear();
                      _searchResults = [];
                    }),
                  ),
                ),
          ],
          const SizedBox(height: 24),
          Text(
            'Secondary diagnoses (optional)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ..._secondaries.map(
            (e) => ListTile(
              title: Text(
                e.code == DoctorEncounterDiagnosisTab.customDiagnosisCode
                    ? e.description
                    : '${e.code} — ${e.description}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => _secondaries.remove(e)),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showAddSecondary(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add secondary diagnosis (ICD-10)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showCustomSecondaryDialog(context),
            icon: const Icon(Icons.edit_note_outlined, size: 18),
            label: const Text('Other — custom secondary'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save diagnosis'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSecondary(BuildContext context) async {
    Icd10Model? selected;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        List<Icd10Model> results = [];
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add secondary diagnosis (ICD-10)'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search ICD-10',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) async {
                        final r = await _icd10Service.search(v);
                        setDialogState(() => results = r);
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.take(6).length,
                        itemBuilder: (_, i) {
                          final e = results[i];
                          return ListTile(
                            title: Text(e.code),
                            subtitle: Text(
                              e.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              selected = e;
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _secondaries.add(selected!));
    }
  }

  Future<void> _showCustomPrimaryDialog(BuildContext context) async {
    final ctrl = TextEditingController(
      text: _primary?.code == DoctorEncounterDiagnosisTab.customDiagnosisCode
          ? _primary!.description
          : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom primary diagnosis'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Diagnosis (free text)',
              hintText: 'Describe the diagnosis in your own words',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Use this diagnosis'),
          ),
        ],
      ),
    );
    final text = ctrl.text.trim();
    // Dialog route may still be animating; defer dispose until after the field
    // is detached so the TextField does not touch a disposed controller.
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (ok != true || !mounted) {
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a diagnosis description')),
      );
      return;
    }
    setState(() {
      _primary = Icd10Model(
        code: DoctorEncounterDiagnosisTab.customDiagnosisCode,
        description: text,
      );
      _primarySearchCtrl.clear();
      _searchResults = [];
    });
  }

  Future<void> _showCustomSecondaryDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom secondary diagnosis'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Diagnosis (free text)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final text = ctrl.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (ok != true || !mounted) {
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a diagnosis description')),
      );
      return;
    }
    setState(() {
      _secondaries.add(
        Icd10Model(
          code: DoctorEncounterDiagnosisTab.customDiagnosisCode,
          description: text,
        ),
      );
    });
  }
}
