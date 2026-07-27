class ClinicalPackageItem {
  const ClinicalPackageItem({
    this.id,
    this.serviceId,
    this.drugId,
    this.serviceName,
    this.drugName,
  });

  final String? id;
  final String? serviceId;
  final String? drugId;
  final String? serviceName;
  final String? drugName;

  factory ClinicalPackageItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final drug = json['drug'] as Map<String, dynamic>?;
    return ClinicalPackageItem(
      id: json['id'] as String?,
      serviceId: json['serviceId'] as String? ?? service?['id'] as String?,
      drugId: json['drugId'] as String? ?? drug?['id'] as String?,
      serviceName: json['serviceName'] as String? ??
          service?['name'] as String? ??
          service?['serviceName'] as String?,
      drugName: json['drugName'] as String? ??
          drug?['brandName'] as String? ??
          drug?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null && id!.isNotEmpty) 'id': id,
        if (serviceId != null && serviceId!.isNotEmpty) 'serviceId': serviceId,
        if (drugId != null && drugId!.isNotEmpty) 'drugId': drugId,
      };
}

class ClinicalPackage {
  const ClinicalPackage({
    required this.id,
    required this.name,
    this.active = true,
    this.isDefaultAntenatal = false,
    this.items = const [],
  });

  final String id;
  final String name;
  final bool active;
  final bool isDefaultAntenatal;
  final List<ClinicalPackageItem> items;

  factory ClinicalPackage.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return ClinicalPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      isDefaultAntenatal: json['isDefaultAntenatal'] as bool? ?? false,
      items: list
          .map((e) => ClinicalPackageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ClinicalPackagePayload {
  const ClinicalPackagePayload({
    required this.name,
    this.active = true,
    this.isDefaultAntenatal = false,
    this.items = const [],
  });

  final String name;
  final bool active;
  final bool isDefaultAntenatal;
  final List<ClinicalPackageItem> items;

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': active,
        'isDefaultAntenatal': isDefaultAntenatal,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

/// Response from GET /clinical-packages/default-antenatal
class DefaultAntenatalPackage {
  const DefaultAntenatalPackage({
    this.packageId,
    this.name,
    this.items = const [],
  });

  final String? packageId;
  final String? name;
  final List<ClinicalPackageItem> items;

  Set<String> get serviceIds => items
      .map((e) => e.serviceId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();

  Set<String> get drugIds => items
      .map((e) => e.drugId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();

  factory DefaultAntenatalPackage.fromJson(Map<String, dynamic> json) {
    if (json['package'] is Map<String, dynamic>) {
      final pkg = ClinicalPackage.fromJson(
        json['package'] as Map<String, dynamic>,
      );
      return DefaultAntenatalPackage(
        packageId: pkg.id,
        name: pkg.name,
        items: pkg.items,
      );
    }
    final list = json['items'] as List<dynamic>? ??
        json['services'] as List<dynamic>? ??
        json['drugs'] as List<dynamic>?;
    if (list != null) {
      return DefaultAntenatalPackage(
        packageId: json['id'] as String? ?? json['packageId'] as String?,
        name: json['name'] as String?,
        items: list
            .map((e) => ClinicalPackageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    final pkg = ClinicalPackage.fromJson(json);
    return DefaultAntenatalPackage(
      packageId: pkg.id.isNotEmpty ? pkg.id : null,
      name: pkg.name,
      items: pkg.items,
    );
  }
}
