enum HospitalAssetKind {
  equipment('EQUIPMENT', 'Equipment'),
  machinery('MACHINERY', 'Machinery'),
  vehicle('VEHICLE', 'Vehicle'),
  furniture('FURNITURE', 'Furniture'),
  other('OTHER', 'Other');

  const HospitalAssetKind(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HospitalAssetKind fromString(String? value) {
    final k = (value ?? '').toUpperCase();
    return HospitalAssetKind.values.firstWhere(
      (e) => e.apiValue == k,
      orElse: () => HospitalAssetKind.other,
    );
  }
}

enum HospitalAssetStatus {
  inUse('IN_USE', 'In use'),
  underRepair('UNDER_REPAIR', 'Under repair'),
  decommissioned('DECOMMISSIONED', 'Decommissioned'),
  transferred('TRANSFERRED', 'Transferred');

  const HospitalAssetStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HospitalAssetStatus fromString(String? value) {
    final k = (value ?? '').toUpperCase();
    return HospitalAssetStatus.values.firstWhere(
      (e) => e.apiValue == k,
      orElse: () => HospitalAssetStatus.inUse,
    );
  }
}

enum HospitalAssetLogType {
  created('CREATED', 'Created'),
  usage('USAGE', 'Usage'),
  movement('MOVEMENT', 'Movement'),
  maintenance('MAINTENANCE', 'Maintenance'),
  statusChange('STATUS_CHANGE', 'Status change'),
  transfer('TRANSFER', 'Transfer');

  const HospitalAssetLogType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HospitalAssetLogType fromString(String? value) {
    final k = (value ?? '').toUpperCase();
    return HospitalAssetLogType.values.firstWhere(
      (e) => e.apiValue == k,
      orElse: () => HospitalAssetLogType.usage,
    );
  }
}

class HospitalAssetAccessMe {
  const HospitalAssetAccessMe({
    required this.canView,
    required this.canLog,
    required this.canManage,
    this.hospitalWide = false,
    this.viewDepartments = const [],
  });

  final bool canView;
  final bool canLog;
  final bool canManage;
  final bool hospitalWide;
  final List<String> viewDepartments;

  factory HospitalAssetAccessMe.fromJson(Map<String, dynamic> json) {
    final view = json['view'];
    return HospitalAssetAccessMe(
      canView: json['canView'] == true,
      canLog: json['canLog'] == true,
      canManage: json['canManage'] == true,
      hospitalWide: view == 'ALL',
      viewDepartments: view is List
          ? view.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class HospitalAsset {
  const HospitalAsset({
    required this.id,
    required this.name,
    required this.assetTag,
    required this.kind,
    required this.status,
    required this.accountType,
    this.serialNumber,
    this.manufacturer,
    this.model,
    this.locationNote,
    this.notes,
    this.transferredToNote,
    this.logs = const [],
  });

  final String id;
  final String name;
  final String assetTag;
  final HospitalAssetKind kind;
  final HospitalAssetStatus status;
  final String accountType;
  final String? serialNumber;
  final String? manufacturer;
  final String? model;
  final String? locationNote;
  final String? notes;
  final String? transferredToNote;
  final List<HospitalAssetLog> logs;

  factory HospitalAsset.fromJson(Map<String, dynamic> json) {
    final logsRaw = json['logs'];
    return HospitalAsset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      assetTag: json['assetTag']?.toString() ?? '',
      kind: HospitalAssetKind.fromString(json['kind']?.toString()),
      status: HospitalAssetStatus.fromString(json['status']?.toString()),
      accountType: json['accountType']?.toString() ?? '',
      serialNumber: json['serialNumber']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      model: json['model']?.toString(),
      locationNote: json['locationNote']?.toString(),
      notes: json['notes']?.toString(),
      transferredToNote: json['transferredToNote']?.toString(),
      logs: logsRaw is List
          ? logsRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      HospitalAssetLog.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class HospitalAssetLog {
  const HospitalAssetLog({
    required this.id,
    required this.type,
    this.note,
    this.fromStatus,
    this.toStatus,
    this.createdAt,
    this.createdByName,
  });

  final String id;
  final HospitalAssetLogType type;
  final String? note;
  final String? fromStatus;
  final String? toStatus;
  final DateTime? createdAt;
  final String? createdByName;

  factory HospitalAssetLog.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'] as Map)
        : null;
    return HospitalAssetLog(
      id: json['id']?.toString() ?? '',
      type: HospitalAssetLogType.fromString(json['type']?.toString()),
      note: json['note']?.toString(),
      fromStatus: json['fromStatus']?.toString(),
      toStatus: json['toStatus']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      createdByName: createdBy == null
          ? null
          : '${createdBy['firstName'] ?? ''} ${createdBy['lastName'] ?? ''}'
                .trim(),
    );
  }
}

class HospitalAssetAccessGrant {
  const HospitalAssetAccessGrant({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.canView,
    required this.canLog,
    required this.accountType,
  });

  final String id;
  final String staffId;
  final String staffName;
  final bool canView;
  final bool canLog;
  final String accountType;

  factory HospitalAssetAccessGrant.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] is Map
        ? Map<String, dynamic>.from(json['staff'] as Map)
        : null;
    return HospitalAssetAccessGrant(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? staff?['id']?.toString() ?? '',
      staffName: staff == null
          ? ''
          : '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
      canView: json['canView'] == true,
      canLog: json['canLog'] == true,
      accountType: json['accountType']?.toString() ?? '',
    );
  }
}
