import 'package:helty/src/models/icd10_model.dart';

/// ICD-10 search (mock list until API exists).
class Icd10Service {
  static final List<Icd10Model> _mockList = [
    const Icd10Model(code: 'A09', description: 'Infectious gastroenteritis and colitis, unspecified'),
    const Icd10Model(code: 'A15.0', description: 'Tuberculosis of lung'),
    const Icd10Model(code: 'E11.9', description: 'Type 2 diabetes mellitus without complications'),
    const Icd10Model(code: 'E78.5', description: 'Hyperlipidemia, unspecified'),
    const Icd10Model(code: 'G43.9', description: 'Migraine, unspecified'),
    const Icd10Model(code: 'I10', description: 'Essential (primary) hypertension'),
    const Icd10Model(code: 'J00', description: 'Acute nasopharyngitis [common cold]'),
    const Icd10Model(code: 'J06.9', description: 'Acute upper respiratory infection, unspecified'),
    const Icd10Model(code: 'J18.9', description: 'Pneumonia, unspecified organism'),
    const Icd10Model(code: 'K21.9', description: 'Gastro-oesophageal reflux disease without oesophagitis'),
    const Icd10Model(code: 'K29.70', description: 'Gastritis, unspecified, without bleeding'),
    const Icd10Model(code: 'M54.5', description: 'Low back pain'),
    const Icd10Model(code: 'R10.4', description: 'Other and unspecified abdominal pain'),
    const Icd10Model(code: 'R11.0', description: 'Nausea'),
    const Icd10Model(code: 'R51', description: 'Headache'),
    const Icd10Model(code: 'R53', description: 'Malaise and fatigue'),
  ];

  /// Search by code or description (case-insensitive substring).
  Future<List<Icd10Model>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (query.trim().isEmpty) return List.from(_mockList);
    final q = query.trim().toLowerCase();
    return _mockList
        .where((e) =>
            e.code.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q))
        .toList();
  }
}
