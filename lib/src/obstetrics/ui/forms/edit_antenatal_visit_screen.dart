import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/staff_service.dart';

@RoutePage()
class ObstetricsEditAntenatalVisitScreen extends ConsumerStatefulWidget {
  final String visitId;

  const ObstetricsEditAntenatalVisitScreen({
    super.key,
    required this.visitId,
  });

  @override
  ConsumerState<ObstetricsEditAntenatalVisitScreen> createState() =>
      _ObstetricsEditAntenatalVisitScreenState();
}

class _ObstetricsEditAntenatalVisitScreenState
    extends ConsumerState<ObstetricsEditAntenatalVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitDateCtrl = TextEditingController();
  final _gestationWeeksCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fundalHeightCtrl = TextEditingController();
  final _fetalHeartRateCtrl = TextEditingController();
  final _urineProteinCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _ultrasoundCtrl = TextEditingController();

  List<Staff> _staffList = [];
  String? _selectedStaffId;
  FetalPresentation? _presentation;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);
  StaffService get _staffService => StaffService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final visit = await _obstetrics.getAntenatalVisit(widget.visitId);
      final list = await _staffService.fetchStaff(limit: 100);
      if (!mounted) return;
      _visitDateCtrl.text = visit.visitDate;
      _gestationWeeksCtrl.text = visit.gestationWeeks?.toString() ?? '';
      _systolicCtrl.text = visit.systolicBP?.toString() ?? '';
      _diastolicCtrl.text = visit.diastolicBP?.toString() ?? '';
      _weightCtrl.text = visit.weight?.toString() ?? '';
      _fundalHeightCtrl.text = visit.fundalHeight?.toString() ?? '';
      _fetalHeartRateCtrl.text = visit.fetalHeartRate?.toString() ?? '';
      _urineProteinCtrl.text = visit.urineProtein ?? '';
      _notesCtrl.text = visit.notes ?? '';
      _ultrasoundCtrl.text = visit.ultrasoundFindings ?? '';
      setState(() {
        _selectedStaffId = visit.staffId;
        _presentation = visit.presentation;
        _staffList = list;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  @override
  void dispose() {
    _visitDateCtrl.dispose();
    _gestationWeeksCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _weightCtrl.dispose();
    _fundalHeightCtrl.dispose();
    _fetalHeartRateCtrl.dispose();
    _urineProteinCtrl.dispose();
    _notesCtrl.dispose();
    _ultrasoundCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      _visitDateCtrl.text = date.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final staffId = _selectedStaffId ?? ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      setState(() => _error = 'Please select staff.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _obstetrics.updateAntenatalVisit(widget.visitId, {
        'visitDate': _visitDateCtrl.text.trim(),
        'staffId': staffId,
        if (_gestationWeeksCtrl.text.trim().isNotEmpty)
          'gestationWeeks': double.tryParse(_gestationWeeksCtrl.text.trim()),
        if (_systolicCtrl.text.trim().isNotEmpty)
          'systolicBP': int.tryParse(_systolicCtrl.text.trim()),
        if (_diastolicCtrl.text.trim().isNotEmpty)
          'diastolicBP': int.tryParse(_diastolicCtrl.text.trim()),
        if (_weightCtrl.text.trim().isNotEmpty)
          'weight': double.tryParse(_weightCtrl.text.trim()),
        if (_fundalHeightCtrl.text.trim().isNotEmpty)
          'fundalHeight': double.tryParse(_fundalHeightCtrl.text.trim()),
        if (_fetalHeartRateCtrl.text.trim().isNotEmpty)
          'fetalHeartRate': int.tryParse(_fetalHeartRateCtrl.text.trim()),
        if (_presentation != null) 'presentation': _presentation!.apiValue,
        'urineProtein': _urineProteinCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'ultrasoundFindings': _ultrasoundCtrl.text.trim(),
      });
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit updated.')),
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

    if (_loading && _visitDateCtrl.text.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit antenatal visit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit antenatal visit'),
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
              controller: _visitDateCtrl,
              decoration: InputDecoration(
                labelText: 'Visit date *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStaffId,
              decoration: const InputDecoration(
                labelText: 'Staff *',
                border: OutlineInputBorder(),
              ),
              items: _staffList
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.fullName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedStaffId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gestationWeeksCtrl,
              decoration: const InputDecoration(
                labelText: 'Gestation (weeks)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Systolic BP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic BP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fundalHeightCtrl,
              decoration: const InputDecoration(
                labelText: 'Fundal height (cm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fetalHeartRateCtrl,
              decoration: const InputDecoration(
                labelText: 'Fetal heart rate',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FetalPresentation>(
              value: _presentation,
              decoration: const InputDecoration(
                labelText: 'Presentation',
                border: OutlineInputBorder(),
              ),
              items: FetalPresentation.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _presentation = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urineProteinCtrl,
              decoration: const InputDecoration(
                labelText: 'Urine protein',
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _ultrasoundCtrl,
              decoration: const InputDecoration(
                labelText: 'Ultrasound findings',
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
                  : const Text('Update visit'),
            ),
          ],
        ),
      ),
    );
  }
}
