// DTOs for `GET /clinical/specialties`, specialty modules, and clinical section documents.

import 'staff_attribution.dart';

class ClinicalSpecialtyCatalogModel {
  const ClinicalSpecialtyCatalogModel({
    required this.catalogVersion,
    required this.specialties,
  });

  final int catalogVersion;
  final List<CatalogSpecialtyModel> specialties;

  factory ClinicalSpecialtyCatalogModel.fromJson(Map<String, dynamic> json) {
    final raw = json['specialties'];
    final list = <CatalogSpecialtyModel>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CatalogSpecialtyModel.fromJson(e));
        } else if (e is Map) {
          list.add(CatalogSpecialtyModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    final v = json['catalogVersion'];
    return ClinicalSpecialtyCatalogModel(
      catalogVersion: v is int ? v : int.tryParse('$v') ?? 0,
      specialties: list,
    );
  }
}

class CatalogSpecialtyModel {
  const CatalogSpecialtyModel({
    required this.code,
    required this.displayName,
    this.description,
    required this.sections,
  });

  final String code;
  final String displayName;
  final String? description;
  final List<CatalogSectionModel> sections;

  factory CatalogSpecialtyModel.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    final list = <CatalogSectionModel>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CatalogSectionModel.fromJson(e));
        } else if (e is Map) {
          list.add(CatalogSectionModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CatalogSpecialtyModel(
      code: json['code']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['code']?.toString() ?? '',
      description: json['description'] as String?,
      sections: list,
    );
  }
}

/// `embedded` (default) = JSON via clinical-section API; `deep_link` = navigate elsewhere.
class CatalogSectionModel {
  const CatalogSectionModel({
    required this.key,
    required this.label,
    required this.sortOrder,
    this.exampleData,
    this.integration = 'embedded',
    this.deepLinkRoute,
  });

  final String key;
  final String label;
  final int sortOrder;
  final Map<String, dynamic>? exampleData;
  final String integration;
  final String? deepLinkRoute;

  bool get isDeepLink => integration == 'deep_link';

  factory CatalogSectionModel.fromJson(Map<String, dynamic> json) {
    final ex = json['exampleData'];
    Map<String, dynamic>? example;
    if (ex is Map<String, dynamic>) {
      example = ex;
    } else if (ex is Map) {
      example = Map<String, dynamic>.from(ex);
    }
    final so = json['sortOrder'];
    return CatalogSectionModel(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? json['key']?.toString() ?? '',
      sortOrder: so is int ? so : int.tryParse('$so') ?? 0,
      exampleData: example,
      integration: json['integration']?.toString() ?? 'embedded',
      deepLinkRoute: json['deepLinkRoute'] as String?,
    );
  }
}

class EncounterSpecialtyModuleModel {
  const EncounterSpecialtyModuleModel({
    this.id,
    this.encounterId,
    required this.specialty,
    required this.enabledSectionKeys,
  });

  /// Absent when constructing a payload for [PUT .../specialty-modules] only.
  final String? id;
  final String? encounterId;
  final String specialty;
  final List<String> enabledSectionKeys;

  factory EncounterSpecialtyModuleModel.fromJson(Map<String, dynamic> json) {
    final keysRaw = json['enabledSectionKeys'];
    final keys = <String>[];
    if (keysRaw is List) {
      for (final e in keysRaw) {
        keys.add(e.toString());
      }
    }
    return EncounterSpecialtyModuleModel(
      id: json['id']?.toString(),
      encounterId: json['encounterId']?.toString(),
      specialty: json['specialty']?.toString() ?? '',
      enabledSectionKeys: keys,
    );
  }

  Map<String, dynamic> toSyncBody() => {
        'specialty': specialty,
        'enabledSectionKeys': enabledSectionKeys,
      };
}

class EncounterClinicalSectionRowModel {
  const EncounterClinicalSectionRowModel({
    required this.encounterId,
    required this.specialty,
    required this.sectionKey,
    required this.data,
    required this.schemaVersion,
    this.updatedAt,
    this.createdByName,
  });

  final String encounterId;
  final String specialty;
  final String sectionKey;
  final Map<String, dynamic> data;
  final int schemaVersion;
  final DateTime? updatedAt;
  final String? createdByName;

  factory EncounterClinicalSectionRowModel.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    Map<String, dynamic> data = {};
    if (dataRaw is Map<String, dynamic>) {
      data = Map<String, dynamic>.from(dataRaw);
    } else if (dataRaw is Map) {
      data = Map<String, dynamic>.from(dataRaw);
    }
    final sv = json['schemaVersion'];
    return EncounterClinicalSectionRowModel(
      encounterId: json['encounterId']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      sectionKey: json['sectionKey']?.toString() ?? '',
      data: data,
      schemaVersion: sv is int ? sv : int.tryParse('$sv') ?? 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      createdByName: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
    );
  }
}
