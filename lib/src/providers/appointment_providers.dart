import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

final appointmentServiceProvider = Provider<AppointmentService>(
  (ref) => AppointmentService(),
);

final appointmentListProvider =
    FutureProvider.family<List<Appointment>, String?>((ref, query) async {
      final svc = ref.read(appointmentServiceProvider);
      return svc.fetchAppointments(query: query);
    });
