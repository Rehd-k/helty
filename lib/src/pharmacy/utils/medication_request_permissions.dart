import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/models/medication_request_model.dart';

/// Label for the requester column — OPD auto-requests store the doctor in
/// `requestedByNurse`.
String requestedByColumnLabel({required bool isOpd}) =>
    isOpd ? 'Prescribed by' : 'Requested by';

bool isPrescribingDoctorForRequest(
  MedicationRequestModel request,
  String currentStaffId,
) {
  if (currentStaffId.isEmpty) return false;
  final doctorId = request.medicationOrder?.doctor?.id.trim() ?? '';
  return doctorId.isNotEmpty && doctorId == currentStaffId;
}

/// Whether the current user may PATCH a medication request (doctor on BILLED).
bool canModifyMedicationRequest(
  MedicationRequestModel request, {
  required String currentStaffId,
}) {
  if (!isPrescribingDoctorForRequest(request, currentStaffId)) return false;

  if (request.status == MedicationRequestStatus.requested) return true;

  if (request.status != MedicationRequestStatus.billed) return false;

  final item = request.invoiceItem;
  if (item == null || item.id.isEmpty) return false;
  if (item.settled) return false;
  if (item.amountPaid > 0) return false;
  if (item.allocationCount > 0) return false;
  final invoiceStatus = item.invoiceStatus?.trim().toUpperCase() ?? '';
  if (invoiceStatus == 'PAID') return false;

  return true;
}

/// Nurse may cancel only their own REQUESTED requests.
bool canNurseCancelMedicationRequest(
  MedicationRequestModel request,
  String currentStaffId,
) =>
    request.canCancelAsNurse(currentStaffId);

/// Pharmacy may cancel any REQUESTED request.
bool canPharmacyCancelMedicationRequest(MedicationRequestModel request) =>
    request.isRequested;

bool canNurseRequestMedication({
  required MedicationOrderModel order,
  required bool isOutpatient,
  required bool isNurse,
  required bool isAdmissionActive,
}) =>
    !isOutpatient &&
    isNurse &&
    isAdmissionActive &&
    order.canRequestMedication;

/// Tooltip text when [canNurseRequestMedication] is false; null when allowed.
String? nurseMedicationRequestDisableReason({
  required MedicationOrderModel order,
  required bool isOutpatient,
  required bool isNurse,
  required bool isAdmissionActive,
  String? admissionStatus,
}) {
  if (!isNurse) {
    return 'Only nurses can request medication from pharmacy';
  }
  if (isOutpatient) {
    return 'Medication requests are not available for outpatient encounters';
  }
  if (!isAdmissionActive) {
    final st = admissionStatus?.trim();
    if (st != null && st.isNotEmpty) {
      return 'Admission is ${st.toUpperCase()} — requests are only allowed while admitted';
    }
    return 'Admission is not active — requests are only allowed while admitted';
  }
  return order.medicationRequestDisableReason;
}
