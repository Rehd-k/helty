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
class ObstetricsAddPostnatalVisitScreen extends ConsumerStatefulWidget {
  final String labourDeliveryId;

  const ObstetricsAddPostnatalVisitScreen({
    super.key,
    required this.labourDeliveryId,
  });

  @override
  ConsumerState<ObstetricsAddPostnatalVisitScreen> createState() =>
      _ObstetricsAddPostnatalVisitScreenState();
}

class _ObstetricsAddPostnatalVisitScreenState
    extends ConsumerState<ObstetricsAddPostnatalVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _uterusInvolutionCtrl = TextEditingController();
  final _lochiaCtrl = TextEditingController();
  final _perineumCtrl = TextEditingController();
  final _bloodPressureCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _breastfeedingCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _feedingCtrl = TextEditingController();
  final _jaundiceCtrl = TextEditingController();
  final _immunisationCtrl = TextEditingController();

  List<Staff> _staffList = [];
  String? _selectedStaffId;
  PostnatalVisitType? _type = PostnatalVisitType.MOTHER;
  String? _patientId;
  String? _babyId;
  List<Baby> _babies = [];
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
      final staffList = await _staffService.fetchStaff(limit: 100);
      final delivery = await _obstetrics.getLabourDelivery(widget.labourDeliveryId);
      final babiesRes = await _obstetrics.listBabies(
        labourDeliveryId: widget.labourDeliveryId,
      );
      if (!mounted) return;
      final pregnancy = await _obstetrics.getPregnancy(delivery.pregnancyId);
      setState(() {
        _staffList = staffList;
        _babies = babiesRes.babies;
        _patientId = pregnancy.patientId;
        _selectedStaffId = ref.read(authProvider).staff?.id;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _visitDateCtrl.dispose();
    _notesCtrl.dispose();
    _uterusInvolutionCtrl.dispose();
    _lochiaCtrl.dispose();
    _perineumCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _temperatureCtrl.dispose();
    _breastfeedingCtrl.dispose();
    _weightCtrl.dispose();
    _feedingCtrl.dispose();
    _jaundiceCtrl.dispose();
    _immunisationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _visitDateCtrl.text = date.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedStaffId == null) {
      setState(() => _error = 'Select staff.');
      return;
    }
    if (_type == PostnatalVisitType.MOTHER && _patientId == null) {
      setState(() => _error = 'Mother patient ID not available.');
      return;
    }
    if (_type == PostnatalVisitType.BABY && _babyId == null) {
      setState(() => _error = 'Select baby.');
      return;
    }
    final visitDate = _visitDateCtrl.text.trim();
    if (visitDate.isEmpty) {
      setState(() => _error = 'Visit date is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'labourDeliveryId': widget.labourDeliveryId,
        'type': _type!.apiValue,
        'visitDate': visitDate,
        'staffId': _selectedStaffId!,
        if (_type == PostnatalVisitType.MOTHER) 'patientId': _patientId,
        if (_type == PostnatalVisitType.BABY) 'babyId': _babyId,
        if (_uterusInvolutionCtrl.text.trim().isNotEmpty)
          'uterusInvolution': _uterusInvolutionCtrl.text.trim(),
        if (_lochiaCtrl.text.trim().isNotEmpty)
          'lochia': _lochiaCtrl.text.trim(),
        if (_perineumCtrl.text.trim().isNotEmpty)
          'perineum': _perineumCtrl.text.trim(),
        if (_bloodPressureCtrl.text.trim().isNotEmpty)
          'bloodPressure': _bloodPressureCtrl.text.trim(),
        if (_temperatureCtrl.text.trim().isNotEmpty)
          'temperature': double.tryParse(_temperatureCtrl.text.trim()),
        if (_breastfeedingCtrl.text.trim().isNotEmpty)
          'breastfeeding': _breastfeedingCtrl.text.trim(),
        if (_weightCtrl.text.trim().isNotEmpty)
          'weight': double.tryParse(_weightCtrl.text.trim()),
        if (_feedingCtrl.text.trim().isNotEmpty)
          'feeding': _feedingCtrl.text.trim(),
        if (_jaundiceCtrl.text.trim().isNotEmpty)
          'jaundice': _jaundiceCtrl.text.trim(),
        if (_immunisationCtrl.text.trim().isNotEmpty)
          'immunisationGiven': _immunisationCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      };
      await _obstetrics.createPostnatalVisit(body);
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postnatal visit added.')),
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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add postnatal visit')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add postnatal visit'),
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
            DropdownButtonFormField<PostnatalVisitType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type *',
                border: OutlineInputBorder(),
              ),
              items: PostnatalVisitType.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 16),
            if (_type == PostnatalVisitType.BABY) ...[
              DropdownButtonFormField<String>(
                value: _babyId,
                decoration: const InputDecoration(
                  labelText: 'Baby *',
                  border: OutlineInputBorder(),
                ),
                items: _babies
                    .map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(
                              'Baby ${b.birthOrder} · ${b.sex.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _babyId = v),
              ),
              const SizedBox(height: 16),
            ],
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
            if (_type == PostnatalVisitType.MOTHER) ...[
              TextFormField(
                controller: _uterusInvolutionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Uterus involution',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lochiaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lochia',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _perineumCtrl,
                decoration: const InputDecoration(
                  labelText: 'Perineum',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodPressureCtrl,
                decoration: const InputDecoration(
                  labelText: 'Blood pressure',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _temperatureCtrl,
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breastfeedingCtrl,
                decoration: const InputDecoration(
                  labelText: 'Breastfeeding',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_type == PostnatalVisitType.BABY) ...[
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
                controller: _feedingCtrl,
                decoration: const InputDecoration(
                  labelText: 'Feeding',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jaundiceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jaundice',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _immunisationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Immunisation given',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
                  : const Text('Save visit'),
            ),
          ],
        ),
      ),
    );
  }
}
