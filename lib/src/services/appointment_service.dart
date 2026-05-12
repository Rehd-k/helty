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
        final items = raw.map((e) => Appointment.fromJson(_asMap(e))).toList();
        return (items: items, total: items.length);
      }
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final listRaw =
            m['appointments'] ?? m['data'] ?? m['items'] ?? m['results'];
        final total =
            (m['total'] as num?)?.toInt() ?? (m['count'] as num?)?.toInt();
        final list = listRaw is List
            ? listRaw.map((e) => Appointment.fromJson(_asMap(e))).toList()
            : <Appointment>[];
        return (items: list, total: total ?? list.length);
      }
      return (items: <Appointment>[], total: 0);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  /// `GET /appointments/calendar-counts` — per-day counts for a date range.
  /// Falls back to aggregating [findAll] when the route is missing (404).
  Future<Map<DateTime, int>> getCalendarCounts({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final resp = await _dio.get(
        '/appointments/calendar-counts',
        queryParameters: {
          'fromDate': fromDate.toUtc().toIso8601String(),
          'toDate': toDate.toUtc().toIso8601String(),
        },
      );
      final raw = resp.data;
      final out = <DateTime, int>{};
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final listRaw = m['counts'] ?? m['data'] ?? m['items'];
        if (listRaw is List) {
          for (final e in listRaw) {
            if (e is! Map) continue;
            final row = Map<String, dynamic>.from(e);
            final dateStr =
                row['date']?.toString() ?? row['day']?.toString() ?? '';
            final n = row['count'] ?? row['total'];
            final c = n is num ? n.toInt() : int.tryParse(n?.toString() ?? '');
            if (dateStr.isEmpty || c == null) continue;
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              final local = parsed.toLocal();
              final key = DateTime(local.year, local.month, local.day);
              out[key] = c;
            } else {
              final parts = dateStr.split(RegExp(r'[-/]'));
              if (parts.length >= 3) {
                final y = int.tryParse(parts[0]);
                final mo = int.tryParse(parts[1]);
                final d = int.tryParse(parts[2]);
                if (y != null && mo != null && d != null) {
                  out[DateTime(y, mo, d)] = c;
                }
              }
            }
          }
        }
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _calendarCountsFallback(fromDate: fromDate, toDate: toDate);
      }
      throw Exception(_message(e));
    }
  }

  Future<Map<DateTime, int>> _calendarCountsFallback({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final out = <DateTime, int>{};
    var skip = 0;
    const take = 100;
    while (true) {
      final page = await findAll(
        skip: skip,
        take: take,
        fromDate: fromDate,
        toDate: toDate,
      );
      for (final a in page.items) {
        final d = a.appointmentDate.toLocal();
        final key = DateTime(d.year, d.month, d.day);
        out[key] = (out[key] ?? 0) + 1;
      }
      if (page.items.length < take) break;
      if (page.total > 0 && skip + page.items.length >= page.total) break;
      skip += take;
    }
    return out;
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

  /// `POST /appointments` — Prisma: `date`, `status`, `notes`, `referral`, `staffId`,
  /// `createdById`, optional `encounterId` to link this visit’s follow-up.
  Future<Appointment> createAppointment({
    required String patientId,
    required DateTime appointmentDate,
    String? staffId,

    /// Legacy body field — sent as `staffId` if [staffId] is null.
    String? doctorId,
    String status = 'SCHEDULED',
    String? notes,
    String? referral,
    String? createdById,
    String? encounterId,
  }) async {
    final assigned = staffId ?? doctorId;
    try {
      final resp = await _dio.post(
        '/appointments',
        data: {
          'patientId': patientId,
          'date': appointmentDate.toUtc().toIso8601String(),
          'appointmentDate': appointmentDate.toUtc().toIso8601String(),
          'status': status,
          if (assigned != null && assigned.isNotEmpty) 'staffId': assigned,
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (referral != null && referral.trim().isNotEmpty)
            'referral': referral.trim(),
          if (createdById != null && createdById.isNotEmpty)
            'createdById': createdById,
          if (encounterId != null && encounterId.isNotEmpty)
            'encounterId': encounterId,
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
    String? referral,
    String? staffId,
    String? doctorId,
    String? updatedById,
  }) async {
    final assigned = staffId ?? doctorId;
    try {
      final resp = await _dio.patch(
        '/appointments/$id',
        data: {
          if (appointmentDate != null) ...{
            'date': appointmentDate.toUtc().toIso8601String(),
            'appointmentDate': appointmentDate.toUtc().toIso8601String(),
          },
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
          if (referral != null) 'referral': referral,
          if (assigned != null) 'staffId': assigned,
          if (updatedById != null) 'updatedById': updatedById,
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
      toDate: date != null
          ? DateTime(date.year, date.month, date.day, 23, 59, 59)
          : null,
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
