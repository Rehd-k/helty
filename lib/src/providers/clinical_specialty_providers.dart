import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/clinical_specialty_models.dart';
import '../services/clinical_specialty_service.dart';

final clinicalSpecialtyServiceProvider = Provider<ClinicalSpecialtyService>((ref) {
  return ClinicalSpecialtyService();
});

/// Cached catalog; invalidate after `catalogVersion` changes on server if needed.
final clinicalSpecialtyCatalogProvider =
    FutureProvider<ClinicalSpecialtyCatalogModel>((ref) async {
  final svc = ref.watch(clinicalSpecialtyServiceProvider);
  return svc.fetchCatalog();
});

/// Modules enabled on an encounter (refetch after wizard sync).
final encounterSpecialtyModulesProvider =
    FutureProvider.family<List<EncounterSpecialtyModuleModel>, String>((
  ref,
  encounterId,
) async {
  final svc = ref.watch(clinicalSpecialtyServiceProvider);
  return svc.listModules(encounterId);
});

/// Clinical section rows for an encounter (optionally filtered).
final encounterClinicalSectionsProvider = FutureProvider.family<
    List<EncounterClinicalSectionRowModel>,
    EncounterClinicalSectionsQuery>((ref, query) async {
  final svc = ref.watch(clinicalSpecialtyServiceProvider);
  return svc.listSections(
    query.encounterId,
    specialty: query.specialty,
    keys: query.keys,
  );
});

class EncounterClinicalSectionsQuery {
  const EncounterClinicalSectionsQuery({
    required this.encounterId,
    this.specialty,
    this.keys,
  });

  final String encounterId;
  final String? specialty;
  final List<String>? keys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncounterClinicalSectionsQuery &&
          runtimeType == other.runtimeType &&
          encounterId == other.encounterId &&
          specialty == other.specialty &&
          _listEq(keys, other.keys);

  @override
  int get hashCode =>
      Object.hash(encounterId, specialty, keys?.join(',') ?? '');

  static bool _listEq(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
