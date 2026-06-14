import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

/// Shared helpers for antenatal visit add/edit forms.
class AntenatalVisitFormHelpers {
  AntenatalVisitFormHelpers._();

  static Future<void> pickVisitDateTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final existing = _parseVisitDateTime(controller.text.trim());
    final initial = existing ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(existing ?? DateTime.now()),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    controller.text = dt.toIso8601String();
  }

  static DateTime? _parseVisitDateTime(String value) {
    if (value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static String formatVisitDateTimeForField(String? visitDate) {
    if (visitDate == null || visitDate.isEmpty) return '';
    final dt = _parseVisitDateTime(visitDate);
    if (dt == null) return visitDate;
    return DateFormatter.formatFromBackend(visitDate, DateFormatter.dateTime);
  }

  /// Populates gestation week/day controllers from a visit (handles legacy decimal weeks).
  static void loadGestationalAge(
    AntenatalVisit visit, {
    required TextEditingController weeksController,
    required TextEditingController daysController,
  }) {
    if (visit.gestationDays != null) {
      daysController.text = visit.gestationDays.toString();
    }

    if (visit.gestationWeeks != null) {
      final weeksValue = visit.gestationWeeks!;
      if (visit.gestationDays != null) {
        weeksController.text = weeksValue.truncate().toString();
      } else {
        final wholeWeeks = weeksValue.truncate();
        final fractionalDays = ((weeksValue - wholeWeeks) * 7).round();
        weeksController.text = wholeWeeks.toString();
        if (fractionalDays > 0 && daysController.text.isEmpty) {
          daysController.text = fractionalDays.toString();
        }
      }
    }
  }

  static void loadVisitDateTime(
    AntenatalVisit visit,
    TextEditingController controller,
  ) {
    if (visit.visitDate.isEmpty) return;
    final dt = _parseVisitDateTime(visit.visitDate);
    if (dt != null) {
      controller.text = dt.toIso8601String();
    } else {
      controller.text = visit.visitDate;
    }
  }
}

/// Visit date/time, staff, gestation, and vitals section.
class AntenatalVisitVitalsFields extends StatelessWidget {
  const AntenatalVisitVitalsFields({
    super.key,
    required this.visitDateController,
    required this.gestationWeeksController,
    required this.gestationDaysController,
    required this.systolicController,
    required this.diastolicController,
    required this.weightController,
    required this.fundalHeightController,
    required this.fetalHeartRateController,
    required this.staffList,
    required this.selectedStaffId,
    required this.onStaffChanged,
    this.loadingStaff = false,
  });

  final TextEditingController visitDateController;
  final TextEditingController gestationWeeksController;
  final TextEditingController gestationDaysController;
  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController weightController;
  final TextEditingController fundalHeightController;
  final TextEditingController fetalHeartRateController;
  final List<Staff> staffList;
  final String? selectedStaffId;
  final ValueChanged<String?> onStaffChanged;
  final bool loadingStaff;

  @override
  Widget build(BuildContext context) {
    return ObFormSectionCard(
      title: 'Visit & vitals',
      icon: Icons.event_note_rounded,
      children: [
        TextFormField(
          controller: visitDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Visit date & time *',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => AntenatalVisitFormHelpers.pickVisitDateTime(
                context,
                visitDateController,
              ),
            ),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: selectedStaffId,
          decoration: const InputDecoration(
            labelText: 'Staff *',
            border: OutlineInputBorder(),
          ),
          items: staffList
              .map(
                (s) => DropdownMenuItem(value: s.id, child: Text(s.fullName)),
              )
              .toList(),
          onChanged: loadingStaff ? null : onStaffChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: gestationWeeksController,
                decoration: const InputDecoration(
                  labelText: 'Gestation (weeks)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: gestationDaysController,
                decoration: const InputDecoration(
                  labelText: 'Gestation (days)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final days = int.tryParse(v.trim());
                  if (days == null) return 'Enter a whole number';
                  if (days < 0 || days > 6) return '0–6 days';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: systolicController,
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
                controller: diastolicController,
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
          controller: weightController,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: fundalHeightController,
          decoration: const InputDecoration(
            labelText: 'Fundal height (cm)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: fetalHeartRateController,
          decoration: const InputDecoration(
            labelText: 'Fetal heart rate',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}

/// Fetal assessment and notes section.
class AntenatalVisitFetalAssessmentFields extends StatelessWidget {
  const AntenatalVisitFetalAssessmentFields({
    super.key,
    required this.presentation,
    required this.onPresentationChanged,
    required this.descent,
    required this.onDescentChanged,
    required this.urineProtein,
    required this.onUrineProteinChanged,
    required this.urineGlucose,
    required this.onUrineGlucoseChanged,
    required this.pcvController,
    required this.notesController,
    required this.ultrasoundController,
  });

  final FetalPresentation? presentation;
  final ValueChanged<FetalPresentation?> onPresentationChanged;
  final String? descent;
  final ValueChanged<String?> onDescentChanged;
  final String? urineProtein;
  final ValueChanged<String?> onUrineProteinChanged;
  final String? urineGlucose;
  final ValueChanged<String?> onUrineGlucoseChanged;
  final TextEditingController pcvController;
  final TextEditingController notesController;
  final TextEditingController ultrasoundController;

  @override
  Widget build(BuildContext context) {
    return ObFormSectionCard(
      title: 'Fetal assessment & notes',
      icon: Icons.health_and_safety_rounded,
      useTertiaryAccent: true,
      children: [
        DropdownButtonFormField<FetalPresentation>(
          initialValue: presentation,
          decoration: const InputDecoration(
            labelText: 'Presentation',
            border: OutlineInputBorder(),
          ),
          items: FetalPresentation.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
              .toList(),
          onChanged: onPresentationChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: descent,
          decoration: const InputDecoration(
            labelText: 'Descent',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            ...kFetalDescentOptions.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: onDescentChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: AntenatalVisitFetalAssessmentFields.matchDipstickOption(urineProtein),
          decoration: const InputDecoration(
            labelText: 'Urine protein',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            ...kUrineDipstickOptions.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: onUrineProteinChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: AntenatalVisitFetalAssessmentFields.matchDipstickOption(urineGlucose),
          decoration: const InputDecoration(
            labelText: 'Glucose',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('—')),
            ...kUrineDipstickOptions.map(
              (v) => DropdownMenuItem(value: v, child: Text(v)),
            ),
          ],
          onChanged: onUrineGlucoseChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: pcvController,
          decoration: const InputDecoration(
            labelText: 'PCV',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: ultrasoundController,
          decoration: const InputDecoration(
            labelText: 'Ultrasound findings',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  /// Maps legacy free-text dipstick values to dropdown options when possible.
  static String? matchDipstickOption(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final option in kUrineDipstickOptions) {
      if (option.toLowerCase() == value.toLowerCase()) return option;
    }
    return null;
  }
}

/// Builds the API payload map for create/update from form state.
Map<String, dynamic> buildAntenatalVisitPayload({
  required String visitDate,
  required String staffId,
  required TextEditingController gestationWeeksController,
  required TextEditingController gestationDaysController,
  required TextEditingController systolicController,
  required TextEditingController diastolicController,
  required TextEditingController weightController,
  required TextEditingController fundalHeightController,
  required TextEditingController fetalHeartRateController,
  FetalPresentation? presentation,
  String? descent,
  String? urineProtein,
  String? urineGlucose,
  required TextEditingController pcvController,
  required TextEditingController notesController,
  required TextEditingController ultrasoundController,
  String? encounterId,
  bool includeEmptyStrings = false,
}) {
  final weeksText = gestationWeeksController.text.trim();
  final daysText = gestationDaysController.text.trim();

  final payload = <String, dynamic>{
    'visitDate': visitDate,
    'staffId': staffId,
    if (weeksText.isNotEmpty) 'gestationWeeks': int.tryParse(weeksText),
    if (daysText.isNotEmpty) 'gestationDays': int.tryParse(daysText),
    if (systolicController.text.trim().isNotEmpty)
      'systolicBP': int.tryParse(systolicController.text.trim()),
    if (diastolicController.text.trim().isNotEmpty)
      'diastolicBP': int.tryParse(diastolicController.text.trim()),
    if (weightController.text.trim().isNotEmpty)
      'weight': double.tryParse(weightController.text.trim()),
    if (fundalHeightController.text.trim().isNotEmpty)
      'fundalHeight': double.tryParse(fundalHeightController.text.trim()),
    if (fetalHeartRateController.text.trim().isNotEmpty)
      'fetalHeartRate': int.tryParse(fetalHeartRateController.text.trim()),
    if (presentation != null) 'presentation': presentation.apiValue,
    if (descent != null && descent.isNotEmpty) 'descent': descent,
    if (urineProtein != null && urineProtein.isNotEmpty)
      'urineProtein': urineProtein,
    if (urineGlucose != null && urineGlucose.isNotEmpty)
      'urineGlucose': urineGlucose,
    if (pcvController.text.trim().isNotEmpty)
      'pcv': double.tryParse(pcvController.text.trim()),
    if (includeEmptyStrings || notesController.text.trim().isNotEmpty)
      'notes': notesController.text.trim(),
    if (includeEmptyStrings || ultrasoundController.text.trim().isNotEmpty)
      'ultrasoundFindings': ultrasoundController.text.trim(),
    if (encounterId != null && encounterId.isNotEmpty)
      'encounterId': encounterId,
  };

  return payload;
}
