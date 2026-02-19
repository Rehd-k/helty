import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  final _dio = ApiService().dio;

  Future<List<Appointment>> fetchAppointments({String? query}) async {
    final resp = await _dio.get(
      '/appointments',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    final data = resp.data as List;
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelAppointment(String id) async {
    await _dio.patch('/appointments/$id', data: {'status': 'cancelled'});
  }

  Future<void> sendMessage(String appointmentId, String method) async {
    // backend should have endpoints for messaging; placeholder
    await _dio.post(
      '/appointments/$appointmentId/message',
      data: {'method': method},
    );
  }
}
