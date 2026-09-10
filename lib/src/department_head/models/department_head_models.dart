import '../../nursing/models/nursing_models.dart';

class DepartmentStaffMember {
  const DepartmentStaffMember({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.staffRole,
    required this.accountType,
    this.email,
    this.phone,
    this.isActive = true,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String staffRole;
  final String accountType;
  final String? email;
  final String? phone;
  final bool isActive;

  String get fullName => '$firstName $lastName';

  factory DepartmentStaffMember.fromJson(Map<String, dynamic> json) {
    return DepartmentStaffMember(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      staffRole: json['staffRole']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}

class DepartmentRosterEntry {
  const DepartmentRosterEntry({
    required this.id,
    required this.staffId,
    required this.accountType,
    required this.shiftDate,
    required this.shiftType,
    this.notes,
    this.staffName,
    this.staffRole,
  });

  final String id;
  final String staffId;
  final String accountType;
  final DateTime shiftDate;
  final ShiftType shiftType;
  final String? notes;
  final String? staffName;
  final String? staffRole;

  factory DepartmentRosterEntry.fromJson(Map<String, dynamic> json) {
    final staff = json['staff'] is Map
        ? Map<String, dynamic>.from(json['staff'] as Map)
        : null;
    return DepartmentRosterEntry(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? staff?['id']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      shiftDate: DateTime.tryParse(json['shiftDate']?.toString() ?? '') ??
          DateTime.now(),
      shiftType: ShiftType.fromString(json['shiftType']?.toString()) ??
          ShiftType.morning,
      notes: json['notes']?.toString(),
      staffName: staff == null
          ? null
          : '${staff['firstName'] ?? ''} ${staff['lastName'] ?? ''}'.trim(),
      staffRole: staff?['staffRole']?.toString(),
    );
  }
}

class DepartmentRosterSummary {
  const DepartmentRosterSummary({
    required this.shiftDate,
    required this.accountType,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.scheduled,
  });

  final DateTime shiftDate;
  final String accountType;
  final List<DepartmentRosterEntry> morning;
  final List<DepartmentRosterEntry> afternoon;
  final List<DepartmentRosterEntry> night;
  final int scheduled;

  factory DepartmentRosterSummary.fromJson(Map<String, dynamic> json) {
    List<DepartmentRosterEntry> parse(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => DepartmentRosterEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return DepartmentRosterSummary(
      shiftDate: DateTime.tryParse(json['shiftDate']?.toString() ?? '') ??
          DateTime.now(),
      accountType: json['accountType']?.toString() ?? '',
      morning: parse(json['morning']),
      afternoon: parse(json['afternoon']),
      night: parse(json['night']),
      scheduled: json['scheduled'] is int
          ? json['scheduled'] as int
          : int.tryParse('${json['scheduled']}') ?? 0,
    );
  }
}
