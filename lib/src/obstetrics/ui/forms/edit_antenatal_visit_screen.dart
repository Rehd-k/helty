import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/obstetrics/ui/widgets/antenatal_visit_form_fields.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';
import 'package:helty/src/obstetrics/utils/obstetrics_display.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/staff_service.dart';

@RoutePage()
class ObstetricsEditAntenatalVisitScreen extends ConsumerStatefulWidget {
  final String visitId;

  const ObstetricsEditAntenatalVisitScreen({super.key, required this.visitId});

  @override
  ConsumerState<ObstetricsEditAntenatalVisitScreen> createState() =>
      _ObstetricsEditAntenatalVisitScreenState();
}

class _ObstetricsEditAntenatalVisitScreenState
    extends ConsumerState<ObstetricsEditAntenatalVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitDateCtrl = TextEditingController();
  final _gestationWeeksCtrl = TextEditingController();
  final _gestationDaysCtrl = TextEditingController();
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fundalHeightCtrl = TextEditingController();
  final _fetalHeartRateCtrl = TextEditingController();
  final _pcvCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _ultrasoundCtrl = TextEditingController();

  List<Staff> _staffList = [];
  String? _selectedStaffId;
  FetalPresentation? _presentation;
  String? _descent;
  String? _urineProtein;
  String? _urineGlucose;
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

      AntenatalVisitFormHelpers.loadVisitDateTime(visit, _visitDateCtrl);
      AntenatalVisitFormHelpers.loadGestationalAge(
        visit,
        weeksController: _gestationWeeksCtrl,
        daysController: _gestationDaysCtrl,
      );
      _systolicCtrl.text = visit.systolicBP?.toString() ?? '';
      _diastolicCtrl.text = visit.diastolicBP?.toString() ?? '';
      _weightCtrl.text = visit.weight?.toString() ?? '';
      _fundalHeightCtrl.text = visit.fundalHeight?.toString() ?? '';
      _fetalHeartRateCtrl.text = visit.fetalHeartRate?.toString() ?? '';
      _pcvCtrl.text = visit.pcv?.toString() ?? '';
      _notesCtrl.text = visit.notes ?? '';
      _ultrasoundCtrl.text = visit.ultrasoundFindings ?? '';

      setState(() {
        _selectedStaffId = visit.staffId;
        _presentation = visit.presentation;
        _descent = visit.descent;
        _urineProtein = AntenatalVisitFetalAssessmentFields.matchDipstickOption(
          visit.urineProtein,
        ) ?? visit.urineProtein;
        _urineGlucose = AntenatalVisitFetalAssessmentFields.matchDipstickOption(
          visit.urineGlucose,
        ) ?? visit.urineGlucose;
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
    _gestationDaysCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _weightCtrl.dispose();
    _fundalHeightCtrl.dispose();
    _fetalHeartRateCtrl.dispose();
    _pcvCtrl.dispose();
    _notesCtrl.dispose();
    _ultrasoundCtrl.dispose();
    super.dispose();
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
      await _obstetrics.updateAntenatalVisit(
        widget.visitId,
        buildAntenatalVisitPayload(
          visitDate: _visitDateCtrl.text.trim(),
          staffId: staffId,
          gestationWeeksController: _gestationWeeksCtrl,
          gestationDaysController: _gestationDaysCtrl,
          systolicController: _systolicCtrl,
          diastolicController: _diastolicCtrl,
          weightController: _weightCtrl,
          fundalHeightController: _fundalHeightCtrl,
          fetalHeartRateController: _fetalHeartRateCtrl,
          presentation: _presentation,
          descent: _descent,
          urineProtein: _urineProtein,
          urineGlucose: _urineGlucose,
          pcvController: _pcvCtrl,
          notesController: _notesCtrl,
          ultrasoundController: _ultrasoundCtrl,
          includeEmptyStrings: true,
        ),
      );
      if (!mounted) return;
      context.router.maybePop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Visit updated.')));
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
    if (_loading && _visitDateCtrl.text.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit antenatal visit')),
        body: ResponsiveBody(
          builder: (context, bp) => const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final scopePregnancy = PregnancyViewScope.of(context)?.pregnancy;
    final patientContext = scopePregnancy != null
        ? '${pregnancyGpLabel(scopePregnancy)} · Updated antenatal data'
        : 'Visit ${widget.visitId}';

    return ObstetricsFormScaffold(
      title: 'Edit antenatal visit',
      subtitle: 'Update vitals, presentation, and notes.',
      formKey: _formKey,
      error: _error,
      saving: _saving,
      saveLabel: 'Update visit',
      onSave: _submit,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.router.maybePop(),
      ),
      contextBanner: ObFormContextBanner(
        title: 'Antenatal visit',
        lines: [patientContext],
        icon: Icons.medical_services_rounded,
      ),
      children: [
        ResponsiveBody(
          center: false,
          bottomPadding: 0,
          builder: (context, bp) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AntenatalVisitVitalsFields(
          visitDateController: _visitDateCtrl,
          gestationWeeksController: _gestationWeeksCtrl,
          gestationDaysController: _gestationDaysCtrl,
          systolicController: _systolicCtrl,
          diastolicController: _diastolicCtrl,
          weightController: _weightCtrl,
          fundalHeightController: _fundalHeightCtrl,
          fetalHeartRateController: _fetalHeartRateCtrl,
          staffList: _staffList,
          selectedStaffId: _selectedStaffId,
          onStaffChanged: (v) => setState(() => _selectedStaffId = v),
        ),
        AntenatalVisitFetalAssessmentFields(
          presentation: _presentation,
          onPresentationChanged: (v) => setState(() => _presentation = v),
          descent: _descent,
          onDescentChanged: (v) => setState(() => _descent = v),
          urineProtein: _urineProtein,
          onUrineProteinChanged: (v) => setState(() => _urineProtein = v),
          urineGlucose: _urineGlucose,
          onUrineGlucoseChanged: (v) => setState(() => _urineGlucose = v),
          pcvController: _pcvCtrl,
          notesController: _notesCtrl,
          ultrasoundController: _ultrasoundCtrl,
        ),
            ],
          ),
        ),
      ],
    );
  }
}
