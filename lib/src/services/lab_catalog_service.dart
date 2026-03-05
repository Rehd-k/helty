import 'package:helty/src/models/lab_catalog_model.dart';

class LabCatalogService {
  static final List<LabCatalogModel> _mock = [
    const LabCatalogModel(
      id: 'L1',
      name: 'FBC',
      department: 'Haematology',
      cost: 15,
      turnaround: '4h',
      sampleType: 'Blood',
    ),
    const LabCatalogModel(
      id: 'L2',
      name: 'U&E',
      department: 'Biochemistry',
      cost: 12,
      turnaround: '4h',
      sampleType: 'Blood',
    ),
    const LabCatalogModel(
      id: 'L3',
      name: 'LFT',
      department: 'Biochemistry',
      cost: 18,
      turnaround: '6h',
      sampleType: 'Blood',
    ),
    const LabCatalogModel(
      id: 'L4',
      name: 'Urinalysis',
      department: 'Lab',
      cost: 8,
      turnaround: '2h',
      sampleType: 'Urine',
    ),
    const LabCatalogModel(
      id: 'L5',
      name: 'Blood Glucose',
      department: 'Biochemistry',
      cost: 5,
      turnaround: '1h',
      sampleType: 'Blood',
    ),
  ];

  Future<List<LabCatalogModel>> list() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_mock);
  }
}
