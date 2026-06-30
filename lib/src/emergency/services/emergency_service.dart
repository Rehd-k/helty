import 'package:dio/dio.dart';

import '../../models/admission_model.dart';
import '../../models/clinical_specialty_models.dart';
import '../../models/encounter_model.dart';
import '../../paitients/patient_service.dart';
import '../../services/admission_service.dart';
import '../../services/api_service.dart';
import '../../services/clinical_specialty_service.dart';
import '../../services/encounter_service.dart';
import '../models/ed_enums.dart';
import '../models/emergency_visit_model.dart';

/// ED visit orchestration — PROPOSED `/emergency/*` with EXISTS fallbacks.
class EmergencyService {
  EmergencyService({
    EncounterService? encounterService,
    ClinicalSpecialtyService? clinicalSpecialtyService,
    AdmissionService? admissionService,
    PatientService? patientService,
    Dio? dio,
  })  : _encounterService = encounterService ?? EncounterService(),
        _clinicalSpecialtyService =
            clinicalSpecialtyService ?? ClinicalSpecialtyService(),
        _admissionService = admissionService ?? AdmissionService(),
        _patientService = patientService ?? PatientService(),
        _dio = dio ?? ApiService().dio;

  final EncounterService _encounterService;
  final ClinicalSpecialtyService _clinicalSpecialtyService;
  final AdmissionService _admissionService;
  final PatientService _patientService;
  final Dio _dio;

  static const _emSpecialty = 'EMERGENCY_MEDICINE';
  static const _emSections = ['em.triage', 'em.disposition'];

  bool _isProposedUnavailable(DioException e) {
    final code = e.response?.statusCode;
    return code == 404 || code == 501 || code == 405;
  }

  /// Enables EMERGENCY_MEDICINE specialty modules on an encounter.
  Future<void> enableEmergencyModules(String encounterId) async {
    await _clinicalSpecialtyService.syncModules(
      encounterId,
      [
        const EncounterSpecialtyModuleModel(
          specialty: _emSpecialty,
          enabledSectionKeys: _emSections,
        ),
      ],
    );
  }

  /// Register ED visit — `POST /emergency/visits` or interim `POST /encounters`.
  Future<EmergencyRegisterResult> registerVisit({
    required String patientId,
    required String doctorId,
    required String chiefComplaint,
    EdArrivalMode arrivalMode = EdArrivalMode.walkIn,
    String? triageNurseId,
    String? hpi,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/emergency/visits',
        data: {
          'patientId': patientId,
          'doctorId': doctorId,
          'chiefComplaint': chiefComplaint,
          'arrivalMode': arrivalMode.apiValue,
          if (triageNurseId != null && triageNurseId.isNotEmpty)
            'triageNurseId': triageNurseId,
          if (hpi != null && hpi.isNotEmpty) 'hpi': hpi,
        },
      );
      final data = response.data;
      if (data == null) {
        throw StateError('Register ED visit returned no data');
      }
      final visitRaw = data['emergencyVisit'] ?? data;
      final encRaw = data['encounter'];
      final visit = EmergencyVisitModel.fromJson(
        Map<String, dynamic>.from(visitRaw as Map),
      );
      final enc = encRaw is Map
          ? EncounterModel.fromJson(Map<String, dynamic>.from(encRaw))
          : await _encounterService.getById(visit.encounterId);
      if (enc == null) {
        throw StateError('Encounter missing after ED registration');
      }
      await enableEmergencyModules(enc.id);
      return EmergencyRegisterResult(
        emergencyVisit: visit,
        encounter: enc,
      );
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    final body = <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      'encounterType': 'EMERGENCY',
      'chiefComplaint': chiefComplaint,
      if (hpi != null && hpi.isNotEmpty) 'hpi': hpi,
      if (triageNurseId != null && triageNurseId.isNotEmpty)
        'triageNurseId': triageNurseId,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/encounters',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create encounter returned no data');
    }
    final encounter = EncounterModel.fromJson(data);
    final reused = response.statusCode == 200;
    if (!reused) {
      await enableEmergencyModules(encounter.id);
    }

    final visit = EmergencyVisitModel.fromEncounter(
      encounter,
      workflowStatus: EdWorkflowStatus.registered,
    );
    return EmergencyRegisterResult(
      emergencyVisit: visit,
      encounter: encounter,
      reusedExistingEncounter: reused,
    );
  }

  /// List active ED visits for the board.
  Future<EmergencyVisitListResult> listActiveVisits({
    String? status,
    int? esiLevel,
    DateTime? fromDate,
    DateTime? toDate,
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final qp = <String, dynamic>{
        'skip': skip,
        'take': take,
        if (status != null && status.isNotEmpty) 'status': status,
        if (esiLevel != null) 'esiLevel': esiLevel,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      };
      final response = await _dio.get<dynamic>(
        '/emergency/visits',
        queryParameters: qp,
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final list = raw['visits'] as List? ?? raw['data'] as List? ?? [];
        final visits = list
            .whereType<Map>()
            .map(
              (e) => EmergencyVisitModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
        return EmergencyVisitListResult(
          visits: visits,
          total: raw['total'] as int? ?? visits.length,
          skip: raw['skip'] as int? ?? skip,
          take: raw['take'] as int? ?? take,
        );
      }
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    final from = fromDate ?? DateTime.now().subtract(const Duration(days: 1));
    final to = toDate ?? DateTime.now().add(const Duration(days: 1));
    final encounters = await _encounterService.fetchEmergencyEncounters(
      fromDate: from,
      toDate: to,
      status: 'ONGOING',
      skip: skip,
      take: take,
    );

    final visits = <EmergencyVisitModel>[];
    for (final enc in encounters) {
      String? patientName;
      try {
        final p = await _patientService.getPatientById(enc.patientId);
        patientName = p.displayName.trim();
      } catch (_) {}

      int? esi;
      EdWorkflowStatus ws = EdWorkflowStatus.registered;
      try {
        final sections = await _clinicalSpecialtyService.listSections(
          enc.id,
          specialty: _emSpecialty,
          keys: ['em.triage'],
        );
        for (final s in sections) {
          if (s.sectionKey != 'em.triage') continue;
          final data = s.data;
          final rawEsi = data['esiLevel'];
          if (rawEsi is int) {
            esi = rawEsi;
          } else if (rawEsi != null) {
            esi = int.tryParse(rawEsi.toString());
          }
          if (esi != null) {
            ws = EdWorkflowStatus.waitingDoctor;
          }
        }
      } catch (_) {}

      visits.add(
        EmergencyVisitModel.fromEncounter(
          enc,
          patientName: patientName,
          esiLevel: esi,
          workflowStatus: ws,
        ),
      );
    }

    return EmergencyVisitListResult(
      visits: visits,
      total: visits.length,
      skip: skip,
      take: take,
    );
  }

  /// GET visit by id or encounter id (interim).
  Future<EmergencyVisitModel?> getVisit(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/emergency/visits/$id',
      );
      final data = response.data;
      if (data == null) return null;
      final visitRaw = data['emergencyVisit'] ?? data;
      return EmergencyVisitModel.fromJson(
        Map<String, dynamic>.from(visitRaw as Map),
      );
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    final enc = await _encounterService.getById(
      id,
      expand: ['clinicalSections', 'specialtyModules'],
    );
    if (enc == null || !enc.isEmergency) return null;

    int? esi;
    EdWorkflowStatus ws = EdWorkflowStatus.registered;
    for (final s in enc.clinicalSections ?? const []) {
      if (s.sectionKey != 'em.triage') continue;
      final data = s.data;
      if (data == null) continue;
      final rawEsi = data['esiLevel'];
      if (rawEsi is int) {
        esi = rawEsi;
      } else if (rawEsi != null) {
        esi = int.tryParse(rawEsi.toString());
      }
      if (esi != null) ws = EdWorkflowStatus.waitingDoctor;
    }

    return EmergencyVisitModel.fromEncounter(
      enc,
      esiLevel: esi,
      workflowStatus: ws,
    );
  }

  /// PATCH visit status / ESI (PROPOSED); no-op on interim except local intent.
  Future<EmergencyVisitModel?> updateVisit(
    String visitId, {
    EdWorkflowStatus? workflowStatus,
    int? esiLevel,
    DateTime? triageCompletedAt,
    String? assignedDoctorId,
  }) async {
    try {
      final body = <String, dynamic>{
        if (workflowStatus != null) 'workflowStatus': workflowStatus.apiValue,
        if (esiLevel != null) 'esiLevel': esiLevel,
        if (triageCompletedAt != null)
          'triageCompletedAt': triageCompletedAt.toIso8601String(),
        if (assignedDoctorId != null && assignedDoctorId.isNotEmpty)
          'assignedDoctorId': assignedDoctorId,
      };
      if (body.isEmpty) return getVisit(visitId);

      final response = await _dio.patch<Map<String, dynamic>>(
        '/emergency/visits/$visitId',
        data: body,
      );
      final data = response.data;
      if (data == null) return null;
      final visitRaw = data['emergencyVisit'] ?? data;
      return EmergencyVisitModel.fromJson(
        Map<String, dynamic>.from(visitRaw as Map),
      );
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }
    return getVisit(visitId);
  }

  /// Submit disposition — PROPOSED endpoint or interim complete.
  Future<EncounterModel> submitDisposition({
    required String visitId,
    required String encounterId,
    required EdDispositionPayload payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/emergency/visits/$visitId/disposition',
        data: payload.toJson(),
      );
      final data = response.data;
      final encRaw = data?['encounter'];
      if (encRaw is Map) {
        return EncounterModel.fromJson(Map<String, dynamic>.from(encRaw));
      }
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    await _clinicalSpecialtyService.upsertSection(
      encounterId,
      _emSpecialty,
      'em.disposition',
      {
        'disposition': payload.disposition.apiValue,
        if (payload.followUpInstructions != null)
          'followUp': payload.followUpInstructions,
      },
    );

    if (payload.disposition == EdDisposition.admitWard ||
        payload.disposition == EdDisposition.admitIcu) {
      final enc = await _encounterService.getById(encounterId);
      if (enc == null) throw StateError('Encounter not found');
      return enc;
    }

    if (payload.disposition == EdDisposition.lwbs) {
      return _encounterService.cancelEncounter(encounterId);
    }

    // Discharge, transfer, observation, deceased → COMPLETED
    return _encounterService.complete(encounterId);
  }

  /// Unified clinical + billing aggregate (PROPOSED) with expand fallback.
  Future<Map<String, dynamic>?> fetchClinicalFile(String encounterId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/encounters/$encounterId/clinical-file',
      );
      return response.data;
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    final enc = await _encounterService.getById(
      encounterId,
      expand: [
        'medicationOrders',
        'labRequests',
        'radiologyOrders',
        'clinicalSections',
        'specialtyModules',
        'invoices',
      ],
    );
    if (enc == null) return null;

    return {
      'encounter': enc.toJson(),
      'clinicalSections': [
        for (final s in enc.clinicalSections ?? const [])
          {
            'specialty': s.specialty,
            'sectionKey': s.sectionKey,
            'data': s.data,
          },
      ],
      'billing': {'invoices': []},
    };
  }

  /// Admit from ED — PROPOSED or interim POST /admissions.
  Future<AdmissionModel> admitFromEd({
    required String visitId,
    required String patientId,
    required String encounterId,
    required EdAdmitPayload payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/emergency/visits/$visitId/admit',
        data: payload.toJson(),
      );
      final data = response.data;
      if (data != null) {
        final admRaw = data['admission'] ?? data;
        if (admRaw is Map) {
          return AdmissionModel.fromJson(Map<String, dynamic>.from(admRaw));
        }
      }
    } on DioException catch (e) {
      if (!_isProposedUnavailable(e)) rethrow;
    }

    return _admissionService.create(
      patientId: patientId,
      encounterId: encounterId,
      wardId: payload.wardId,
      bedPreference: payload.bedId,
      reason: payload.reason,
      attendingDoctorId: payload.attendingDoctorId,
    );
  }

  /// Extract ESI from encounter clinical sections.
  int? esiFromEncounter(EncounterModel enc) {
    for (final s in enc.clinicalSections ?? const []) {
      if (s.sectionKey != 'em.triage') continue;
      final data = s.data;
      if (data == null) continue;
      final rawEsi = data['esiLevel'];
      if (rawEsi is int) return rawEsi;
      if (rawEsi != null) return int.tryParse(rawEsi.toString());
    }
    return null;
  }
}
