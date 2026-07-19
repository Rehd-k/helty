import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../paitients/patient_service.dart';
import 'patient_access_service.dart';

final patientAccessServiceProvider = Provider<PatientAccessService>((ref) {
  return PatientAccessService();
});

final patientAccessPatientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});
