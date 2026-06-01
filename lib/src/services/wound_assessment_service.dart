import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../helper/clinical_image_picker.dart';
import '../models/wound_assessment_model.dart';
import 'api_service.dart';

class WoundAssessmentService {
  WoundAssessmentService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  Map<String, dynamic> _createFields({
    required String nurseId,
    required String woundLocation,
    required String woundSize,
    required String woundStage,
    required String exudate,
    required String odor,
    required String infectionSigns,
    DateTime? recordedAt,
  }) {
    return {
      'nurseId': nurseId,
      'woundLocation': woundLocation,
      'woundSize': woundSize,
      'woundStage': woundStage,
      'exudate': exudate,
      'odor': odor,
      'infectionSigns': infectionSigns,
      if (recordedAt != null)
        'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }

  WoundAssessmentModel _parseCreateResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw StateError('Create wound assessment returned no data');
    }
    return WoundAssessmentModel.fromJson(data);
  }

  /// GET `/admissions/:admissionId/wound-assessments`
  Future<List<WoundAssessmentModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/wound-assessments',
    );
    return _listData(response.data)
        .map((e) => WoundAssessmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/admissions/:admissionId/wound-assessments`
  ///
  /// JSON when [photo] is null; multipart with `file` part when set (Nest
  /// `FileInterceptor('file')`). Server should return `photoUrl` in the response.
  Future<WoundAssessmentModel> create({
    required String admissionId,
    required String nurseId,
    required String woundLocation,
    required String woundSize,
    required String woundStage,
    required String exudate,
    required String odor,
    required String infectionSigns,
    PickedClinicalImage? photo,
    DateTime? recordedAt,
  }) async {
    final path = '/admissions/$admissionId/wound-assessments';
    final fields = _createFields(
      nurseId: nurseId,
      woundLocation: woundLocation,
      woundSize: woundSize,
      woundStage: woundStage,
      exudate: exudate,
      odor: odor,
      infectionSigns: infectionSigns,
      recordedAt: recordedAt,
    );

    if (photo != null) {
      final formData = FormData.fromMap({
        ...fields,
        'file': await photo.toMultipartFile(),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return _parseCreateResponse(response.data);
    }

    final response = await _dio.post<Map<String, dynamic>>(path, data: fields);
    return _parseCreateResponse(response.data);
  }

  static final _photoBytesOptions = Options(
    responseType: ResponseType.bytes,
    receiveTimeout: const Duration(seconds: 60),
  );

  /// Loads wound photo bytes with auth (storage paths are not public URLs).
  ///
  /// Tries common Nest file routes, then the stored [photoUrl] path.
  Future<Uint8List> getPhotoBytes({
    required String admissionId,
    required String assessmentId,
    required String photoUrl,
  }) async {
    final stored = photoUrl.trim();
    final paths = <String>[
      '/admissions/$admissionId/wound-assessments/$assessmentId/photo',
      '/admissions/$admissionId/wound-assessments/$assessmentId/photo/file',
      '/admissions/$admissionId/wound-assessments/$assessmentId/file',
    ];

    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      paths.add(stored);
    } else {
      paths.add(stored.startsWith('/') ? stored : '/$stored');
      final withoutLeading = stored.startsWith('/')
          ? stored.substring(1)
          : stored;
      paths.add('/uploads/$withoutLeading');
    }

    DioException? lastDio;
    for (final path in paths) {
      try {
        final response = await _dio.get<List<int>>(
          path,
          options: _photoBytesOptions,
        );
        final data = response.data;
        if (data != null && data.isNotEmpty) {
          return Uint8List.fromList(data);
        }
      } on DioException catch (e) {
        lastDio = e;
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) continue;
        rethrow;
      }
    }

    if (lastDio != null) throw lastDio;
    throw StateError('Could not load wound photo');
  }
}
