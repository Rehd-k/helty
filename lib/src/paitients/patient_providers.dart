import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'patient.state.dart';
import 'patient_notifier.dart';
import 'patient_service.dart';

final patientServiceProvider = Provider<PatientService>(
  (ref) => PatientService(),
);

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((
  ref,
) {
  final service = ref.read(patientServiceProvider);
  return PatientNotifier(service);
});
