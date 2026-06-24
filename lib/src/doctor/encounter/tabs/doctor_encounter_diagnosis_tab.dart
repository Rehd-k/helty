import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/doctor/encounter/encounter_tab_reload.dart';
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
  int _lastReloadGeneration = 0;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _primarySearchCtrl.dispose();
    super.dispose();
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is AppException) {
      return (e.error as AppException).message;
    }
    if (e is AppException) return e.message;
    return e.toString();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await _icd10Service.search(query, take: 20);
      if (!mounted) return;
      setState(() {
        _searchResults = page.items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      _showErrorSnackBar('ICD-10 search failed: ${_errorMessage(e)}');
    }
  }

  void _onPrimarySearchChanged(String v) {
    _searchDebounce?.cancel();
    final query = v.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchResults = [];
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(v),
    );
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

      await _encounterService.saveDiagnosis(
        scope.encounterId,
        {
          'primaryIcdCode': _primary!.code,
          'primaryIcdDescription': _primary!.description,
          'secondaryDiagnosesJson': secondaryJson,
        },
        editReason: amendEditReason(scope),
      );
      if (!mounted) return;
      showEncounterSaveSnackBar(
        context,
        scope: scope,
        ongoingMessage: 'Diagnosis saved',
      );
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      showEncounterEditErrorSnackBar(context, e);
      setState(() => _saving = false);
    }
  }

  Widget _icd10ResultTile(Icd10Model e, VoidCallback onTap) {
    final specialty = e.specialty?.trim();
    return ListTile(
      title: Text(
        e.displayLabel,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: specialty != null && specialty.isNotEmpty
          ? Text(specialty, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      onTap: onTap,
    );
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

    final showSearchHint =
        _primary == null &&
        _primarySearchCtrl.text.trim().isEmpty &&
        !_searching &&
        _searchResults.isEmpty;

    final readOnly = !scope.canEdit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AbsorbPointer(
        absorbing: readOnly,
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
            onChanged: _onPrimarySearchChanged,
          ),
          if (showSearchHint) ...[
            const SizedBox(height: 8),
            Text(
              'Type a code or description to search ICD-10',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
                _primary!.code ==
                        DoctorEncounterDiagnosisTab.customDiagnosisCode
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
            ..._searchResults.map(
              (e) => _icd10ResultTile(e, () {
                setState(() {
                  _primary = e;
                  _primarySearchCtrl.clear();
                  _searchResults = [];
                  _searching = false;
                });
              }),
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
                    : e.displayLabel,
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
          if (!readOnly)
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
      ),
    );
  }

  Future<void> _showAddSecondary(BuildContext context) async {
    final selected = await showDialog<Icd10Model>(
      context: context,
      builder: (ctx) => _AddSecondaryIcd10Dialog(icd10Service: _icd10Service),
    );
    if (selected != null && mounted) {
      setState(() => _secondaries.add(selected));
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
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (ok != true || !context.mounted) {
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
      _searching = false;
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
    if (ok != true || !context.mounted) {
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

class _AddSecondaryIcd10Dialog extends StatefulWidget {
  const _AddSecondaryIcd10Dialog({required this.icd10Service});

  final Icd10Service icd10Service;

  @override
  State<_AddSecondaryIcd10Dialog> createState() =>
      _AddSecondaryIcd10DialogState();
}

class _AddSecondaryIcd10DialogState extends State<_AddSecondaryIcd10Dialog> {
  final _searchCtrl = TextEditingController();
  List<Icd10Model> _results = [];
  bool _searching = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is AppException) {
      return (e.error as AppException).message;
    }
    if (e is AppException) return e.message;
    return e.toString();
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final page = await widget.icd10Service.search(query, take: 20);
      if (!mounted) return;
      setState(() {
        _results = page.items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ICD-10 search failed: ${_errorMessage(e)}')),
      );
    }
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    final query = v.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _results = [];
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showHint =
        _searchCtrl.text.trim().isEmpty && !_searching && _results.isEmpty;

    return AlertDialog(
      title: const Text('Add secondary diagnosis (ICD-10)'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search ICD-10 by code or description',
                border: const OutlineInputBorder(),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            if (showHint) ...[
              const SizedBox(height: 8),
              Text(
                'Type a code or description to search ICD-10',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: _results.isEmpty && !_searching
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final e = _results[i];
                        final specialty = e.specialty?.trim();
                        return ListTile(
                          title: Text(
                            e.displayLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: specialty != null && specialty.isNotEmpty
                              ? Text(
                                  specialty,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
