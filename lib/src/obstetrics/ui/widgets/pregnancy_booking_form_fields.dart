import 'package:flutter/material.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_form_scaffold.dart';

/// Optional dropdown with a null "—" option.
List<DropdownMenuItem<String>> _optionalStringDropdownItems(
  List<String> options,
) {
  return [
    const DropdownMenuItem<String>(value: null, child: Text('—')),
    ...options.map((v) => DropdownMenuItem(value: v, child: Text(v))),
  ];
}

/// Vitals captured at pregnancy booking.
class PregnancyBookingVitalsFields extends StatelessWidget {
  const PregnancyBookingVitalsFields({
    super.key,
    required this.respiratoryRateController,
    required this.heartRateController,
    required this.systolicController,
    required this.diastolicController,
    required this.spo2Controller,
  });

  final TextEditingController respiratoryRateController;
  final TextEditingController heartRateController;
  final TextEditingController systolicController;
  final TextEditingController diastolicController;
  final TextEditingController spo2Controller;

  @override
  Widget build(BuildContext context) {
    return ObFormSectionCard(
      title: 'Vitals',
      icon: Icons.monitor_heart_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: respiratoryRateController,
                decoration: const InputDecoration(
                  labelText: 'RR (breaths/min)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: heartRateController,
                decoration: const InputDecoration(
                  labelText: 'HR (bpm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
          controller: spo2Controller,
          decoration: const InputDecoration(
            labelText: 'SpO₂',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}

/// Genotype and blood group at booking.
class PregnancyBookingBloodTypeFields extends StatelessWidget {
  const PregnancyBookingBloodTypeFields({
    super.key,
    required this.genotype,
    required this.onGenotypeChanged,
    required this.bloodGroup,
    required this.onBloodGroupChanged,
  });

  final String? genotype;
  final ValueChanged<String?> onGenotypeChanged;
  final String? bloodGroup;
  final ValueChanged<String?> onBloodGroupChanged;

  @override
  Widget build(BuildContext context) {
    return ObFormSectionCard(
      title: 'Blood type',
      icon: Icons.bloodtype_outlined,
      children: [
        DropdownButtonFormField<String>(
          initialValue: genotype,
          decoration: const InputDecoration(
            labelText: 'Genotype',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kGenotypeOptions),
          onChanged: onGenotypeChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: bloodGroup,
          decoration: const InputDecoration(
            labelText: 'Blood group',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kBloodGroupOptions),
          onChanged: onBloodGroupChanged,
        ),
      ],
    );
  }
}

/// Booking laboratory results and urinalysis.
class PregnancyBookingLaboratoryFields extends StatelessWidget {
  const PregnancyBookingLaboratoryFields({
    super.key,
    required this.pcvController,
    required this.hcv,
    required this.onHcvChanged,
    required this.hbsAg,
    required this.onHbsAgChanged,
    required this.vdrl,
    required this.onVdrlChanged,
    required this.hiv12,
    required this.onHiv12Changed,
    required this.urinalysisProtein,
    required this.onUrinalysisProteinChanged,
    required this.urinalysisGlucose,
    required this.onUrinalysisGlucoseChanged,
  });

  final TextEditingController pcvController;
  final String? hcv;
  final ValueChanged<String?> onHcvChanged;
  final String? hbsAg;
  final ValueChanged<String?> onHbsAgChanged;
  final String? vdrl;
  final ValueChanged<String?> onVdrlChanged;
  final String? hiv12;
  final ValueChanged<String?> onHiv12Changed;
  final String? urinalysisProtein;
  final ValueChanged<String?> onUrinalysisProteinChanged;
  final String? urinalysisGlucose;
  final ValueChanged<String?> onUrinalysisGlucoseChanged;

  @override
  Widget build(BuildContext context) {
    return ObFormSectionCard(
      title: 'Laboratory results',
      icon: Icons.biotech_outlined,
      useTertiaryAccent: true,
      children: [
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
        DropdownButtonFormField<String>(
          initialValue: hcv,
          decoration: const InputDecoration(
            labelText: 'HCV',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kSerologyResultOptions),
          onChanged: onHcvChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: hbsAg,
          decoration: const InputDecoration(
            labelText: 'HBsAg',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kSerologyResultOptions),
          onChanged: onHbsAgChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: vdrl,
          decoration: const InputDecoration(
            labelText: 'VDRL',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kSerologyResultOptions),
          onChanged: onVdrlChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: hiv12,
          decoration: const InputDecoration(
            labelText: 'HIV 1 & 2',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kSerologyResultOptions),
          onChanged: onHiv12Changed,
        ),
        const SizedBox(height: 20),
        Text(
          'Urinalysis',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: urinalysisProtein,
          decoration: const InputDecoration(
            labelText: 'Protein',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kUrineDipstickOptions),
          onChanged: onUrinalysisProteinChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: urinalysisGlucose,
          decoration: const InputDecoration(
            labelText: 'Glucose',
            border: OutlineInputBorder(),
          ),
          items: _optionalStringDropdownItems(kUrineDipstickOptions),
          onChanged: onUrinalysisGlucoseChanged,
        ),
      ],
    );
  }
}

Map<String, dynamic> buildPregnancyBookingPayload({
  required String patientId,
  required int gravida,
  required int para,
  required String lmp,
  required String edd,
  required TextEditingController bookingDateController,
  PregnancyStatus? status,
  required TextEditingController outcomeController,
  required TextEditingController respiratoryRateController,
  required TextEditingController heartRateController,
  required TextEditingController systolicController,
  required TextEditingController diastolicController,
  required TextEditingController spo2Controller,
  String? genotype,
  String? bloodGroup,
  required TextEditingController pcvController,
  String? hcv,
  String? hbsAg,
  String? vdrl,
  String? hiv12,
  String? urinalysisProtein,
  String? urinalysisGlucose,
  required TextEditingController ttImmunizationController,
}) {
  return {
    'patientId': patientId,
    'gravida': gravida,
    'para': para,
    'lmp': lmp,
    'edd': edd,
    if (bookingDateController.text.trim().isNotEmpty)
      'bookingDate': bookingDateController.text.trim(),
    if (status != null) 'status': status.apiValue,
    if (outcomeController.text.trim().isNotEmpty)
      'outcome': outcomeController.text.trim(),
    if (respiratoryRateController.text.trim().isNotEmpty)
      'respiratoryRate': int.tryParse(respiratoryRateController.text.trim()),
    if (heartRateController.text.trim().isNotEmpty)
      'heartRate': int.tryParse(heartRateController.text.trim()),
    if (systolicController.text.trim().isNotEmpty)
      'systolicBP': int.tryParse(systolicController.text.trim()),
    if (diastolicController.text.trim().isNotEmpty)
      'diastolicBP': int.tryParse(diastolicController.text.trim()),
    if (spo2Controller.text.trim().isNotEmpty)
      'spo2': double.tryParse(spo2Controller.text.trim()),
    if (genotype != null && genotype.isNotEmpty) 'genotype': genotype,
    if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
    if (pcvController.text.trim().isNotEmpty)
      'pcv': double.tryParse(pcvController.text.trim()),
    if (hcv != null && hcv.isNotEmpty) 'hcv': hcv,
    if (hbsAg != null && hbsAg.isNotEmpty) 'hbsAg': hbsAg,
    if (vdrl != null && vdrl.isNotEmpty) 'vdrl': vdrl,
    if (hiv12 != null && hiv12.isNotEmpty) 'hiv12': hiv12,
    if (urinalysisProtein != null && urinalysisProtein.isNotEmpty)
      'urinalysisProtein': urinalysisProtein,
    if (urinalysisGlucose != null && urinalysisGlucose.isNotEmpty)
      'urinalysisGlucose': urinalysisGlucose,
    if (ttImmunizationController.text.trim().isNotEmpty)
      'ttImmunization': ttImmunizationController.text.trim(),
  };
}
