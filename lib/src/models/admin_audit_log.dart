class AdminAuditStaff {
  const AdminAuditStaff({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.staffRole,
    required this.accountType,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String staffRole;
  final String accountType;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    if (name.isEmpty) return staffId;
    return '$name ($staffId)';
  }

  factory AdminAuditStaff.fromJson(Map<String, dynamic> json) {
    return AdminAuditStaff(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      staffRole: json['staffRole']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
    );
  }
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.entity,
    required this.entityId,
    this.summary,
    this.route,
    this.httpMethod,
    this.ipAddress,
    this.staffRole,
    this.accountType,
    this.departmentName,
    this.oldValue,
    this.newValue,
    this.staff,
  });

  final String id;
  final DateTime createdAt;
  final String action;
  final String entity;
  final String entityId;
  final String? summary;
  final String? route;
  final String? httpMethod;
  final String? ipAddress;
  final String? staffRole;
  final String? accountType;
  final String? departmentName;
  final Object? oldValue;
  final Object? newValue;
  final AdminAuditStaff? staff;

  factory AdminAuditEntry.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'];
    return AdminAuditEntry(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      summary: _nullable(json['summary']),
      route: _nullable(json['route']),
      httpMethod: _nullable(json['httpMethod']),
      ipAddress: _nullable(json['ipAddress']),
      staffRole: _nullable(json['staffRole']),
      accountType: _nullable(json['accountType']),
      departmentName: _nullable(json['departmentName']),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      staff: staff is Map
          ? AdminAuditStaff.fromJson(Map<String, dynamic>.from(staff))
          : null,
    );
  }
}

class AdminAuditPage {
  const AdminAuditPage({required this.items, this.nextCursor});

  final List<AdminAuditEntry> items;
  final String? nextCursor;

  factory AdminAuditPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AdminAuditEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <AdminAuditEntry>[];
    return AdminAuditPage(
      items: items,
      nextCursor: _nullable(json['nextCursor']),
    );
  }
}

String? _nullable(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
