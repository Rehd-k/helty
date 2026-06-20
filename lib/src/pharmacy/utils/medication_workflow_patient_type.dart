import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/services/admission_service.dart';

bool isOpdWardName(String? wardName) =>
    wardName?.trim().toUpperCase() == 'OPD';

bool isActiveAdmissionStatus(String? status) {
  final s = status?.trim().toUpperCase();
  return s == 'ACTIVE' || s == 'ADMITTED';
}

AdmissionModel? findActiveAdmission(List<AdmissionModel> admissions) {
  for (final a in admissions) {
    if (isActiveAdmissionStatus(a.status)) return a;
  }
  return null;
}

Future<bool> isOutpatientMedicationPatient({
  required Patient patient,
  required AdmissionService admissionService,
}) async {
  if (!isOpdWardName(patient.ward)) return false;
  final patientId = patient.id?.trim() ?? '';
  if (patientId.isEmpty) return isOpdWardName(patient.ward);
  final admissions = await admissionService.getByPatientId(patientId);
  return !admissions.any((a) => isActiveAdmissionStatus(a.status));
}

Future<({bool isOutpatient, String? activeAdmissionId})>
    resolveMedicationPatientContext({
  required Patient? patient,
  required AdmissionService admissionService,
  String? encounterAdmissionId,
}) async {
  if (patient == null) {
    return (isOutpatient: false, activeAdmissionId: encounterAdmissionId);
  }

  final patientId = patient.id?.trim() ?? '';
  List<AdmissionModel> admissions = const [];
  if (patientId.isNotEmpty) {
    try {
      admissions = await admissionService.getByPatientId(patientId);
    } catch (_) {
      admissions = const [];
    }
  }

  final active = findActiveAdmission(admissions);
  final activeAdmissionId =
      encounterAdmissionId?.trim().isNotEmpty == true
          ? encounterAdmissionId
          : active?.id;

  final isOutpatient =
      isOpdWardName(patient.ward) &&
      !admissions.any((a) => isActiveAdmissionStatus(a.status));

  return (isOutpatient: isOutpatient, activeAdmissionId: activeAdmissionId);
}
