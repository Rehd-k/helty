import 'package:helty/src/admissions/discharge_admission_dialog.dart';
import 'package:helty/src/models/admission_billing_clearance_models.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/services/admission_service.dart';

/// User-facing success message after clinical discharge (PATCH `/admissions/:id`).
String dischargeSuccessMessage(AdmissionModel admission) {
  final status = admission.status.normalized;
  if (status == 'PENDING_BILLING_CLEARANCE') {
    return 'Clinical discharge recorded. Awaiting billing and nurse clearance.';
  }
  if (status == 'DISCHARGED') {
    return 'Patient discharged.';
  }
  if (status == 'DECEASED') {
    return 'Death recorded. Admission finalized.';
  }
  return 'Discharge saved successfully.';
}

/// Performs clinical discharge and returns the updated admission.
Future<AdmissionModel> performClinicalDischarge({
  required AdmissionService service,
  required String admissionId,
  required DischargeAdmissionPayload payload,
  DateTime? dischargeDate,
}) {
  return service.dischargeAdmission(
    admissionId,
    dischargeDate: dischargeDate,
    outcome: payload.outcome,
    dischargeSummary: payload.dischargeSummary,
    otherImportantNotes: payload.otherImportantNotes,
  );
}

/// Resolves the active admission id for a patient (ACTIVE / ADMITTED).
Future<String?> resolveActiveAdmissionId(
  AdmissionService service,
  String patientId,
) async {
  final admissions = await service.getByPatientId(patientId);
  for (final a in admissions) {
    if (a.isActiveAdmission &&
        a.dischargeDate == null &&
        a.dischargeDateTime == null) {
      return a.id;
    }
  }
  return null;
}
