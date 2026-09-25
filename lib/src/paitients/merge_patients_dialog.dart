import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'patient_model.dart';
import 'patient_service.dart';

/// Full any-to-any merge (Super Admin) vs one-time → registered only (Front Desk / MR).
enum MergePatientsMode { full, unregisteredOnly }

class MergePatientsSelection {
  const MergePatientsSelection({
    required this.survivor,
    required this.duplicate,
  });

  final Patient survivor;
  final Patient duplicate;
}

bool patientHasHospitalId(Patient p) {
  final id = p.patientId.trim();
  if (id.isEmpty) return false;
  // One-time rows sometimes surface their UUID in patientId in list payloads.
  final uuid = p.id?.trim() ?? '';
  if (uuid.isNotEmpty && id == uuid) return false;
  return true;
}

String patientMergeLabel(Patient p) {
  final hospitalId = p.patientId.trim();
  if (!patientHasHospitalId(p)) {
    return '${p.displayName} · one-time (no hospital ID)';
  }
  return '${p.displayName} · $hospitalId';
}

/// Opens picker + confirm, then calls merge API. Returns the survivor on success.
Future<Patient?> runMergePatientsFlow(
  BuildContext context, {
  required MergePatientsMode mode,
  Patient? initialSurvivor,
  Patient? initialDuplicate,
}) async {
  final selection = await showDialog<MergePatientsSelection>(
    context: context,
    builder: (ctx) => MergePatientsDialog(
      mode: mode,
      initialSurvivor: initialSurvivor,
      initialDuplicate: initialDuplicate,
    ),
  );
  if (selection == null || !context.mounted) return null;

  final messenger = ScaffoldMessenger.of(context);
  final survivor = selection.survivor;
  final duplicate = selection.duplicate;
  final survivorUuid = survivor.id?.trim() ?? '';
  final duplicateUuid = duplicate.id?.trim() ?? '';
  if (survivorUuid.isEmpty || duplicateUuid.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Select both survivor and duplicate patients.'),
      ),
    );
    return null;
  }
  if (survivorUuid == duplicateUuid) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Survivor and duplicate must differ.')),
    );
    return null;
  }

  if (mode == MergePatientsMode.unregisteredOnly) {
    if (!patientHasHospitalId(survivor)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Registered patient (keep) must have a hospital ID.',
          ),
        ),
      );
      return null;
    }
    if (patientHasHospitalId(duplicate)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Only one-time patients (no hospital ID) can be linked.',
          ),
        ),
      );
      return null;
    }
  }

  final survivorLabel = patientMergeLabel(survivor);
  final duplicateLabel = patientMergeLabel(duplicate);
  final confirmTitle = mode == MergePatientsMode.unregisteredOnly
      ? 'Confirm link'
      : 'Confirm merge';
  final confirmBody = mode == MergePatientsMode.unregisteredOnly
      ? 'Link $duplicateLabel into $survivorLabel? '
            'All visits and bills move to the registered patient. This cannot be undone.'
      : 'Merge $duplicateLabel into $survivorLabel? This cannot be undone.';
  final confirmAction = mode == MergePatientsMode.unregisteredOnly
      ? 'Confirm link'
      : 'Confirm merge';

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(confirmTitle),
      content: Text(confirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmAction),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;

  try {
    final merged = await PatientService().mergePatients(
      survivorId: survivorUuid,
      duplicateId: duplicateUuid,
    );
    if (!context.mounted) return merged;
    final doneMsg = mode == MergePatientsMode.unregisteredOnly
        ? 'Linked into ${merged.displayName} (${merged.patientId}).'
        : 'Merged into ${merged.displayName} (${merged.patientId}).';
    messenger.showSnackBar(SnackBar(content: Text(doneMsg)));
    return merged;
  } on DioException catch (e) {
    if (!context.mounted) return null;
    final data = e.response?.data;
    var message = 'Merge failed.';
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      message = m is List ? m.join(', ') : m.toString();
    } else if (e.message != null && e.message!.trim().isNotEmpty) {
      message = e.message!.trim();
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return null;
  } catch (e) {
    if (!context.mounted) return null;
    messenger.showSnackBar(SnackBar(content: Text('Merge failed: $e')));
    return null;
  }
}

class MergePatientsDialog extends StatefulWidget {
  const MergePatientsDialog({
    super.key,
    this.mode = MergePatientsMode.full,
    this.initialSurvivor,
    this.initialDuplicate,
  });

  final MergePatientsMode mode;
  final Patient? initialSurvivor;
  final Patient? initialDuplicate;

  @override
  State<MergePatientsDialog> createState() => _MergePatientsDialogState();
}

class _MergePatientsDialogState extends State<MergePatientsDialog> {
  final _patientService = PatientService();
  late Patient? _survivor = widget.initialSurvivor;
  late Patient? _duplicate = widget.initialDuplicate;

  bool get _unregisteredOnly =>
      widget.mode == MergePatientsMode.unregisteredOnly;

  Future<List<Patient>> _searchRegistered(String query, bool ascending) async {
    final rows = await _patientService.searchPatients(query, ascending);
    return rows.where(patientHasHospitalId).toList();
  }

  Future<List<Patient>> _searchOneTime(String query, bool ascending) async {
    final rows = await _patientService.searchPatientsIncludingUnregistered(
      query,
      ascending,
    );
    return rows.where((p) => !patientHasHospitalId(p)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canMerge = _survivor != null && _duplicate != null;
    final title = _unregisteredOnly ? 'Link one-time patient' : 'Merge patients';
    final description = _unregisteredOnly
        ? 'Move all records from a one-time (no hospital ID) patient onto a registered patient, then remove the one-time record.'
        : 'Search by name or hospital patient ID. Reassign all records from the duplicate onto the survivor, then delete the duplicate. Survivor keeps their hospital ID and phone.';
    final survivorLabel = _unregisteredOnly
        ? 'Registered patient (keep)'
        : 'Survivor (keep)';
    final duplicateLabel = _unregisteredOnly
        ? 'One-time patient (merge into them)'
        : 'Duplicate (merge away)';
    final actionLabel = _unregisteredOnly ? 'Link' : 'Merge';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            MergePatientSearchPicker(
              label: survivorLabel,
              selected: _survivor,
              onSelected: (p) {
                if (_unregisteredOnly && !patientHasHospitalId(p)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Select a registered patient with a hospital ID.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _survivor = p);
              },
              onClear: () => setState(() => _survivor = null),
              search: _unregisteredOnly
                  ? _searchRegistered
                  : _patientService.searchPatients,
            ),
            const SizedBox(height: 12),
            MergePatientSearchPicker(
              label: duplicateLabel,
              selected: _duplicate,
              onSelected: (p) {
                if (_unregisteredOnly && patientHasHospitalId(p)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Select a one-time patient without a hospital ID.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _duplicate = p);
              },
              onClear: () => setState(() => _duplicate = null),
              search: _unregisteredOnly
                  ? _searchOneTime
                  : _patientService.searchPatientsIncludingUnregistered,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canMerge
              ? () => Navigator.pop(
                  context,
                  MergePatientsSelection(
                    survivor: _survivor!,
                    duplicate: _duplicate!,
                  ),
                )
              : null,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class MergePatientSearchPicker extends StatefulWidget {
  const MergePatientSearchPicker({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onClear,
    required this.search,
  });

  final String label;
  final Patient? selected;
  final ValueChanged<Patient> onSelected;
  final VoidCallback onClear;
  final Future<List<Patient>> Function(String query, bool isAscending) search;

  @override
  State<MergePatientSearchPicker> createState() =>
      _MergePatientSearchPickerState();
}

class _MergePatientSearchPickerState extends State<MergePatientSearchPicker> {
  final _controller = TextEditingController();
  List<Patient> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.search(q, true);
      if (!mounted) return;
      setState(() {
        _results = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    if (selected != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Clear',
            onPressed: widget.onClear,
            icon: const Icon(Icons.clear),
          ),
        ),
        child: Text(
          patientMergeLabel(selected),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Search name or patient ID',
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: () => _runSearch(_controller.text),
                    icon: const Icon(Icons.search),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) {
            if (v.trim().length >= 2) _runSearch(v);
          },
          onSubmitted: _runSearch,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: Material(
              type: MaterialType.transparency,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final p = _results[index];
                  return ListTile(
                    dense: true,
                    title: Text(p.displayName),
                    subtitle: Text(
                      patientHasHospitalId(p)
                          ? p.patientId
                          : 'One-time · no hospital ID',
                    ),
                    onTap: () {
                      widget.onSelected(p);
                      _controller.clear();
                      setState(() => _results = const []);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
