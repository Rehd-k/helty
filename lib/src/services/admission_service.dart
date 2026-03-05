import 'package:helty/src/models/admission_model.dart';

class AdmissionService {
  static final List<AdmissionModel> _list = [];

  Future<AdmissionModel> create({
    required String patientId,
    required String encounterId,
    String? reason,
    String? ward,
    String? bedPreference,
    String? provisionalDiagnosis,
    String? expectedLOS,
    bool isolationRequired = false,
    String? specialInstructions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final id = 'ADM-${DateTime.now().millisecondsSinceEpoch}';
    final admission = AdmissionModel(
      id: id,
      patientId: patientId,
      encounterId: encounterId,
      reason: reason,
      ward: ward,
      bedPreference: bedPreference,
      provisionalDiagnosis: provisionalDiagnosis,
      expectedLOS: expectedLOS,
      isolationRequired: isolationRequired,
      specialInstructions: specialInstructions,
      status: 'Pending',
    );
    _list.add(admission);
    return admission;
  }
}
