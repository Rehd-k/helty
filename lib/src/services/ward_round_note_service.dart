import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/ward_round_note_model.dart';

class WardRoundNoteService {
  WardRoundNoteService() : _dio = ApiService().dio;

  final Dio _dio;

  /// POST /ward-round-notes — create a ward round note.
  Future<WardRoundNoteModel> create({
    required String admissionId,
    required String doctorId,
    required DateTime roundDate,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
  }) async {
    final body = <String, dynamic>{
      'admissionId': admissionId,
      'doctorId': doctorId,
      'roundDate': _dateOnly(roundDate),
      if (subjective != null && subjective.isNotEmpty) 'subjective': subjective,
      if (objective != null && objective.isNotEmpty) 'objective': objective,
      if (assessment != null && assessment.isNotEmpty) 'assessment': assessment,
      if (plan != null && plan.isNotEmpty) 'plan': plan,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/ward-round-notes',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create ward round note returned no data');
    return WardRoundNoteModel.fromJson(data);
  }

  /// GET /ward-round-notes?admissionId=... — list notes for an admission.
  Future<List<WardRoundNoteModel>> listByAdmission(
    String admissionId, {
    String? doctorId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, dynamic>{'admissionId': admissionId};
    if (doctorId != null && doctorId.isNotEmpty) query['doctorId'] = doctorId;
    if (fromDate != null) query['fromDate'] = _dateOnly(fromDate);
    if (toDate != null) query['toDate'] = _dateOnly(toDate);
    final response = await _dio.get<dynamic>(
      '/ward-round-notes',
      queryParameters: query,
    );
    final data = response.data;
    if (data == null || data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(WardRoundNoteModel.fromJson)
        .toList();
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
