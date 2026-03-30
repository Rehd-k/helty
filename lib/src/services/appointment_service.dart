import 'package:dio/dio.dart';

import '../models/appointment_model.dart';
import 'api_service.dart';

/// Align query/body field names with your Nest `CreateAppointmentDto` / `DateRangeSkipTakeDto`.
class AppointmentService {
  AppointmentService() : _dio = ApiService().dio;
  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException('Expected JSON object');
  }

  String _message(DioException e) {
    final p = e.response?.data;
    if (p is Map && p['message'] != null) return p['message'].toString();
    return e.message ?? 'Request failed';
  }

  /// `GET /appointments` — supports skip/take + optional date window.
  Future<({List<Appointment> items, int total})> findAll({
    int skip = 0,
    int take = 20,
    DateTime? fromDate,
    DateTime? toDate,
    String? q,
  }) async {
    try {
      final resp = await _dio.get(
        '/appointments',
        queryParameters: {
          'skip': skip,
          'take': take,
          if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
          if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
          if (q != null && q.isNotEmpty) 'q': q,
        },
      );
      final raw = resp.data;
      if (raw is List) {
        final items = raw
            .map((e) => Appointment.fromJson(_asMap(e)))
            .toList();
        return (items: items, total: items.length);
      }
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final listRaw = m['appointments'] ?? m['data'] ?? m['items'] ?? m['results'];
        final total = (m['total'] as num?)?.toInt() ??
            (m['count'] as num?)?.toInt();
        final list = listRaw is List
            ? listRaw.map((e) => Appointment.fromJson(_asMap(e))).toList()
            : <Appointment>[];
        return (
          items: list,
          total: total ?? list.length,
        );
      }
      return (items: <Appointment>[], total: 0);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  /// `GET /appointments/upcoming`
  Future<List<Appointment>> getUpcomingAppointments() async {
    try {
      final resp = await _dio.get('/appointments/upcoming');
      final raw = resp.data;
      if (raw is List) {
        return raw.map((e) => Appointment.fromJson(_asMap(e))).toList();
      }
      if (raw is Map) {
        final listRaw = raw['appointments'] ?? raw['data'] ?? raw['items'];
        if (listRaw is List) {
          return listRaw.map((e) => Appointment.fromJson(_asMap(e))).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<Appointment> getAppointmentById(String id) async {
    try {
      final resp = await _dio.get('/appointments/$id');
      return Appointment.fromJson(_asMap(resp.data));
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  /// `POST /appointments` — body keys: adjust to match your `CreateAppointmentDto`
  /// (e.g. `staffId` instead of `doctorId`, or `date` instead of `appointmentDate`).
  Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    try {
      final resp = await _dio.post(
        '/appointments',
        data: {
          'patientId': patientId,
          'doctorId': doctorId,
          'appointmentDate': appointmentDate.toUtc().toIso8601String(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      final data = resp.data;
      if (data is Map) return Appointment.fromJson(_asMap(data));
      throw FormatException('Unexpected create response');
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<Appointment> updateAppointment(
    String id, {
    DateTime? appointmentDate,
    String? status,
    String? notes,
    String? doctorId,
  }) async {
    try {
      final resp = await _dio.patch(
        '/appointments/$id',
        data: {
          if (appointmentDate != null)
            'appointmentDate': appointmentDate.toUtc().toIso8601String(),
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
          if (doctorId != null) 'doctorId': doctorId,
        },
      );
      return Appointment.fromJson(_asMap(resp.data));
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await _dio.delete('/appointments/$id');
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  // ── Legacy method names (keep callers working) ───────────────────────────

  Future<List<Appointment>> fetchAppointments({
    String? query,
    String? status,
    String? patientId,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    final skip = (page - 1) * limit;
    final r = await findAll(
      skip: skip,
      take: limit,
      fromDate: date != null ? DateTime(date.year, date.month, date.day) : null,
      toDate: date != null ? DateTime(date.year, date.month, date.day, 23, 59, 59) : null,
    );
    return r.items;
  }

  Future<List<Appointment>> getTodayAppointments() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final r = await findAll(skip: 0, take: 200, fromDate: start, toDate: end);
    return r.items;
  }
}
