/// Staff account types (mirrors Prisma AccountType enum).
enum AccountType {
  admin,
  staff,
  doctor,
  nurse,
  receptionist;

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
    departmentId: json['departmentId'] as String?,
    departmentName: json['department']?['name'] as String?,
    accountType: AccountType.fromString(json['accountType'] as String?),
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    isActive: (json['isActive'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'staffId': staffId,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
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
    departmentId: departmentId ?? this.departmentId,
    departmentName: departmentName ?? this.departmentName,
    accountType: accountType ?? this.accountType,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    isActive: isActive ?? this.isActive,
  );
}
