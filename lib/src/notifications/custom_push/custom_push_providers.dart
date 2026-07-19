import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../paitients/patient_service.dart';
import 'custom_push_service.dart';

final customPushServiceProvider = Provider<CustomPushService>((ref) {
  return CustomPushService();
});

final customPushPatientServiceProvider = Provider<PatientService>((ref) {
  return PatientService();
});
