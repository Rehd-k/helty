// ignore_for_file: constant_identifier_names

import '../nursing/ward_matching.dart';
import 'staff_attribution.dart';

/// Staff account types (mirrors backend `AccountType` — department-level).
///
/// Serialized to API as [name] in UPPER_SNAKE (e.g. [billing] → `BILLING`).
enum AccountType {
  billing,
  accounting,
  hmo,
  pharmacy,
  nurse,
  physician,
  laboratory,
  radiology,
  dialysis,
  theatre,
  store,
  purchases,
  medical_records,
  front_desk,
  ict,
  cmd,
  cmac,
  super_admin,

  /// Unknown / legacy token not mapped to a department.
  staff;

  /// Backend `AccountType` enum values (excludes legacy [staff]).
  static const List<AccountType> departmentTypes = [
    billing,
    accounting,
    pharmacy,
    nurse,
    physician,
    laboratory,
    radiology,
    store,
    medical_records,
    front_desk,
    ict,
    cmd,
    cmac,
    hmo,
    purchases,
    dialysis,
    theatre,
    super_admin,
  ];

  /// Serialized to the API as UPPER_SNAKE (e.g. `BILLING`).
  String get apiValue => name.toUpperCase();

  /// Human-readable label for forms.
  String get label => switch (this) {
    billing => 'Billing',
    accounting => 'Accounting',
    pharmacy => 'Pharmacy',
    nurse => 'Nurse',
    physician => 'Physician',
    laboratory => 'Laboratory',
    radiology => 'Radiology',
    store => 'Store',
    medical_records => 'Medical Records',
    front_desk => 'Front Desk',
    ict => 'ICT',
    cmd => 'CMD',
    cmac => 'CMAC',
    hmo => 'HMO',
    purchases => 'Purchases',
    dialysis => 'Dialysis',
    theatre => 'Theatre',
    super_admin => 'Super Admin',
    staff => 'Staff (legacy)',
  };

  bool get isDepartmentType => departmentTypes.contains(this);

  static AccountType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return AccountType.staff;
    final k = value.trim().toLowerCase().replaceAll('-', '_');

    for (final e in AccountType.values) {
      if (e.name == k) return e;
    }

    // Legacy API values → current enum
    switch (k) {
      case 'bills':
        return AccountType.billing;
      case 'accounts':
        return AccountType.accounting;
      case 'hmo':
      case 'hmo_desk':
        return AccountType.hmo;
      case 'pharmacy_store':
      case 'pharmacy_dispensary':
      case 'pharmacy_head':
      case 'pharmacy':
      case 'dispensary':
        return AccountType.pharmacy;
      case 'head_nurse':
      case 'matron':
      case 'ward_charge_nurse':
      case 'icu_charge_nurse':
      case 'emergency_charge_nurse':
      case 'opd_charge_nurse':
      case 'ong_charge_nurse':
      case 'inpatient_nurse':
      case 'emergency_nurse':
      case 'icu_nurse':
      case 'ong_nurse':
      case 'outpatient_nurse':
      case 'nurse':
        return AccountType.nurse;
      case 'consultant':
      case 'inpatient_doctor':
        return AccountType.physician;
      case 'lab':
        return AccountType.laboratory;
      case 'dialysis':
        return AccountType.dialysis;
      case 'theatre':
        return AccountType.theatre;
      case 'purchases_store':
      case 'purchases_head':
      case 'purchases':
        return AccountType.purchases;
      case 'frontdesk':
        return AccountType.front_desk;
      case 'other':
      case 'theatere':
      case 'ong':
        return AccountType.staff;
      default:
        return AccountType.staff;
    }
  }
}

/// Maps the Prisma `Staff` model from the backend schema.
class Staff {
  const Staff({
    required this.id,
    required this.staffId,
    required this.firstName,
    required this.lastName,
    required this.staffRole,
    this.pharmacyRole,
    this.permissions = const [],
    this.departmentId,
    this.departmentName,
    this.wardId,
    this.wardName,
    this.accountType,
    this.email,
    this.phone,
    this.isActive = true,
    /// Present on some admin / detail API responses when a forgot-password code exists.
    this.passwordResetCode,
    this.passwordResetCodeExpiresAt,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String staffRole;
  final String? pharmacyRole;
  final List<String> permissions;
  final String? departmentId;
  final String? departmentName;
  final String? wardId;
  final String? wardName;
  final AccountType? accountType;
  final String? email;
  final String? phone;
  final bool isActive;

  /// 6-digit (or other) code for staff password reset; read-only from API.
  final String? passwordResetCode;

  /// When [passwordResetCode] expires, if the API provides it.
  final DateTime? passwordResetCodeExpiresAt;

  final String? createdByName;
  final String? updatedByName;

  String get fullName => '$firstName $lastName';

  bool get hasActivePasswordResetCode =>
      passwordResetCode != null && passwordResetCode!.trim().isNotEmpty;

  static String? _optionalString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static String _requiredString(dynamic v, [String fallback = '']) {
    final s = _optionalString(v);
    return (s == null || s.isEmpty) ? fallback : s;
  }

  static DateTime? _optionalDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Top-level reset fields, or the latest non-expired entry in [passwordResets].
  static ({String code, DateTime? expiresAt})? _passwordResetFromJson(
    Map<String, dynamic> json,
  ) {
    final topCode =
        _optionalString(json['passwordResetCode']) ??
        _optionalString(json['password_reset_code']) ??
        _optionalString(json['resetCode']) ??
        _optionalString(json['reset_code']) ??
        _optionalString(json['pendingPasswordResetCode']) ??
        _optionalString(json['forgotPasswordCode']);
    if (topCode != null && topCode.trim().isNotEmpty) {
      return (
        code: topCode.trim(),
        expiresAt:
            _optionalDateTime(json['passwordResetCodeExpiresAt']) ??
            _optionalDateTime(json['password_reset_code_expires_at']) ??
            _optionalDateTime(json['passwordResetExpiresAt']) ??
            _optionalDateTime(json['resetCodeExpiresAt']),
      );
    }
    return _activePasswordResetFromResets(json);
  }

  static ({String code, DateTime? expiresAt})? _activePasswordResetFromResets(
    Map<String, dynamic> json,
  ) {
    final resets = json['passwordResets'] ?? json['password_resets'];
    if (resets is! List || resets.isEmpty) return null;

    final now = DateTime.now().toUtc();
    ({String code, DateTime? expiresAt, DateTime createdAt})? best;

    for (final raw in resets) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final code =
          _optionalString(m['code']) ??
          _optionalString(m['resetCode']) ??
          _optionalString(m['reset_code']);
      if (code == null || code.trim().isEmpty) continue;

      final expiresAt =
          _optionalDateTime(m['expiresAt']) ??
          _optionalDateTime(m['expires_at']);
      if (expiresAt != null && !expiresAt.toUtc().isAfter(now)) continue;

      final createdAt =
          _optionalDateTime(m['createdAt']) ??
          _optionalDateTime(m['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

      final candidate = (
        code: code.trim(),
        expiresAt: expiresAt,
        createdAt: createdAt,
      );

      if (best == null) {
        best = candidate;
        continue;
      }

      final bestExpiry = best.expiresAt ?? DateTime.utc(9999, 12, 31);
      final candidateExpiry = candidate.expiresAt ?? DateTime.utc(9999, 12, 31);
      if (candidateExpiry.isAfter(bestExpiry)) {
        best = candidate;
      } else if (candidateExpiry == bestExpiry &&
          candidate.createdAt.isAfter(best.createdAt)) {
        best = candidate;
      }
    }

    if (best == null) return null;
    return (code: best.code, expiresAt: best.expiresAt);
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    final staffRoleFromApi =
        _optionalString(json['staffRole']) ??
        _optionalString(json['role']) ??
        '';
    final pharmacyRole =
        _optionalString(json['pharmacyRole']) ??
        _optionalString(json['staffRole']) ??
        _optionalString(json['role']);
    final passwordReset = _passwordResetFromJson(json);

    return Staff(
      id: _requiredString(json['id']),
      staffId: _requiredString(json['staffId']),
      firstName: _requiredString(json['firstName']),
      lastName: _requiredString(json['lastName']),
      staffRole: staffRoleFromApi.isNotEmpty
          ? staffRoleFromApi
          : (_optionalString(json['accountType']) ?? ''),
      pharmacyRole: pharmacyRole,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      departmentId: json['departmentId'] as String?,
      departmentName: json['department']?['name'] as String?,
      wardId: _optionalString(json['wardId']),
      wardName: json['ward'] is Map
          ? (json['ward'] as Map)['name'] as String?
          : null,
      accountType: AccountType.fromString(json['accountType'] as String?),
      email: json['email'] as String?,
      phone: json['phone']?.toString(), // API may return int or string
      isActive: (json['isActive'] as bool?) ?? true,
      passwordResetCode: passwordReset?.code,
      passwordResetCodeExpiresAt: passwordReset?.expiresAt,
      createdByName: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
      updatedByName: formatStaffName(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffId': staffId,
    'firstName': firstName,
    'lastName': lastName,
    'staffRole': staffRole,
    'pharmacyRole': pharmacyRole,
    'permissions': permissions,
    'departmentId': departmentId,
    'wardId': wardId,
    'accountType': accountType?.apiValue,
    'email': email,
    'phone': phone,
    'isActive': isActive,
  };

  /// Payload for POST/PATCH `/staff` with nursing role assignment rules applied.
  Map<String, dynamic> toStaffWriteJson() {
    final role = staffRole.trim().toUpperCase().replaceAll('-', '_');
    final isCharge = isChargeNurseStaffRole(role);
    final isMatron = role == 'MATRON' || role == 'HEAD_NURSE';

    final map = <String, dynamic>{
      'id': id,
      'staffId': staffId,
      'firstName': firstName,
      'lastName': lastName,
      'staffRole': staffRole,
      if (pharmacyRole != null) 'pharmacyRole': pharmacyRole,
      'permissions': permissions,
      if (accountType != null) 'accountType': accountType!.apiValue,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'isActive': isActive,
    };

    if (isCharge) {
      if (wardId != null && wardId!.trim().isNotEmpty) {
        map['wardId'] = wardId;
      } else {
        map['wardId'] = null;
      }
    } else if (isMatron) {
      map['wardId'] = null;
      map['departmentId'] = null;
    } else {
      map['departmentId'] = departmentId;
      if (wardId == null || wardId!.trim().isEmpty) {
        map['wardId'] = null;
      } else {
        map['wardId'] = wardId;
      }
    }

    return map;
  }

  Staff copyWith({
    String? id,
    String? staffId,
    String? firstName,
    String? lastName,
    String? staffRole,
    String? pharmacyRole,
    List<String>? permissions,
    String? departmentId,
    String? departmentName,
    String? wardId,
    String? wardName,
    AccountType? accountType,
    String? email,
    String? phone,
    bool? isActive,
    String? passwordResetCode,
    DateTime? passwordResetCodeExpiresAt,
    String? createdByName,
    String? updatedByName,
    bool clearPasswordResetCode = false,
    bool clearDepartmentId = false,
    bool clearWardId = false,
  }) => Staff(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    staffRole: staffRole ?? this.staffRole,
    pharmacyRole: pharmacyRole ?? this.pharmacyRole,
    permissions: permissions ?? this.permissions,
    departmentId: clearDepartmentId ? null : (departmentId ?? this.departmentId),
    departmentName:
        clearDepartmentId ? null : (departmentName ?? this.departmentName),
    wardId: clearWardId ? null : (wardId ?? this.wardId),
    wardName: clearWardId ? null : (wardName ?? this.wardName),
    accountType: accountType ?? this.accountType,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    isActive: isActive ?? this.isActive,
    passwordResetCode: clearPasswordResetCode
        ? null
        : (passwordResetCode ?? this.passwordResetCode),
    passwordResetCodeExpiresAt: clearPasswordResetCode
        ? null
        : (passwordResetCodeExpiresAt ?? this.passwordResetCodeExpiresAt),
    createdByName: createdByName ?? this.createdByName,
    updatedByName: updatedByName ?? this.updatedByName,
  );
}

/// Billing analytics dashboard, transaction change-date, and refund actions.
///
/// Allowed: [AccountType.super_admin], role `super_admin`, `billing_head`,
/// `account_head`.
bool staffCanAccessPrivilegedBillingStrings(
  String role,
  String accountTypeApiValue,
) {
  final at = AccountType.fromString(accountTypeApiValue);
  if (at == AccountType.super_admin) return true;
  final r = role.trim().toLowerCase().replaceAll('-', '_');
  if (r == 'super_admin') return true;
  if (r == 'billing_head') return true;
  if (r == 'account_head') return true;
  return false;
}

bool staffCanAccessPrivilegedBilling(Staff? staff) {
  if (staff == null) return false;
  return staffCanAccessPrivilegedBillingStrings(
    staff.staffRole,
    staff.accountType?.name ?? '',
  );
}
