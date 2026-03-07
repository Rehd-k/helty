import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/staff_service.dart';

const List<String> _procedureTypes = [
  'D&C',
  'HYSTERECTOMY',
  'MYOMECTOMY',
  'LAPAROSCOPY',
  'LAPAROTOMY',
  'COLPOSCOPY',
  'OTHER',
];

@RoutePage()
class ObstetricsAddGynaeProcedureScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const ObstetricsAddGynaeProcedureScreen({
    super.key,
    this.patientId,
  });

  @override
  ConsumerState<ObstetricsAddGynaeProcedureScreen> createState() =>
      _ObstetricsAddGynaeProcedureScreenState();
}

class _ObstetricsAddGynaeProcedureScreenState
    extends ConsumerState<ObstetricsAddGynaeProcedureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _procedureDateCtrl = TextEditingController();
  final _findingsCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _patientIdCtrl = TextEditingController();

  List<Staff> _staffList = [];
  String? _selectedSurgeonId;
  String? _procedureType;
  bool _loadingStaff = true;
  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);
  StaffService get _staffService => StaffService();

  @override
  void initState() {
    super.initState();
    _patientIdCtrl.text = widget.patientId ?? '';
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final list = await _staffService.fetchStaff(limit: 100);
      if (!mounted) return;
      setState(() {
        _staffList = list;
        _loadingStaff = false;
        _selectedSurgeonId ??= ref.read(authProvider).staff?.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStaff = false);
    }
  }

  @override
  void dispose() {
    _procedureDateCtrl.dispose();
    _findingsCtrl.dispose();
    _complicationsCtrl.dispose();
    _notesCtrl.dispose();
    _patientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _procedureDateCtrl.text = dt.toIso8601String();
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final patientId = _patientIdCtrl.text.trim();
    if (patientId.isEmpty) {
      setState(() => _error = 'Patient ID is required.');
      return;
    }
    if (_selectedSurgeonId == null) {
      setState(() => _error = 'Select surgeon.');
      return;
    }
    if (_procedureType == null || _procedureType!.isEmpty) {
      setState(() => _error = 'Procedure type is required.');
      return;
    }
    final procedureDate = _procedureDateCtrl.text.trim();
    if (procedureDate.isEmpty) {
      setState(() => _error = 'Procedure date is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _obstetrics.createGynaeProcedure({
        'patientId': patientId,
        'procedureType': _procedureType!,
        'procedureDate': procedureDate,
        'surgeonId': _selectedSurgeonId!,
        if (_findingsCtrl.text.trim().isNotEmpty)
          'findings': _findingsCtrl.text.trim(),
        if (_complicationsCtrl.text.trim().isNotEmpty)
          'complications': _complicationsCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty)
          'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure added.')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add gynae procedure'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            TextFormField(
              controller: _patientIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Patient ID *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _procedureType,
              decoration: const InputDecoration(
                labelText: 'Procedure type *',
                border: OutlineInputBorder(),
              ),
              items: _procedureTypes
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _procedureType = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _procedureDateCtrl,
              decoration: InputDecoration(
                labelText: 'Procedure date & time *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSurgeonId,
              decoration: const InputDecoration(
                labelText: 'Surgeon *',
                border: OutlineInputBorder(),
              ),
              items: _staffList
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.fullName),
                      ))
                  .toList(),
              onChanged: _loadingStaff ? null : (v) => setState(() => _selectedSurgeonId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _findingsCtrl,
              decoration: const InputDecoration(
                labelText: 'Findings',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complicationsCtrl,
              decoration: const InputDecoration(
                labelText: 'Complications',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save procedure'),
            ),
          ],
        ),
      ),
    );
  }
}
