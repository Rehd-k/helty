import 'package:dio/dio.dart';

import '../models/care_plan_model.dart';
import 'api_service.dart';

class CarePlanService {
  CarePlanService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/care-plans`
  Future<List<CarePlanModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/care-plans',
    );
    return _listData(response.data)
        .map(
          (e) => CarePlanModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/care-plans`
  Future<CarePlanModel> create({
    required String admissionId,
    required String problem,
    String? goal,
    String? interventions,
    String? evaluation,
  }) async {
    final body = <String, dynamic>{
      'problem': problem,
      if (goal != null) 'goal': goal,
      if (interventions != null) 'interventions': interventions,
      if (evaluation != null) 'evaluation': evaluation,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/care-plans',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create care plan returned no data');
    }
    return CarePlanModel.fromJson(data);
  }

  /// PATCH `/admissions/:admissionId/care-plans/:carePlanId`
  Future<CarePlanModel> update({
    required String admissionId,
    required String carePlanId,
    String? problem,
    String? goal,
    String? interventions,
    String? evaluation,
    String? status,
  }) async {
    final body = <String, dynamic>{
      if (problem != null) 'problem': problem,
      if (goal != null) 'goal': goal,
      if (interventions != null) 'interventions': interventions,
      if (evaluation != null) 'evaluation': evaluation,
      if (status != null) 'status': status,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/care-plans/$carePlanId',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Update care plan returned no data');
    }
    return CarePlanModel.fromJson(data);
  }
}
