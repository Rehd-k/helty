import 'package:helty/src/models/drug_catalog_model.dart';

class DrugCatalogService {
  static final List<DrugCatalogModel> _mock = [
    const DrugCatalogModel(id: 'D1', name: 'Paracetamol', generic: 'Paracetamol', strength: '500mg', form: 'Tablet'),
    const DrugCatalogModel(id: 'D2', name: 'Ibuprofen', generic: 'Ibuprofen', strength: '400mg', form: 'Tablet'),
    const DrugCatalogModel(id: 'D3', name: 'Amoxicillin', generic: 'Amoxicillin', strength: '500mg', form: 'Capsule'),
    const DrugCatalogModel(id: 'D4', name: 'Omeprazole', generic: 'Omeprazole', strength: '20mg', form: 'Capsule'),
    const DrugCatalogModel(id: 'D5', name: 'Loratadine', generic: 'Loratadine', strength: '10mg', form: 'Tablet'),
    const DrugCatalogModel(id: 'D6', name: 'Metformin', generic: 'Metformin', strength: '500mg', form: 'Tablet'),
  ];

  Future<List<DrugCatalogModel>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (query.trim().isEmpty) return List.from(_mock);
    final q = query.trim().toLowerCase();
    return _mock
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.generic?.toLowerCase().contains(q) ?? false))
        .toList();
  }
}
