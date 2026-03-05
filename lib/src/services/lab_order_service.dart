import 'package:helty/src/models/lab_order_model.dart';

class LabOrderService {
  static final Map<String, List<LabOrderModel>> _byEncounter = {};

  Future<List<LabOrderModel>> getByEncounter(String encounterId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_byEncounter[encounterId] ?? []);
  }

  Future<LabOrderModel> create({
    required String encounterId,
    required String catalogTestId,
    required String testName,
    String? priority,
    String? clinicalNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = 'LAB-${DateTime.now().millisecondsSinceEpoch}';
    final order = LabOrderModel(
      id: id,
      encounterId: encounterId,
      catalogTestId: catalogTestId,
      testName: testName,
      priority: priority ?? 'Routine',
      clinicalNotes: clinicalNotes,
      status: 'Ordered',
    );
    _byEncounter.putIfAbsent(encounterId, () => []).add(order);
    return order;
  }
}
