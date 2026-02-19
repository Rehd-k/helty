import 'package:dio/dio.dart';

import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  AppointmentService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Appointment>> fetchAppointments({
    String? query,
    String? status,
    String? patientId,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/appointments',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null) 'status': status,
        if (patientId != null) 'patientId': patientId,
        if (date != null) 'date': date.toIso8601String().split('T').first,
        'page': page,
        'limit': limit,
      },
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> getAppointmentById(String id) async {
    final resp = await _dio.get('/appointments/$id');
    return Appointment.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Appointment>> getTodayAppointments() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final resp = await _dio.get(
      '/appointments',
      queryParameters: {'date': today},
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Appointment> createAppointment(Appointment a) async {
    final resp = await _dio.post('/appointments', data: a.toJson());
    return Appointment.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Appointment> updateAppointment(Appointment a) async {
    final resp = await _dio.patch('/appointments/${a.id}', data: a.toJson());
    return Appointment.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> cancelAppointment(String id) async {
    await _dio.patch('/appointments/$id', data: {'status': 'CANCELLED'});
  }

  Future<void> deleteAppointment(String id) async {
    await _dio.delete('/appointments/$id');
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  Future<void> sendMessage(String appointmentId, String method) async {
    await _dio.post(
      '/appointments/$appointmentId/message',
      data: {'method': method},
    );
  }
}
