import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';
import 'package:helty/src/obstetrics/ui/widgets/pregnancy_booking_form_fields.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsAddPregnancyScreen extends ConsumerStatefulWidget {
  /// When null or empty, patientId is taken from [patientProvider].selectedPatient.
  final String? patientId;

  const ObstetricsAddPregnancyScreen({super.key, this.patientId});

  @override
  ConsumerState<ObstetricsAddPregnancyScreen> createState() =>
      _ObstetricsAddPregnancyScreenState();
}

class _ObstetricsAddPregnancyScreenState
    extends ConsumerState<ObstetricsAddPregnancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gravidaCtrl = TextEditingController(text: '1');
  final _paraCtrl = TextEditingController(text: '0');
  final _lmpCtrl = TextEditingController();
  final _eddCtrl = TextEditingController();
  final _bookingDateCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();
  final _respiratoryRateCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _pcvCtrl = TextEditingController();
  final _ttImmunizationCtrl = TextEditingController();

  PregnancyStatus? _status = PregnancyStatus.ONGOING;
  String? _genotype;
  String? _bloodGroup;
  String? _hcv;
  String? _hbsAg;
  String? _vdrl;
  String? _hiv12;
  String? _urinalysisProtein;
  String? _urinalysisGlucose;
  bool _saving = false;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  /// Prefer selectedPatient from state; fallback to widget.patientId (e.g. when opened from pregnancies list).
  String? get _effectivePatientId {
    final selected = ref.watch(patientProvider).selectedPatient;
    return (selected?.patientId.isNotEmpty == true
            ? selected!.patientId
            : selected?.id) ??
        (widget.patientId?.trim().isEmpty == false ? widget.patientId : null);
  }

  @override
  void initState() {
    super.initState();
    _lmpCtrl.addListener(_updateEddFromLmp);
  }

  void _updateEddFromLmp() {
    final raw = _lmpCtrl.text.trim();
    if (raw.isEmpty) return;
    try {
      final lmp = DateTime.parse(raw);
      // Standard 280-day gestation (40 weeks)
      final edd = lmp.add(const Duration(days: 280));
      final formatted = edd.toIso8601String().split('T').first;
      if (_eddCtrl.text != formatted) {
        _eddCtrl.text = formatted;
      }
    } catch (_) {
      // Ignore invalid formats and leave EDD unchanged
    }
  }

  @override
  void dispose() {
    _gravidaCtrl.dispose();
    _paraCtrl.dispose();
    _lmpCtrl.dispose();
    _eddCtrl.dispose();
    _bookingDateCtrl.dispose();
    _outcomeCtrl.dispose();
    _respiratoryRateCtrl.dispose();
    _heartRateCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _spo2Ctrl.dispose();
    _pcvCtrl.dispose();
    _ttImmunizationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    TextEditingController ctrl, {
    DateTime? initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      ctrl.text = date.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    _error = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final gravida = int.tryParse(_gravidaCtrl.text.trim());
    final para = int.tryParse(_paraCtrl.text.trim());
    if (gravida == null || gravida < 0) {
      setState(() => _error = 'Gravida must be a number ≥ 0.');
      return;
    }
    if (para == null || para < 0) {
      setState(() => _error = 'Para must be a number ≥ 0.');
      return;
    }
    final lmp = _lmpCtrl.text.trim();
    final edd = _eddCtrl.text.trim();
    if (lmp.isEmpty || edd.isEmpty) {
      setState(() => _error = 'LMP and EDD are required.');
      return;
    }
    final patientId = _effectivePatientId;
    if (patientId == null || patientId.isEmpty) {
      setState(() => _error = 'No patient selected. Select a patient first.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createPregnancy(
        buildPregnancyBookingPayload(
          patientId: patientId,
          gravida: gravida,
          para: para,
          lmp: lmp,
          edd: edd,
          bookingDateController: _bookingDateCtrl,
          status: _status,
          outcomeController: _outcomeCtrl,
          respiratoryRateController: _respiratoryRateCtrl,
          heartRateController: _heartRateCtrl,
          systolicController: _systolicCtrl,
          diastolicController: _diastolicCtrl,
          spo2Controller: _spo2Ctrl,
          genotype: _genotype,
          bloodGroup: _bloodGroup,
          pcvController: _pcvCtrl,
          hcv: _hcv,
          hbsAg: _hbsAg,
          vdrl: _vdrl,
          hiv12: _hiv12,
          urinalysisProtein: _urinalysisProtein,
          urinalysisGlucose: _urinalysisGlucose,
          ttImmunizationController: _ttImmunizationCtrl,
        ),
      );
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pregnancy added.')));
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
    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    final patientId = _effectivePatientId;

    if (patientId == null || patientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add pregnancy'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: ResponsiveBody(
          builder: (context, bp) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Select a patient to add a pregnancy.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return ObstetricsFormScaffold(
      title: 'Add pregnancy',
      subtitle: 'Create a new pregnancy record for the selected patient.',
      formKey: _formKey,
      contextBanner: ObFormContextBanner(
        title: selectedPatient != null
            ? selectedPatient.displayName.trim()
            : 'Selected patient',
        lines: ['Patient ID: $patientId'],
        icon: Icons.pregnant_woman_rounded,
      ),
      error: _error,
      saving: _saving,
      saveLabel: 'Save pregnancy',
      onSave: _saving ? null : _submit,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      children: [
        ResponsiveBody(
          center: false,
          bottomPadding: 0,
          builder: (context, bp) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ObFormSectionCard(
          title: 'Gravida & Para',
          icon: Icons.scale_rounded,
          children: [
            TextFormField(
              controller: _gravidaCtrl,
              decoration: const InputDecoration(
                labelText: 'Gravida *',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a number ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paraCtrl,
              decoration: const InputDecoration(
                labelText: 'Para *',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a number ≥ 0';
                return null;
              },
            ),
          ],
        ),
        ObFormSectionCard(
          title: 'Dates',
          icon: Icons.calendar_today_rounded,
          children: [
            TextFormField(
              controller: _lmpCtrl,
              decoration: InputDecoration(
                labelText: 'LMP (date) *',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_lmpCtrl),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eddCtrl,
              decoration: InputDecoration(
                labelText: 'EDD (date) *',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_eddCtrl),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bookingDateCtrl,
              decoration: InputDecoration(
                labelText: 'Booking date (optional)',
                hintText: 'YYYY-MM-DD',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(_bookingDateCtrl),
                ),
              ),
            ),
          ],
        ),
        PregnancyBookingVitalsFields(
          respiratoryRateController: _respiratoryRateCtrl,
          heartRateController: _heartRateCtrl,
          systolicController: _systolicCtrl,
          diastolicController: _diastolicCtrl,
          spo2Controller: _spo2Ctrl,
        ),
        PregnancyBookingBloodTypeFields(
          genotype: _genotype,
          onGenotypeChanged: (v) => setState(() => _genotype = v),
          bloodGroup: _bloodGroup,
          onBloodGroupChanged: (v) => setState(() => _bloodGroup = v),
        ),
        PregnancyBookingLaboratoryFields(
          pcvController: _pcvCtrl,
          hcv: _hcv,
          onHcvChanged: (v) => setState(() => _hcv = v),
          hbsAg: _hbsAg,
          onHbsAgChanged: (v) => setState(() => _hbsAg = v),
          vdrl: _vdrl,
          onVdrlChanged: (v) => setState(() => _vdrl = v),
          hiv12: _hiv12,
          onHiv12Changed: (v) => setState(() => _hiv12 = v),
          urinalysisProtein: _urinalysisProtein,
          onUrinalysisProteinChanged: (v) =>
              setState(() => _urinalysisProtein = v),
          urinalysisGlucose: _urinalysisGlucose,
          onUrinalysisGlucoseChanged: (v) =>
              setState(() => _urinalysisGlucose = v),
        ),
        ObFormSectionCard(
          title: 'Clinical',
          useTertiaryAccent: true,
          icon: Icons.medical_services_rounded,
          children: [
            DropdownButtonFormField<PregnancyStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: PregnancyStatus.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ttImmunizationCtrl,
              decoration: const InputDecoration(
                labelText: 'T-T immunization',
                hintText: 'e.g. TT1, TT2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outcomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Outcome (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
            ],
          ),
        ),
      ],
    );
  }
}
