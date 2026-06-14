import 'package:dio/dio.dart';

import '../models/nursing_note_model.dart';
import 'api_service.dart';

class NursingNoteService {
  NursingNoteService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/nursing-notes`
  Future<List<NursingNoteModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/nursing-notes',
    );
    return _listData(response.data)
        .map(
          (e) => NursingNoteModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/nursing-notes`
  Future<NursingNoteModel> create({
    required String admissionId,
    required String noteType,
    required String content,
    String? nurseId,
  }) async {
    final body = <String, dynamic>{
      'noteType': noteType,
      'content': content,
      if (nurseId != null && nurseId.isNotEmpty) 'nurseId': nurseId,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/nursing-notes',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create nursing note returned no data');
    }
    return NursingNoteModel.fromJson(data);
  }

  /// PATCH `/admissions/:admissionId/nursing-notes/:noteId`
  Future<NursingNoteModel> update({
    required String admissionId,
    required String noteId,
    String? noteType,
    String? content,
  }) async {
    final body = <String, dynamic>{
      if (noteType != null) 'noteType': noteType,
      if (content != null) 'content': content,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/nursing-notes/$noteId',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Update nursing note returned no data');
    }
    return NursingNoteModel.fromJson(data);
  }
}
