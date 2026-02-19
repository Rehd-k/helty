import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_model.dart';
import '../services/patient_service.dart';

final patientServiceProvider = Provider<PatientService>(
  (ref) => PatientService(),
);

final patientListProvider = FutureProvider.family<List<Patient>, String?>((
  ref,
  query,
) async {
  final service = ref.read(patientServiceProvider);
  return service.fetchPatients(query: query);
});

final currentPatientProvider = StateProvider<Patient?>((ref) => null);
