class BankModel {
  final String id;
  final String name;
  final String accountNumber;
  final String? createdById;
  final String? updatedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? staffId;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? updatedBy;
  final Map<String, dynamic>? count;

  BankModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    this.createdById,
    this.updatedById,
    required this.createdAt,
    required this.updatedAt,
    this.staffId,
    this.createdBy,
    this.updatedBy,
    this.count,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String,
      createdById: json['createdById'] as String?,
      updatedById: json['updatedById'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      staffId: json['staffId'] as String?,
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      updatedBy: json['updatedBy'] as Map<String, dynamic>?,
      count: json['_count'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'createdById': createdById,
      'updatedById': updatedById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'staffId': staffId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      '_count': count,
    };
  }

  BankModel copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? createdById,
    String? updatedById,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? staffId,
    Map<String, dynamic>? createdBy,
    Map<String, dynamic>? updatedBy,
    Map<String, dynamic>? count,
  }) {
    return BankModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      createdById: createdById ?? this.createdById,
      updatedById: updatedById ?? this.updatedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffId: staffId ?? this.staffId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      count: count ?? this.count,
    );
  }
}
