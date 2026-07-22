// Models for nursing roles API (see docs/nursing-roles-frontend-guide.md).

import '../../core/utils/patient_initials.dart';
import '../../models/nurse_dashboard_models.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum NursingUnit {
  inpatientWard('INPATIENT_WARD', 'Inpatient Ward'),
  icu('ICU', 'ICU'),
  emergency('EMERGENCY', 'Emergency'),
  opd('OPD', 'OPD'),
  ong('ONG', 'O&G');

  const NursingUnit(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static NursingUnit? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final k = value.trim().toUpperCase().replaceAll('-', '_');
    for (final u in NursingUnit.values) {
      if (u.apiValue == k || u.name.toUpperCase() == k) return u;
    }
    return null;
  }
}

enum ShiftType {
  morning('MORNING', 'Morning'),
  afternoon('AFTERNOON', 'Afternoon'),
  night('NIGHT', 'Night');

  const ShiftType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ShiftType? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final k = value.trim().toUpperCase();
    for (final s in ShiftType.values) {
      if (s.apiValue == k) return s;
    }
    return null;
  }
}

/// Normalize legacy HEAD_NURSE to MATRON.
String normalizeNursingStaffRole(String? role) {
  if (role == null || role.trim().isEmpty) return '';
  final r = role.trim().toUpperCase().replaceAll('-', '_');
  if (r == 'HEAD_NURSE') return 'MATRON';
  return r;
}

String? _nestedPersonName(Map<String, dynamic>? person) {
  if (person == null) return null;
  final first = person['firstName']?.toString().trim() ?? '';
  final last =
      (person['lastName'] ?? person['surname'])?.toString().trim() ?? '';
  final combined = [first, last].where((s) => s.isNotEmpty).join(' ');
  return combined.isEmpty ? null : combined;
}

// ── Bootstrap ────────────────────────────────────────────────────────────────

class NursingDepartmentRef {
  const NursingDepartmentRef({required this.id, required this.name});

  final String id;
  final String name;

  factory NursingDepartmentRef.fromJson(Map<String, dynamic> json) =>
      NursingDepartmentRef(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class NursingWardRef {
  const NursingWardRef({
    required this.id,
    required this.name,
    this.type,
  });

  final String id;
  final String name;
  final String? type;

  factory NursingWardRef.fromJson(Map<String, dynamic> json) => NursingWardRef(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String?,
      );
}

class NursingDashboardMe {
  const NursingDashboardMe({
    required this.staffId,
    required this.staffRole,
    required this.accountType,
    this.nursingUnit,
    this.department,
    this.ward,
    this.capabilities = const [],
    this.defaultDashboardRoute,
  });

  final String staffId;
  final String staffRole;
  final String accountType;
  final String? nursingUnit;
  final NursingDepartmentRef? department;
  final NursingWardRef? ward;
  final List<String> capabilities;
  final String? defaultDashboardRoute;

  String get normalizedStaffRole => normalizeNursingStaffRole(staffRole);

  bool hasCapability(String cap) =>
      capabilities.map((c) => c.toLowerCase()).contains(cap.toLowerCase());

  factory NursingDashboardMe.fromJson(Map<String, dynamic> json) {
    final rawCaps = json['capabilities'];
    final caps = rawCaps is List
        ? rawCaps.map((e) => e.toString()).toList()
        : <String>[];
    final dept = json['department'];
    final ward = json['ward'];
    return NursingDashboardMe(
      staffId: json['staffId']?.toString() ?? '',
      staffRole: normalizeNursingStaffRole(json['staffRole'] as String?),
      accountType: json['accountType'] as String? ?? 'NURSE',
      nursingUnit: json['nursingUnit'] as String?,
      department: dept is Map
          ? NursingDepartmentRef.fromJson(Map<String, dynamic>.from(dept))
          : null,
      ward: ward is Map
          ? NursingWardRef.fromJson(Map<String, dynamic>.from(ward))
          : null,
      capabilities: caps,
      defaultDashboardRoute: json['defaultDashboardRoute'] as String?,
    );
  }
}

// ── Extended dashboard sections ──────────────────────────────────────────────

class NursingUnitRosterCount {
  const NursingUnitRosterCount({
    required this.nursingUnit,
    this.scheduled = 0,
    this.onDuty = 0,
    this.coverageGap = 0,
    this.assignmentGap = 0,
  });

  final String nursingUnit;
  final int scheduled;
  final int onDuty;
  final int coverageGap;
  final int assignmentGap;

  factory NursingUnitRosterCount.fromJson(Map<String, dynamic> json) =>
      NursingUnitRosterCount(
        nursingUnit: json['nursingUnit'] as String? ?? '',
        scheduled: (json['scheduled'] as num?)?.toInt() ?? 0,
        onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
        coverageGap: (json['coverageGap'] as num?)?.toInt() ?? 0,
        assignmentGap: (json['assignmentGap'] as num?)?.toInt() ?? 0,
      );
}

class NursingShiftBreakdown {
  const NursingShiftBreakdown({
    required this.shiftType,
    this.scheduled = 0,
    this.onDuty = 0,
  });

  final String shiftType;
  final int scheduled;
  final int onDuty;

  factory NursingShiftBreakdown.fromJson(Map<String, dynamic> json) =>
      NursingShiftBreakdown(
        shiftType: json['shiftType'] as String? ?? '',
        scheduled: (json['scheduled'] as num?)?.toInt() ?? 0,
        onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
      );
}

class NursingMyRosterShift {
  const NursingMyRosterShift({
    this.id,
    required this.shiftDate,
    required this.shiftType,
    this.nursingUnit,
    this.wardId,
    this.wardName,
    this.wardType,
    this.notes,
    this.assignedByName,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final DateTime shiftDate;
  final String shiftType;
  final String? nursingUnit;
  final String? wardId;
  final String? wardName;
  final String? wardType;
  final String? notes;
  final String? assignedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NursingMyRosterShift.fromJson(Map<String, dynamic> json) {
    final ward = json['ward'];
    final assignedBy = json['assignedBy'];

    String? wardName;
    String? wardType;
    String? wardId = json['wardId']?.toString();
    if (ward is Map) {
      final m = Map<String, dynamic>.from(ward);
      wardName = m['name']?.toString();
      wardType = m['type']?.toString();
      wardId ??= m['id']?.toString();
    } else if (ward is String && ward.trim().isNotEmpty) {
      wardName = ward.trim();
    }
    wardName ??= json['wardName'] as String?;
    wardType ??= json['wardType'] as String?;

    String? assignedByName;
    if (assignedBy is Map) {
      assignedByName =
          _nestedPersonName(Map<String, dynamic>.from(assignedBy));
    }
    assignedByName ??= json['assignedByName'] as String?;

    return NursingMyRosterShift(
      id: json['id']?.toString(),
      shiftDate: json['shiftDate'] != null
          ? DateTime.parse(json['shiftDate'] as String)
          : DateTime.now(),
      shiftType: json['shiftType'] as String? ?? '',
      nursingUnit: json['nursingUnit'] as String?,
      wardId: wardId,
      wardName: wardName,
      wardType: wardType,
      notes: json['notes'] as String?,
      assignedByName: assignedByName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class NursingAssignedAdmission {
  const NursingAssignedAdmission({
    this.id,
    required this.admissionId,
    this.patientName = '',
    this.patientNumber,
    this.avatarUrl,
    this.wardName,
    this.bedLabel,
    this.shiftType,
    this.shiftDate,
  });

  final String? id;
  final String admissionId;
  final String patientName;
  final String? patientNumber;
  final String? avatarUrl;
  final String? wardName;
  final String? bedLabel;
  final String? shiftType;
  final DateTime? shiftDate;

  factory NursingAssignedAdmission.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    final ward = json['ward'];

    String? patientName;
    String? patientNumber;
    String? avatarUrl;
    if (patient is Map) {
      final m = Map<String, dynamic>.from(patient);
      patientName = _nestedPersonName(m);
      patientNumber = m['patientId']?.toString();
      avatarUrl = avatarUrlFromJson(m);
    }
    patientName ??= json['patientName'] as String?;
    patientNumber ??= json['patientNumber'] as String?;
    avatarUrl ??= avatarUrlFromJson(json);

    String? wardName;
    if (ward is Map) {
      wardName = Map<String, dynamic>.from(ward)['name']?.toString();
    } else if (ward is String && ward.trim().isNotEmpty) {
      wardName = ward.trim();
    }
    wardName ??= json['wardName'] as String?;

    return NursingAssignedAdmission(
      id: json['id']?.toString(),
      admissionId: json['admissionId']?.toString() ?? '',
      patientName: patientName ?? '',
      patientNumber: patientNumber,
      avatarUrl: avatarUrl,
      wardName: wardName,
      bedLabel: json['bedLabel'] as String?,
      shiftType: json['shiftType'] as String?,
      shiftDate: json['shiftDate'] != null
          ? DateTime.tryParse(json['shiftDate'] as String)
          : null,
    );
  }
}

class NursingOutpatientQueuePatient {
  const NursingOutpatientQueuePatient({
    required this.invoiceId,
    this.patientName = '',
    this.serviceName,
    this.waitingSince,
    this.nursingUnit,
  });

  final String invoiceId;
  final String patientName;
  final String? serviceName;
  final DateTime? waitingSince;
  final String? nursingUnit;

  factory NursingOutpatientQueuePatient.fromJson(Map<String, dynamic> json) =>
      NursingOutpatientQueuePatient(
        invoiceId: json['invoiceId']?.toString() ?? '',
        patientName: json['patientName'] as String? ?? '',
        serviceName: json['serviceName'] as String?,
        waitingSince: json['waitingSince'] != null
            ? DateTime.tryParse(json['waitingSince'] as String)
            : null,
        nursingUnit: json['nursingUnit'] as String?,
      );
}

/// Extended overview wrapping base dashboard + role-specific optional sections.
class NursingDashboardOverview {
  const NursingDashboardOverview({
    required this.base,
    this.dashboardType,
    this.nursingUnit,
    this.unitRosterCounts = const [],
    this.shiftBreakdown = const [],
    this.myRosterShifts = const [],
    this.assignedAdmissions = const [],
    this.outpatientQueue = const [],
    this.opdQueueDepth,
    this.bedOccupancyPercent,
  });

  final NurseDashboardOverview base;
  final String? dashboardType;
  final String? nursingUnit;
  final List<NursingUnitRosterCount> unitRosterCounts;
  final List<NursingShiftBreakdown> shiftBreakdown;
  final List<NursingMyRosterShift> myRosterShifts;
  final List<NursingAssignedAdmission> assignedAdmissions;
  final List<NursingOutpatientQueuePatient> outpatientQueue;
  final int? opdQueueDepth;
  final double? bedOccupancyPercent;

  factory NursingDashboardOverview.fromJson(Map<String, dynamic> json) {
    return NursingDashboardOverview(
      base: NurseDashboardOverview.fromJson(json),
      dashboardType: json['dashboardType'] as String?,
      nursingUnit: json['nursingUnit'] as String?,
      unitRosterCounts: _list(
        json['unitRosterCounts'],
        NursingUnitRosterCount.fromJson,
      ),
      shiftBreakdown: _list(
        json['shiftBreakdown'],
        NursingShiftBreakdown.fromJson,
      ),
      myRosterShifts: _list(
        json['myRosterShifts'],
        NursingMyRosterShift.fromJson,
      ),
      assignedAdmissions: _list(
        json['assignedAdmissions'] ?? json['inpatientAssignments'],
        NursingAssignedAdmission.fromJson,
      ),
      outpatientQueue: _list(
        json['outpatientQueue'] ?? json['outpatientAssignments'],
        NursingOutpatientQueuePatient.fromJson,
      ),
      opdQueueDepth: (json['opdQueueDepth'] as num?)?.toInt(),
      bedOccupancyPercent: (json['bedOccupancyPercent'] as num?)?.toDouble(),
    );
  }

  bool get isLineDashboard => dashboardType?.toLowerCase() == 'line';
}

// ── Roster ───────────────────────────────────────────────────────────────────

class NursingRosterEntry {
  const NursingRosterEntry({
    required this.id,
    required this.nurseId,
    required this.nursingUnit,
    required this.shiftDate,
    required this.shiftType,
    this.wardId,
    this.wardName,
    this.wardType,
    this.nurseName,
    this.nurseRole,
    this.departmentName,
    this.assignedByName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nurseId;
  final String nursingUnit;
  final DateTime shiftDate;
  final String shiftType;
  final String? wardId;
  final String? wardName;
  final String? wardType;
  final String? nurseName;
  final String? nurseRole;
  final String? departmentName;
  final String? assignedByName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NursingRosterEntry.fromJson(Map<String, dynamic> json) {
    final nurse = json['nurse'];
    final ward = json['ward'];
    final department = json['department'];
    final assignedBy = json['assignedBy'];

    String? nurseName;
    String? nurseRole;
    if (nurse is Map) {
      final m = Map<String, dynamic>.from(nurse);
      nurseName = _nestedPersonName(m);
      nurseRole = m['staffRole']?.toString();
    }
    nurseName ??= json['nurseName'] as String?;
    nurseRole ??= json['nurseRole'] as String?;

    String? wardName;
    String? wardType;
    if (ward is Map) {
      final m = Map<String, dynamic>.from(ward);
      wardName = m['name']?.toString();
      wardType = m['type']?.toString();
    }
    wardName ??= json['wardName'] as String?;
    wardType ??= json['wardType'] as String?;

    String? departmentName;
    if (department is Map) {
      departmentName =
          Map<String, dynamic>.from(department)['name']?.toString();
    }
    departmentName ??= json['departmentName'] as String?;

    String? assignedByName;
    if (assignedBy is Map) {
      assignedByName =
          _nestedPersonName(Map<String, dynamic>.from(assignedBy));
    }
    assignedByName ??= json['assignedByName'] as String?;

    return NursingRosterEntry(
      id: json['id']?.toString() ?? '',
      nurseId: json['nurseId']?.toString() ??
          (nurse is Map ? nurse['id']?.toString() : null) ??
          '',
      nursingUnit: json['nursingUnit'] as String? ?? '',
      shiftDate: json['shiftDate'] != null
          ? DateTime.parse(json['shiftDate'] as String)
          : DateTime.now(),
      shiftType: json['shiftType'] as String? ?? '',
      wardId: json['wardId']?.toString() ??
          (ward is Map ? ward['id']?.toString() : null),
      wardName: wardName,
      wardType: wardType,
      nurseName: nurseName,
      nurseRole: nurseRole,
      departmentName: departmentName,
      assignedByName: assignedByName,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'nurseId': nurseId,
    'nursingUnit': nursingUnit,
    'shiftDate': _dateOnly(shiftDate),
    'shiftType': shiftType,
    if (wardId != null && wardId!.isNotEmpty) 'wardId': wardId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };

  Map<String, dynamic> toUpdateJson() => {
    if (notes != null) 'notes': notes,
    if (shiftType.isNotEmpty) 'shiftType': shiftType,
    if (nursingUnit.isNotEmpty) 'nursingUnit': nursingUnit,
    if (wardId != null) 'wardId': wardId,
  };
}

class NursingRosterSummary {
  const NursingRosterSummary({
    required this.shiftDate,
    this.scheduled = 0,
    this.onDuty = 0,
    this.coverageGap = 0,
  });

  final DateTime shiftDate;
  final int scheduled;
  final int onDuty;
  final int coverageGap;

  factory NursingRosterSummary.fromJson(Map<String, dynamic> json) =>
      NursingRosterSummary(
        shiftDate: json['shiftDate'] != null
            ? DateTime.parse(json['shiftDate'] as String)
            : DateTime.now(),
        scheduled: (json['scheduled'] as num?)?.toInt() ?? 0,
        onDuty: (json['onDuty'] as num?)?.toInt() ?? 0,
        coverageGap: (json['coverageGap'] as num?)?.toInt() ?? 0,
      );
}

// ── Assignments ──────────────────────────────────────────────────────────────

class InpatientNurseAssignment {
  const InpatientNurseAssignment({
    required this.id,
    required this.admissionId,
    required this.nurseId,
    this.nurseName,
    this.patientName,
    this.patientNumber,
    this.avatarUrl,
    this.admissionStatus,
    this.nursingUnit,
    this.wardName,
    this.bedLabel,
    this.shiftDate,
    this.shiftType,
    this.assignedByName,
    this.assignedAt,
  });

  final String id;
  final String admissionId;
  final String nurseId;
  final String? nurseName;
  final String? patientName;
  final String? patientNumber;
  final String? avatarUrl;
  final String? admissionStatus;
  final String? nursingUnit;
  final String? wardName;
  final String? bedLabel;
  final DateTime? shiftDate;
  final String? shiftType;
  final String? assignedByName;
  final DateTime? assignedAt;

  factory InpatientNurseAssignment.fromJson(Map<String, dynamic> json) {
    final nurse = json['nurse'];
    final assignedBy = json['assignedBy'];
    final admission = json['admission'];

    Map<String, dynamic>? admissionMap;
    if (admission is Map) {
      admissionMap = Map<String, dynamic>.from(admission);
    }

    Map<String, dynamic>? patientMap;
    if (admissionMap != null && admissionMap['patient'] is Map) {
      patientMap = Map<String, dynamic>.from(admissionMap['patient'] as Map);
    }

    String? patientName;
    String? patientNumber;
    String? avatarUrl;
    if (patientMap != null) {
      patientName = _nestedPersonName(patientMap);
      patientNumber = patientMap['patientId']?.toString();
      avatarUrl = avatarUrlFromJson(patientMap);
    }
    patientName ??= json['patientName'] as String?;
    patientNumber ??= json['patientNumber'] as String?;
    avatarUrl ??= avatarUrlFromJson(json);

    String? nurseName;
    if (nurse is Map) {
      nurseName = _nestedPersonName(Map<String, dynamic>.from(nurse));
    }
    nurseName ??= json['nurseName'] as String?;

    String? assignedByName;
    if (assignedBy is Map) {
      assignedByName = _nestedPersonName(Map<String, dynamic>.from(assignedBy));
    }
    assignedByName ??= json['assignedByName'] as String?;

    String? wardName;
    String? bedLabel;
    String? admissionStatus;
    if (admissionMap != null) {
      admissionStatus = admissionMap['status']?.toString();

      final wardEntity = admissionMap['wardEntity'];
      if (wardEntity is Map) {
        wardName = wardEntity['name']?.toString();
      }
      wardName ??= admissionMap['wardName'] as String?;
      if (wardName == null && admissionMap['ward'] is Map) {
        wardName =
            (admissionMap['ward'] as Map)['name']?.toString();
      }

      final bed = admissionMap['bed'];
      if (bed is Map) {
        bedLabel = bed['bedNumber']?.toString();
      }
      bedLabel ??= admissionMap['bedPreference'] as String?;
    }
    wardName ??= json['wardName'] as String?;
    bedLabel ??= json['bedLabel'] as String?;
    admissionStatus ??= json['admissionStatus'] as String?;

    return InpatientNurseAssignment(
      id: json['id']?.toString() ?? '',
      admissionId: json['admissionId']?.toString() ??
          admissionMap?['id']?.toString() ??
          '',
      nurseId: json['nurseId']?.toString() ??
          (nurse is Map ? nurse['id']?.toString() : null) ??
          '',
      nurseName: nurseName,
      patientName: patientName,
      patientNumber: patientNumber,
      avatarUrl: avatarUrl,
      admissionStatus: admissionStatus,
      nursingUnit: json['nursingUnit'] as String?,
      wardName: wardName,
      bedLabel: bedLabel,
      shiftDate: json['shiftDate'] != null
          ? DateTime.tryParse(json['shiftDate'] as String)
          : null,
      shiftType: json['shiftType'] as String?,
      assignedByName: assignedByName,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'] as String)
          : null,
    );
  }
}

class OutpatientNurseAssignment {
  const OutpatientNurseAssignment({
    required this.id,
    required this.nurseId,
    required this.invoiceId,
    this.nurseName,
    this.patientName,
    this.nursingUnit,
    this.shiftDate,
    this.shiftType,
    this.serviceName,
  });

  final String id;
  final String nurseId;
  final String invoiceId;
  final String? nurseName;
  final String? patientName;
  final String? nursingUnit;
  final DateTime? shiftDate;
  final String? shiftType;
  final String? serviceName;

  factory OutpatientNurseAssignment.fromJson(Map<String, dynamic> json) =>
      OutpatientNurseAssignment(
        id: json['id']?.toString() ?? '',
        nurseId: json['nurseId']?.toString() ?? '',
        invoiceId: json['invoiceId']?.toString() ?? '',
        nurseName: json['nurseName'] as String?,
        patientName: json['patientName'] as String?,
        nursingUnit: json['nursingUnit'] as String?,
        shiftDate: json['shiftDate'] != null
            ? DateTime.tryParse(json['shiftDate'] as String)
            : null,
        shiftType: json['shiftType'] as String?,
        serviceName: json['serviceName'] as String?,
      );
}

class InpatientAssignmentsResponse {
  const InpatientAssignmentsResponse({
    required this.assignments,
    this.total = 0,
  });

  final List<InpatientNurseAssignment> assignments;
  final int total;

  factory InpatientAssignmentsResponse.fromJson(Map<String, dynamic> json) =>
      InpatientAssignmentsResponse(
        assignments: _list(
          json['assignments'] ?? json['items'] ?? json['data'],
          InpatientNurseAssignment.fromJson,
        ),
        total: (json['total'] as num?)?.toInt() ??
            _list(
              json['assignments'] ?? json['items'] ?? json['data'],
              InpatientNurseAssignment.fromJson,
            ).length,
      );
}

class OutpatientAssignmentsResponse {
  const OutpatientAssignmentsResponse({
    required this.assignments,
    this.total = 0,
  });

  final List<OutpatientNurseAssignment> assignments;
  final int total;

  factory OutpatientAssignmentsResponse.fromJson(Map<String, dynamic> json) =>
      OutpatientAssignmentsResponse(
        assignments: _list(
          json['assignments'] ?? json['items'] ?? json['data'],
          OutpatientNurseAssignment.fromJson,
        ),
        total: (json['total'] as num?)?.toInt() ??
            _list(
              json['assignments'] ?? json['items'] ?? json['data'],
              OutpatientNurseAssignment.fromJson,
            ).length,
      );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .toList();
}

String _dateOnly(DateTime dt) {
  final d = dt.toUtc();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
