import 'package:helty/src/models/encounter_model.dart';

/// Service for encounter (OPD visit) CRUD. Uses mock data until API exists.
class EncounterService {
  Future<EncounterModel?> getById(String encounterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return EncounterModel(
      id: encounterId,
      patientId: 'P-0001',
      doctorId: 'DOC-1',
      status: 'open',
      startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      visitType: 'OPD',
      insurance: 'Self-pay',
    );
  }

  /// List outpatient encounters for the logged-in doctor (e.g. today).
  Future<List<EncounterModel>> fetchOutpatientEncounters({
    String? doctorId,
    DateTime? date,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = date ?? DateTime.now();
    return [
      EncounterModel(
        id: 'ENC-001',
        patientId: 'P-0001',
        appointmentId: 'APPT-001',
        doctorId: doctorId ?? 'DOC-1',
        status: 'waiting',
        startedAt: now,
        visitType: 'OPD',
        insurance: 'Self-pay',
      ),
      EncounterModel(
        id: 'ENC-002',
        patientId: 'P-0002',
        appointmentId: 'APPT-002',
        doctorId: doctorId ?? 'DOC-1',
        status: 'in_consultation',
        startedAt: now.subtract(const Duration(minutes: 15)),
        visitType: 'Follow-up',
        insurance: 'HMO',
      ),
      EncounterModel(
        id: 'ENC-003',
        patientId: 'P-0003',
        appointmentId: null,
        doctorId: doctorId ?? 'DOC-1',
        status: 'done',
        startedAt: now.subtract(const Duration(hours: 1)),
        closedAt: now.subtract(const Duration(minutes: 30)),
        visitType: 'Walk-in',
        insurance: 'Self-pay',
      ),
    ];
  }

  Future<EncounterModel> create({
    required String patientId,
    required String doctorId,
    String? appointmentId,
    String? visitType,
    String? insurance,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return EncounterModel(
      id: 'ENC-${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      appointmentId: appointmentId,
      doctorId: doctorId,
      status: 'open',
      startedAt: DateTime.now(),
      visitType: visitType ?? 'OPD',
      insurance: insurance,
    );
  }

  Future<EncounterModel> update(String id, Map<String, dynamic> patch) async {
    final existing = await getById(id);
    if (existing == null) throw StateError('Encounter not found: $id');
    return EncounterModel(
      id: existing.id,
      patientId: patch['patientId'] as String? ?? existing.patientId,
      appointmentId: patch['appointmentId'] as String? ?? existing.appointmentId,
      doctorId: patch['doctorId'] as String? ?? existing.doctorId,
      status: patch['status'] as String? ?? existing.status,
      startedAt: existing.startedAt,
      closedAt: patch['closedAt'] != null
          ? DateTime.tryParse(patch['closedAt'] as String)
          : existing.closedAt,
      visitType: patch['visitType'] as String? ?? existing.visitType,
      insurance: patch['insurance'] as String? ?? existing.insurance,
      chiefComplaint: patch['chiefComplaint'] as String? ?? existing.chiefComplaint,
      hpi: patch['hpi'] as String? ?? existing.hpi,
      pmh: patch['pmh'] as String? ?? existing.pmh,
      surgicalHistory: patch['surgicalHistory'] as String? ?? existing.surgicalHistory,
      drugHistory: patch['drugHistory'] as String? ?? existing.drugHistory,
      allergyHistory: patch['allergyHistory'] as String? ?? existing.allergyHistory,
      familyHistory: patch['familyHistory'] as String? ?? existing.familyHistory,
      socialHistory: patch['socialHistory'] as String? ?? existing.socialHistory,
      examinationNotes: patch['examinationNotes'] as String? ?? existing.examinationNotes,
      soapSubjective: patch['soapSubjective'] as String? ?? existing.soapSubjective,
      soapObjective: patch['soapObjective'] as String? ?? existing.soapObjective,
      soapAssessment: patch['soapAssessment'] as String? ?? existing.soapAssessment,
      soapPlan: patch['soapPlan'] as String? ?? existing.soapPlan,
      soapLockedAt: patch['soapLockedAt'] != null
          ? DateTime.tryParse(patch['soapLockedAt'] as String)
          : existing.soapLockedAt,
      primaryIcdCode: patch['primaryIcdCode'] as String? ?? existing.primaryIcdCode,
      primaryIcdDescription: patch['primaryIcdDescription'] as String? ?? existing.primaryIcdDescription,
      secondaryDiagnosesJson: patch['secondaryDiagnosesJson'] as String? ?? existing.secondaryDiagnosesJson,
      proceduresJson: patch['proceduresJson'] as String? ?? existing.proceduresJson,
      followUpDate: patch['followUpDate'] as String? ?? existing.followUpDate,
      followUpInstructions: patch['followUpInstructions'] as String? ?? existing.followUpInstructions,
      referral: patch['referral'] as String? ?? existing.referral,
    );
  }
}
