// ignore_for_file: constant_identifier_names
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
  store,
  medical_records,
  front_desk,
  ict,
  cmd,
  cmac,
  super_admin,

  /// Unknown / legacy token not mapped to a department.
  staff;

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
      case 'inpatient_nurse':
      case 'outpatient_nurse':
      case 'nurse':
        return AccountType.nurse;
      case 'consultant':
      case 'inpatient_doctor':
        return AccountType.physician;
      case 'lab':
        return AccountType.laboratory;
      case 'frontdesk':
        return AccountType.front_desk;
      case 'other':
      case 'theatere':
      case 'ong':
      case 'dialysis':
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
    required this.role,
    this.pharmacyRole,
    this.permissions = const [],
    this.departmentId,
    this.departmentName,
    this.accountType,
    this.email,
    this.phone,
    this.isActive = true,
    /// Present on some admin / detail API responses when a forgot-password code exists.
    this.passwordResetCode,
    this.passwordResetCodeExpiresAt,
  });

  final String id;
  final String staffId;
  final String firstName;
  final String lastName;
  final String role;
  final String? pharmacyRole;
  final List<String> permissions;
  final String? departmentId;
  final String? departmentName;
  final AccountType? accountType;
  final String? email;
  final String? phone;
  final bool isActive;

  /// 6-digit (or other) code for staff password reset; read-only from API.
  final String? passwordResetCode;

  /// When [passwordResetCode] expires, if the API provides it.
  final DateTime? passwordResetCodeExpiresAt;

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

  static String? _passwordResetCodeFromJson(Map<String, dynamic> json) {
    return _optionalString(
          json['passwordResetCode'],
        ) ??
        _optionalString(json['password_reset_code']) ??
        _optionalString(json['resetCode']) ??
        _optionalString(json['reset_code']) ??
        _optionalString(json['pendingPasswordResetCode']) ??
        _optionalString(json['forgotPasswordCode']);
  }

  static DateTime? _passwordResetExpiresFromJson(Map<String, dynamic> json) {
    return _optionalDateTime(
          json['passwordResetCodeExpiresAt'],
        ) ??
        _optionalDateTime(json['password_reset_code_expires_at']) ??
        _optionalDateTime(json['passwordResetExpiresAt']) ??
        _optionalDateTime(json['resetCodeExpiresAt']);
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    final roleFromApi =
        _optionalString(json['role']) ??
        _optionalString(json['staffRole']) ??
        '';
    final pharmacyRole =
        _optionalString(json['pharmacyRole']) ??
        _optionalString(json['staffRole']) ??
        _optionalString(json['role']);

    return Staff(
      id: _requiredString(json['id']),
      staffId: _requiredString(json['staffId']),
      firstName: _requiredString(json['firstName']),
      lastName: _requiredString(json['lastName']),
      role: roleFromApi.isNotEmpty
          ? roleFromApi
          : (_optionalString(json['accountType']) ?? ''),
      pharmacyRole: pharmacyRole,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      departmentId: json['departmentId'] as String?,
      departmentName: json['department']?['name'] as String?,
      accountType: AccountType.fromString(json['accountType'] as String?),
      email: json['email'] as String?,
      phone: json['phone']?.toString(), // API may return int or string
      isActive: (json['isActive'] as bool?) ?? true,
      passwordResetCode: _passwordResetCodeFromJson(json),
      passwordResetCodeExpiresAt: _passwordResetExpiresFromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffId': staffId,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'pharmacyRole': pharmacyRole,
    'permissions': permissions,
    'departmentId': departmentId,
    'accountType': accountType?.name,
    'email': email,
    'phone': phone,
    'isActive': isActive,
  };

  Staff copyWith({
    String? id,
    String? staffId,
    String? firstName,
    String? lastName,
    String? role,
    String? pharmacyRole,
    List<String>? permissions,
    String? departmentId,
    String? departmentName,
    AccountType? accountType,
    String? email,
    String? phone,
    bool? isActive,
    String? passwordResetCode,
    DateTime? passwordResetCodeExpiresAt,
    bool clearPasswordResetCode = false,
  }) => Staff(
    id: id ?? this.id,
    staffId: staffId ?? this.staffId,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    role: role ?? this.role,
    pharmacyRole: pharmacyRole ?? this.pharmacyRole,
    permissions: permissions ?? this.permissions,
    departmentId: departmentId ?? this.departmentId,
    departmentName: departmentName ?? this.departmentName,
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
    staff.role,
    staff.accountType?.name ?? '',
  );
}
