import 'package:helty/src/models/imaging_catalog_model.dart';

class ImagingCatalogService {
  static final List<ImagingCatalogModel> _mock = [
    const ImagingCatalogModel(id: 'I1', name: 'Chest X-ray', area: 'Chest', cost: 35),
    const ImagingCatalogModel(id: 'I2', name: 'Abdominal X-ray', area: 'Abdomen', cost: 35),
    const ImagingCatalogModel(id: 'I3', name: 'CT Head', area: 'Head', contrastAvailable: true, cost: 120),
    const ImagingCatalogModel(id: 'I4', name: 'CT Chest', area: 'Chest', contrastAvailable: true, cost: 150),
    const ImagingCatalogModel(id: 'I5', name: 'Ultrasound Abdomen', area: 'Abdomen', cost: 60),
    const ImagingCatalogModel(id: 'I6', name: 'MRI Spine', area: 'Spine', cost: 200),
  ];

  Future<List<ImagingCatalogModel>> list() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_mock);
  }
}
