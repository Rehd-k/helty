import 'package:helty/src/models/medication_order_model.dart';

class MedicationOrderService {
  static final Map<String, List<MedicationOrderModel>> _byEncounter = {};

  Future<List<MedicationOrderModel>> getByEncounter(String encounterId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_byEncounter[encounterId] ?? []);
  }

  Future<MedicationOrderModel> create({
    required String encounterId,
    required String drugId,
    required String drugName,
    String? dose,
    String? frequency,
    String? duration,
    String? route,
    String? specialInstructions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = 'RX-${DateTime.now().millisecondsSinceEpoch}';
    final order = MedicationOrderModel(
      id: id,
      encounterId: encounterId,
      drugId: drugId,
      drugName: drugName,
      dose: dose,
      frequency: frequency,
      duration: duration,
      route: route,
      specialInstructions: specialInstructions,
      status: 'Pending Dispense',
    );
    _byEncounter.putIfAbsent(encounterId, () => []).add(order);
    return order;
  }
}
