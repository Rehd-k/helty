/// Staff account types (mirrors Prisma AccountType enum).
enum AccountType {
  store,
  dispensary,
  other,
  frontdesk,
  consultant,
  nurse,
  lab,
  radiology,
  accounts,
  bills,
  pharmacy,
  theatere,
  ong,
  dialysis,
  staff;

  static AccountType fromString(String? value) => AccountType.values.firstWhere(
    (e) => e.name.toLowerCase() == value?.toLowerCase(),
    orElse: () => AccountType.staff,
  );
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

  String get fullName => '$firstName $lastName';

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
    id: json['id'] as String,
    staffId: json['staffId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    role: json['role'] as String,
    pharmacyRole: json['pharmacyRole'] as String? ?? json['role'] as String,
    permissions: (json['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    departmentId: json['departmentId'] as String?,
    departmentName: json['department']?['name'] as String?,
    accountType: AccountType.fromString(json['accountType'] as String?),
    email: json['email'] as String?,
    phone: json['phone']?.toString(), // API may return int or string
    isActive: (json['isActive'] as bool?) ?? true,
  );

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
  );
}
