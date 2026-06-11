import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/parked_billing_session.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';

enum ParkBillResult {
  success,
  duplicatePatient,
  queueFull,
}

class ParkedBillingNotifier extends StateNotifier<List<ParkedBillingSession>> {
  ParkedBillingNotifier() : super(const []);

  static const int maxSessions = 8;

  ParkBillResult park({
    required Patient patient,
    required List<ServiceModel> items,
    required ModuleRequestFlowConfig flowConfig,
    required double totalDue,
  }) {
    if (state.length >= maxSessions) return ParkBillResult.queueFull;

    final session = ParkedBillingSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      patient: patient,
      items: deepCopyServiceLines(items),
      flowConfig: flowConfig,
      parkedAt: DateTime.now(),
      totalDue: totalDue,
    );

    final key = session.patientKey;
    if (key.isNotEmpty &&
        state.any((existing) => existing.patientKey == key)) {
      return ParkBillResult.duplicatePatient;
    }

    state = [...state, session];
    return ParkBillResult.success;
  }

  void remove(String id) {
    state = state.where((session) => session.id != id).toList();
  }

  void clear() {
    state = const [];
  }

  bool hasPatient(Patient patient) {
    final key = _patientKey(patient);
    if (key.isEmpty) return false;
    return state.any((session) => session.patientKey == key);
  }

  String _patientKey(Patient patient) {
    final uuid = patient.id?.trim() ?? '';
    if (uuid.isNotEmpty) return uuid;
    return patient.patientId.trim();
  }
}

final parkedBillingProvider =
    StateNotifierProvider<ParkedBillingNotifier, List<ParkedBillingSession>>(
  (ref) => ParkedBillingNotifier(),
);

/// One-shot handoff when resuming a parked bill from outside [RenderServiceScreen].
final billingRestoreProvider = StateProvider<ParkedBillingSession?>(
  (ref) => null,
);
