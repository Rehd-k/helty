import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/staff_service.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

@RoutePage()
class ObstetricsAddLabourDeliveryScreen extends ConsumerStatefulWidget {
  final String pregnancyId;

  const ObstetricsAddLabourDeliveryScreen({
    super.key,
    required this.pregnancyId,
  });

  @override
  ConsumerState<ObstetricsAddLabourDeliveryScreen> createState() =>
      _ObstetricsAddLabourDeliveryScreenState();
}

class _ObstetricsAddLabourDeliveryScreenState
    extends ConsumerState<ObstetricsAddLabourDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deliveryDateTimeCtrl = TextEditingController();
  final _bloodLossCtrl = TextEditingController();
  final _perinealTearGradeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Staff> _staffList = [];
  String? _deliveredById;
  DeliveryMode? _mode;
  DeliveryOutcome? _outcome;
  bool? _placentaComplete;
  bool? _episiotomy;
  bool _loadingStaff = true;
  bool _saving = false;
  String? _error;

  ObstetricsService get _obstetrics => ref.read(obstetricsServiceProvider);
  StaffService get _staffService => StaffService();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final list = await _staffService.fetchStaff(limit: 100);
      if (!mounted) return;
      setState(() {
        _staffList = list;
        _loadingStaff = false;
        _deliveredById ??= ref.read(authProvider).staff?.id;
        _mode ??= DeliveryMode.SVD;
        _outcome ??= DeliveryOutcome.LIVE_BIRTH;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStaff = false);
    }
  }

  @override
  void dispose() {
    _deliveryDateTimeCtrl.dispose();
    _bloodLossCtrl.dispose();
    _perinealTearGradeCtrl.dispose();
    _notesCtrl.dispose();
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
    _deliveryDateTimeCtrl.text = dt.toIso8601String();
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_deliveredById == null || _deliveredById!.isEmpty) {
      setState(() => _error = 'Please select delivered by.');
      return;
    }
    if (_mode == null || _outcome == null) {
      setState(() => _error = 'Mode and outcome are required.');
      return;
    }
    final dateTime = _deliveryDateTimeCtrl.text.trim();
    if (dateTime.isEmpty) {
      setState(() => _error = 'Delivery date & time is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final delivery = await _obstetrics.createLabourDelivery(
        widget.pregnancyId,
        {
          'deliveryDateTime': dateTime,
          'mode': _mode!.apiValue,
          'outcome': _outcome!.apiValue,
          'deliveredById': _deliveredById!,
          if (_bloodLossCtrl.text.trim().isNotEmpty)
            'bloodLossMl': int.tryParse(_bloodLossCtrl.text.trim()),
          if (_placentaComplete != null) 'placentaComplete': _placentaComplete,
          if (_episiotomy != null) 'episiotomy': _episiotomy,
          if (_perinealTearGradeCtrl.text.trim().isNotEmpty)
            'perinealTearGrade': _perinealTearGradeCtrl.text.trim(),
          if (_notesCtrl.text.trim().isNotEmpty)
            'notes': _notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      context.router.maybePop(true);
      context.router.push(
        ObstetricsLabourDeliveryViewRoute(labourDeliveryId: delivery.id),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delivery recorded.')));
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
    return ObstetricsFormScaffold(
      title: 'Record delivery',
      subtitle: 'Capture mode, outcome, and delivery details.',
      formKey: _formKey,
      contextBanner: ObFormContextBanner(
        title: 'Delivery record',
        lines: ['Pregnancy: ${widget.pregnancyId}'],
        icon: Icons.local_hospital_rounded,
      ),
      error: _error,
      saving: _saving,
      saveLabel: 'Save delivery',
      onSave: () {
        _submit();
      },
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      children: [
        ObFormSectionCard(
          title: 'Delivery details',
          icon: Icons.local_hospital_rounded,
          children: [
            TextFormField(
              controller: _deliveryDateTimeCtrl,
              decoration: InputDecoration(
                labelText: 'Delivery date & time *',
                hintText: 'YYYY-MM-DDTHH:mm:ss',
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
            DropdownButtonFormField<DeliveryMode>(
              initialValue: _mode,
              decoration: const InputDecoration(
                labelText: 'Mode *',
                border: OutlineInputBorder(),
              ),
              items: DeliveryMode.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _mode = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DeliveryOutcome>(
              initialValue: _outcome,
              decoration: const InputDecoration(
                labelText: 'Outcome *',
                border: OutlineInputBorder(),
              ),
              items: DeliveryOutcome.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _outcome = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _deliveredById,
              decoration: const InputDecoration(
                labelText: 'Delivered by *',
                border: OutlineInputBorder(),
              ),
              items: _staffList
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.fullName),
                    ),
                  )
                  .toList(),
              onChanged: _loadingStaff
                  ? null
                  : (v) => setState(() => _deliveredById = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bloodLossCtrl,
              decoration: const InputDecoration(
                labelText: 'Blood loss (ml)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              initialValue: _placentaComplete,
              decoration: const InputDecoration(
                labelText: 'Placenta complete',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('—')),
                DropdownMenuItem(value: true, child: Text('Yes')),
                DropdownMenuItem(value: false, child: Text('No')),
              ],
              onChanged: (v) => setState(() => _placentaComplete = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<bool>(
              initialValue: _episiotomy,
              decoration: const InputDecoration(
                labelText: 'Episiotomy',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('—')),
                DropdownMenuItem(value: true, child: Text('Yes')),
                DropdownMenuItem(value: false, child: Text('No')),
              ],
              onChanged: (v) => setState(() => _episiotomy = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _perinealTearGradeCtrl,
              decoration: const InputDecoration(
                labelText: 'Perineal tear grade',
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
          ],
        ),
      ],
    );
  }
}
