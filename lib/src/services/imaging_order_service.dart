import 'package:helty/src/models/imaging_order_model.dart';

class ImagingOrderService {
  static final Map<String, List<ImagingOrderModel>> _byEncounter = {};

  Future<List<ImagingOrderModel>> getByEncounter(String encounterId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_byEncounter[encounterId] ?? []);
  }

  Future<ImagingOrderModel> create({
    required String encounterId,
    required String catalogId,
    required String studyName,
    String? area,
    bool contrast = false,
    String? urgency,
    String? notesToRadiologist,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final id = 'IMG-${DateTime.now().millisecondsSinceEpoch}';
    final order = ImagingOrderModel(
      id: id,
      encounterId: encounterId,
      catalogId: catalogId,
      studyName: studyName,
      area: area,
      contrast: contrast,
      urgency: urgency ?? 'Routine',
      notesToRadiologist: notesToRadiologist,
      status: 'Ordered',
    );
    _byEncounter.putIfAbsent(encounterId, () => []).add(order);
    return order;
  }
}
