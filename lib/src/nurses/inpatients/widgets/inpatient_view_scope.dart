import 'package:flutter/material.dart';

import '../../../models/medication_order_model.dart';

/// Provides inpatient view context to tab content.
///
/// Exposes patient/admission identifiers as well as high-level role flags for
/// the currently logged-in staff, so tabs can adjust behavior based on whether
/// the viewer is a doctor or nurse (e.g. ordering vs administering).
class InpatientViewScope extends InheritedWidget {
  const InpatientViewScope({
    super.key,
    required this.patientId,
    this.admissionId,
    this.encounterId,
    this.embeddedMedicationOrders = const [],
    this.patientDisplayName,
    this.hospitalNumber,
    this.staffId,
    this.role,
    this.accountType,
    this.isDoctor = false,
    this.isNurse = false,
    this.admissionStatus,
    this.isOutpatient = false,
    required super.child,
  });

  final String patientId;
  final String? admissionId;

  /// Admission lifecycle status from GET `/admissions/:id` (e.g. ACTIVE, DISCHARGED).
  final String? admissionStatus;

  /// OPD ward with no ACTIVE admission — hide nurse medication request UI.
  final bool isOutpatient;

  /// Display name from patient record (title, first, surname), when loaded.
  final String? patientDisplayName;

  /// Hospital / MRN-style identifier (`patient.patientId`), when loaded.
  final String? hospitalNumber;

  /// Optional encounter backing this admission, when available.
  final String? encounterId;

  /// Orders included on the admission payload (e.g. under `encounter.medicationOrders`).
  final List<MedicationOrderModel> embeddedMedicationOrders;

  /// Currently logged-in staff identifiers.
  final String? staffId;
  final String? role;
  final String? accountType;

  /// Convenience booleans derived from [role]/[accountType].
  final bool isDoctor;
  final bool isNurse;

  /// Whether nursing/clinical actions are allowed on this admission.
  bool get isAdmissionActive {
    final st = (admissionStatus ?? '').toUpperCase();
    return st == 'ACTIVE' || st == 'ADMITTED';
  }

  static InpatientViewScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InpatientViewScope>();

  @override
  bool updateShouldNotify(InpatientViewScope old) =>
      patientId != old.patientId ||
      admissionId != old.admissionId ||
      encounterId != old.encounterId ||
      patientDisplayName != old.patientDisplayName ||
      hospitalNumber != old.hospitalNumber ||
      staffId != old.staffId ||
      role != old.role ||
      accountType != old.accountType ||
      isDoctor != old.isDoctor ||
      isNurse != old.isNurse ||
      admissionStatus != old.admissionStatus ||
      isOutpatient != old.isOutpatient;
}
