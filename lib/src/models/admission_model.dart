import '../paitients/patient_model.dart';
import 'admission_billing_clearance_models.dart';
import 'medication_order_model.dart';
import 'patient_vitals_model.dart';
import 'staff_attribution.dart';

/// Nested `attendingDoctor` on GET `/admissions/:id`.
class AttendingDoctorSummary {
  const AttendingDoctorSummary({
    this.id,
    this.firstName,
    this.lastName,
    this.staffId,
  });

  final String? id;
  final String? firstName;
  final String? lastName;
  final String? staffId;

  String get displayName {
    final fn = firstName?.trim() ?? '';
    final ln = lastName?.trim() ?? '';
    if (fn.isEmpty && ln.isEmpty) return '';
    return '$fn $ln'.trim();
  }

  factory AttendingDoctorSummary.fromJson(Map<String, dynamic> json) {
    return AttendingDoctorSummary(
      id: json['id']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      staffId: json['staffId']?.toString(),
    );
  }
}

/// Inpatient admission as returned by GET/POST/PATCH `/admissions`.
class AdmissionModel {
  const AdmissionModel({
    required this.id,
    required this.patientId,
    required this.patient,
    this.encounterId,
    this.patientVitals = const [],
    this.admissionDate,
    this.dischargeDate,
    this.admissionDateTime,
    this.dischargeDateTime,
    this.room,
    this.reason,
    this.admissionReason,
    this.admissionType,
    this.ward,
    this.wardId,
    this.bedId,

    /// Bed label for UI (from nested `bed.bedNumber` or legacy `bedPreference`).
    this.bedPreference,
    this.primaryDiagnosis,
    this.provisionalDiagnosis,
    this.expectedLOS,
    this.isolationRequired = false,
    this.specialInstructions,
    required this.status,
    this.attendingDoctorId,
    this.admittedByDoctorId,
    this.createdById,
    this.updatedById,
    this.createdByName,
    this.updatedByName,
    this.dischargeSummary,
    this.outcome,
    this.otherImportantNotes,
    this.createdAt,
    this.updatedAt,
    this.wardEntity,
    this.bed,
    this.encounter,
    this.attendingDoctor,
    this.clinicallyDischargedBy,
    this.clinicallyDischargedAt,
    this.billingClearedAt,
    this.billingClearedBy,
    this.nursesClearedAt,
    this.nursesClearedBy,
    this.billing,
    this.encounterMedicationOrders = const [],
  });

  final String id;
  final String patientId;

  /// Present on create-from-encounter flows; may be absent when `encounter` is null.
  final String? encounterId;

  final Patient patient;
  final List<PatientVitalsModel> patientVitals;

  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final DateTime? admissionDateTime;
  final DateTime? dischargeDateTime;

  final String? room;
  final String? reason;
  final String? admissionReason;
  final String? admissionType;

  final String? ward;
  final String? wardId;
  final String? bedId;
  final String? bedPreference;

  final String? primaryDiagnosis;

  /// Kept for screens that predate `primaryDiagnosis`; filled from API in [fromJson].
  final String? provisionalDiagnosis;

  final String? expectedLOS;
  final bool isolationRequired;
  final String? specialInstructions;

  final String status;

  final String? attendingDoctorId;
  final String? admittedByDoctorId;
  final String? createdById;
  final String? updatedById;
  final String? createdByName;
  final String? updatedByName;

  final String? dischargeSummary;
  final String? outcome;
  final String? otherImportantNotes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Raw `wardEntity` object when included (id, name, capacity, type, …).
  final Map<String, dynamic>? wardEntity;

  /// Raw `bed` object when included (id, bedNumber, wardId, …).
  final Map<String, dynamic>? bed;

  /// Raw `encounter` when included (often null after admission is persisted).
  final Map<String, dynamic>? encounter;

  /// When API includes `attendingDoctor` (name/staff id).
  final AttendingDoctorSummary? attendingDoctor;

  /// Set on clinical discharge.
  final AttendingDoctorSummary? clinicallyDischargedBy;

  final DateTime? clinicallyDischargedAt;

  /// Set when billing clears (or auto-finalizes when already paid).
  final DateTime? billingClearedAt;

  final AttendingDoctorSummary? billingClearedBy;

  /// Set when nursing clears the patient for physical discharge.
  final DateTime? nursesClearedAt;

  final AttendingDoctorSummary? nursesClearedBy;

  /// Billing snapshot when included on admission responses.
  final AdmissionBillingSummary? billing;

  /// Orders nested under `encounter` when the admission payload includes them.
  final List<MedicationOrderModel> encounterMedicationOrders;

  bool get isActiveAdmission => status.isActiveAdmission;

  bool get isPendingBillingClearance => status.isPendingBillingClearance;

  /// Best display date for “admitted on” UIs.
  DateTime? get displayAdmissionInstant =>
      admissionDateTime ?? admissionDate ?? createdAt;

  factory AdmissionModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    final patientRaw = json['patient'];
    final Map<String, dynamic> patientMap;
    if (patientRaw is Map) {
      patientMap = Map<String, dynamic>.from(patientRaw);
    } else {
      // PATCH/PUT responses often omit nested `patient` and only return `patientId`.
      final pid = str(json['patientId']);
      if (pid.isEmpty) {
        throw StateError(
          'Admission JSON missing `patient` map and `patientId`',
        );
      }
      patientMap = <String, dynamic>{
        'id': pid,
        'patientId': pid,
      };
    }

    final bedRaw = json['bed'];
    final bedMap = bedRaw is Map ? Map<String, dynamic>.from(bedRaw) : null;

    final wardEntityRaw = json['wardEntity'];
    final wardEntityMap = wardEntityRaw is Map
        ? Map<String, dynamic>.from(wardEntityRaw)
        : null;

    final encounterRaw = json['encounter'];
    final encounterMap = encounterRaw is Map
        ? Map<String, dynamic>.from(encounterRaw)
        : null;

    AttendingDoctorSummary? parseDoctorSummary(dynamic raw) {
      if (raw is Map) {
        return AttendingDoctorSummary.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
      return null;
    }

    final attendingDoctor = parseDoctorSummary(json['attendingDoctor']);
    final clinicallyDischargedBy =
        parseDoctorSummary(json['clinicallyDischargedBy']);
    final billingClearedBy = parseDoctorSummary(json['billingClearedBy']);
    final nursesClearedBy = parseDoctorSummary(json['nursesClearedBy']);

    AdmissionBillingSummary? billing;
    final billingRaw = json['billing'];
    if (billingRaw is Map) {
      billing = AdmissionBillingSummary.fromJson(
        Map<String, dynamic>.from(billingRaw),
      );
    }

    List<MedicationOrderModel> encounterMedicationOrders =
        const <MedicationOrderModel>[];
    if (encounterMap != null) {
      final mo = encounterMap['medicationOrders'];
      if (mo is List) {
        encounterMedicationOrders = mo
            .whereType<Map>()
            .map(
              (e) => MedicationOrderModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      }
    }

    final encounterIdFromJson = json['encounterId']?.toString();
    final encounterIdNested = encounterMap?['id']?.toString();
    final encounterId =
        (encounterIdFromJson != null && encounterIdFromJson.isNotEmpty)
        ? encounterIdFromJson
        : encounterIdNested;

    final primaryDiagnosis = json['primaryDiagnosis']?.toString();
    final provisionalFromJson = json['provisionalDiagnosis']?.toString();
    final provisionalDiagnosis = provisionalFromJson ?? primaryDiagnosis;

    final vitalsList = json['patientVitals'];
    final patientVitals = vitalsList is List
        ? vitalsList
              .whereType<Map>()
              .map(
                (v) =>
                    PatientVitalsModel.fromJson(Map<String, dynamic>.from(v)),
              )
              .toList()
        : <PatientVitalsModel>[];

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final bedNumberFromNested = bedMap?['bedNumber']?.toString();

    return AdmissionModel(
      id: str(json['id']),
      patientId: str(json['patientId']),
      encounterId: encounterId,
      patient: Patient.fromJson(patientMap),
      patientVitals: patientVitals,
      admissionDate: parseDt(json['admissionDate']),
      dischargeDate: parseDt(json['dischargeDate']),
      admissionDateTime: parseDt(json['admissionDateTime']),
      dischargeDateTime: parseDt(json['dischargeDateTime']),
      room: json['room']?.toString(),
      reason: json['reason']?.toString(),
      admissionReason: json['admissionReason']?.toString(),
      admissionType: json['admissionType']?.toString(),
      ward: json['ward']?.toString(),
      wardId: json['wardId']?.toString(),
      bedId: json['bedId']?.toString() ?? bedMap?['id']?.toString(),
      bedPreference: bedNumberFromNested ?? json['bedPreference']?.toString(),
      primaryDiagnosis: primaryDiagnosis,
      provisionalDiagnosis: provisionalDiagnosis,
      expectedLOS: json['expectedLOS']?.toString(),
      isolationRequired: json['isolationRequired'] == true,
      specialInstructions: json['specialInstructions']?.toString(),
      status: (json['status']?.toString()) ?? 'Pending',
      attendingDoctorId: json['attendingDoctorId']?.toString(),
      admittedByDoctorId: json['admittedByDoctorId']?.toString(),
      createdById: json['createdById']?.toString(),
      updatedById: json['updatedById']?.toString(),
      createdByName: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
      updatedByName: formatStaffName(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
      dischargeSummary: json['dischargeSummary']?.toString(),
      outcome: json['outcome']?.toString(),
      otherImportantNotes: json['otherImportantNotes']?.toString(),
      createdAt: parseDt(json['createdAt']),
      updatedAt: parseDt(json['updatedAt']),
      wardEntity: wardEntityMap,
      bed: bedMap,
      encounter: encounterMap,
      attendingDoctor: attendingDoctor,
      clinicallyDischargedBy: clinicallyDischargedBy,
      clinicallyDischargedAt: parseDt(json['clinicallyDischargedAt']),
      billingClearedAt: parseDt(json['billingClearedAt']),
      billingClearedBy: billingClearedBy,
      nursesClearedAt: parseDt(json['nursesClearedAt']),
      nursesClearedBy: nursesClearedBy,
      billing: billing,
      encounterMedicationOrders: encounterMedicationOrders,
    );
  }
}
