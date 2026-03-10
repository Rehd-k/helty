import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/obstetrics_models.dart';

/// Obstetrics & Gynaecology API service. Base path: /obstetrics.
/// All errors are rethrown as [AppException] (via ErrorInterceptor or _handleError).
class ObstetricsService {
  ObstetricsService() : _dio = ApiService().dio;
  final Dio _dio;

  static const String _base = '/obstetrics';

  Never _handleError(DioException e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.message)?.toString()
        : e.message;
    throw UnknownException(
      message?.toString().isNotEmpty == true
          ? message!
          : 'Obstetrics request failed.',
    );
  }

  // ─── Pregnancies ─────────────────────────────────────────────────────────

  Future<PregnanciesListResponse> listPregnancies({
    String? patientId,
    PregnancyStatus? status,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/pregnancies',
        queryParameters: {
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (status != null) 'status': status.apiValue,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const PregnanciesListResponse(
          pregnancies: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return PregnanciesListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Pregnancy> getPregnancy(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/pregnancies/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Pregnancy.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Pregnancy> createPregnancy(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/pregnancies',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Pregnancy.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Pregnancy> updatePregnancy(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/pregnancies/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Pregnancy.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Antenatal visits ────────────────────────────────────────────────────

  Future<AntenatalVisitsListResponse> listAntenatalVisits(
    String pregnancyId, {
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/pregnancies/$pregnancyId/visits',
        queryParameters: {
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const AntenatalVisitsListResponse(
          visits: [],
          total: 0,
          skip: 0,
          take: 50,
        );
      }
      return AntenatalVisitsListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<AntenatalVisit> getAntenatalVisit(String id) async {
    try {
      final resp =
          await _dio.get<Map<String, dynamic>>('$_base/antenatal-visits/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return AntenatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<AntenatalVisit> createAntenatalVisit(
    String pregnancyId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/pregnancies/$pregnancyId/visits',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return AntenatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<AntenatalVisit> updateAntenatalVisit(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/antenatal-visits/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return AntenatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Labour & delivery ──────────────────────────────────────────────────

  /// List labour deliveries for a pregnancy.
  /// GET /obstetrics/pregnancies/:pregnancyId/labour-deliveries
  /// Returns empty list if backend returns 404 (endpoint not implemented).
  Future<LabourDeliveriesListResponse> listLabourDeliveries(
    String pregnancyId, {
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final resp = await _dio.get<dynamic>(
        '$_base/pregnancies/$pregnancyId/labour-deliveries',
        queryParameters: {'skip': skip, 'take': take > 100 ? 100 : take},
      );
      final data = resp.data;
      if (data == null) {
        return const LabourDeliveriesListResponse(
          labourDeliveries: [],
          total: 0,
          skip: 0,
          take: 50,
        );
      }
      return LabourDeliveriesListResponse.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const LabourDeliveriesListResponse(
          labourDeliveries: [],
          total: 0,
          skip: 0,
          take: 50,
        );
      }
      _handleError(e);
    }
  }

  Future<LabourDelivery> createLabourDelivery(
    String pregnancyId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/pregnancies/$pregnancyId/labour-deliveries',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return LabourDelivery.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<LabourDelivery> getLabourDelivery(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/labour-deliveries/$id',
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return LabourDelivery.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<LabourDelivery> getLabourDeliveryByAdmission(String admissionId) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/admissions/$admissionId/labour-delivery',
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return LabourDelivery.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<LabourDelivery> updateLabourDelivery(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/labour-deliveries/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return LabourDelivery.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Partogram ───────────────────────────────────────────────────────────

  Future<List<PartogramEntry>> listPartogram(String labourDeliveryId) async {
    try {
      final resp = await _dio.get<dynamic>(
        '$_base/labour-deliveries/$labourDeliveryId/partogram',
      );
      final data = resp.data;
      if (data == null) return [];
      final list = data is List ? data : (data['partogram'] as List? ?? []);
      return list
          .map((e) => PartogramEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PartogramEntry> addPartogramEntry(
    String labourDeliveryId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/labour-deliveries/$labourDeliveryId/partogram',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return PartogramEntry.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Babies ──────────────────────────────────────────────────────────────

  Future<BabiesListResponse> listBabies({
    String? motherId,
    String? labourDeliveryId,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/babies',
        queryParameters: {
          if (motherId != null && motherId.isNotEmpty) 'motherId': motherId,
          if (labourDeliveryId != null && labourDeliveryId.isNotEmpty)
            'labourDeliveryId': labourDeliveryId,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const BabiesListResponse(
          babies: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return BabiesListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Baby> getBaby(String id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('$_base/babies/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Baby.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Baby> createBaby(
    String labourDeliveryId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/labour-deliveries/$labourDeliveryId/babies',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Baby.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Baby> updateBaby(String id, Map<String, dynamic> body) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/babies/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Baby.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Baby> registerBabyAsPatient(
    String babyId,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/babies/$babyId/register-patient',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return Baby.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Postnatal visits ────────────────────────────────────────────────────

  Future<PostnatalVisitsListResponse> listPostnatalVisits({
    String? labourDeliveryId,
    PostnatalVisitType? type,
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/postnatal-visits',
        queryParameters: {
          if (labourDeliveryId != null && labourDeliveryId.isNotEmpty)
            'labourDeliveryId': labourDeliveryId,
          if (type != null) 'type': type.apiValue,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const PostnatalVisitsListResponse(
          visits: [],
          total: 0,
          skip: 0,
          take: 50,
        );
      }
      return PostnatalVisitsListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PostnatalVisit> getPostnatalVisit(String id) async {
    try {
      final resp =
          await _dio.get<Map<String, dynamic>>('$_base/postnatal-visits/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return PostnatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PostnatalVisit> createPostnatalVisit(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/postnatal-visits',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return PostnatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PostnatalVisit> updatePostnatalVisit(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/postnatal-visits/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return PostnatalVisit.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Gynae procedures ────────────────────────────────────────────────────

  Future<GynaeProceduresListResponse> listGynaeProcedures({
    String? patientId,
    String? procedureType,
    String? fromDate,
    String? toDate,
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '$_base/gynae-procedures',
        queryParameters: {
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          if (procedureType != null && procedureType.isNotEmpty)
            'procedureType': procedureType,
          if (fromDate != null) 'fromDate': fromDate,
          if (toDate != null) 'toDate': toDate,
          'skip': skip,
          'take': take > 100 ? 100 : take,
        },
      );
      final data = resp.data;
      if (data == null) {
        return const GynaeProceduresListResponse(
          procedures: [],
          total: 0,
          skip: 0,
          take: 20,
        );
      }
      return GynaeProceduresListResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<GynaeProcedure> getGynaeProcedure(String id) async {
    try {
      final resp =
          await _dio.get<Map<String, dynamic>>('$_base/gynae-procedures/$id');
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return GynaeProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<GynaeProcedure> createGynaeProcedure(Map<String, dynamic> body) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_base/gynae-procedures',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return GynaeProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<GynaeProcedure> updateGynaeProcedure(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final resp = await _dio.patch<Map<String, dynamic>>(
        '$_base/gynae-procedures/$id',
        data: body,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty response');
      return GynaeProcedure.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
