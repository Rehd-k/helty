import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';

/// Clinical context for antenatal orders (mirrors backend contract).
class PregnancyClinicalContext {
  const PregnancyClinicalContext({
    required this.patientId,
    required this.pregnancyId,
    required this.encounterId,
    this.antenatalVisitId,
  });

  final String patientId;
  final String pregnancyId;
  final String encounterId;
  final String? antenatalVisitId;

  static const clinicalContextKey = 'pregnancy';
}

List<T> _parseModelList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson, {
  List<String> keys = const [
    'medicationOrders',
    'medications',
    'labRequests',
    'labOrders',
    'radiologyOrders',
    'radiologyRequests',
    'orders',
    'data',
    'results',
  ],
}) {
  if (raw == null) return [];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  if (raw is Map<String, dynamic>) {
    for (final key in keys) {
      final list = raw[key];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
  }
  return [];
}

class PregnancyClinicalOrdersBundle {
  const PregnancyClinicalOrdersBundle({
    this.medicationOrders = const [],
    this.labOrders = const [],
    this.radiologyOrders = const [],
  });

  final List<MedicationOrderModel> medicationOrders;
  final List<LabOrderModel> labOrders;
  final List<RadiologyOrder> radiologyOrders;

  factory PregnancyClinicalOrdersBundle.fromJson(Map<String, dynamic> json) {
    return PregnancyClinicalOrdersBundle(
      medicationOrders: _parseModelList(
        json,
        MedicationOrderModel.fromJson,
        keys: const ['medicationOrders', 'medications'],
      ),
      labOrders: _parseModelList(
        json,
        LabOrderModel.fromJson,
        keys: const ['labRequests', 'labOrders'],
      ),
      radiologyOrders: _parseModelList(
        json,
        RadiologyOrder.fromJson,
        keys: const ['radiologyOrders', 'radiologyRequests'],
      ),
    );
  }
}

class PregnancyClinicalResultsBundle {
  const PregnancyClinicalResultsBundle({
    this.labOrders = const [],
    this.radiologyOrders = const [],
  });

  final List<LabOrderModel> labOrders;
  final List<RadiologyOrder> radiologyOrders;

  factory PregnancyClinicalResultsBundle.fromJson(Map<String, dynamic> json) {
    return PregnancyClinicalResultsBundle(
      labOrders: _parseModelList(
        json,
        LabOrderModel.fromJson,
        keys: const ['labOrders', 'labRequests', 'labs'],
      ),
      radiologyOrders: _parseModelList(
        json,
        RadiologyOrder.fromJson,
        keys: const ['radiologyOrders', 'radiologyRequests', 'radiology'],
      ),
    );
  }
}
