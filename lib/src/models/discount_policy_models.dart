class DiscountPolicy {
  DiscountPolicy({
    required this.id,
    required this.name,
    required this.reason,
    required this.mode,
    required this.value,
    required this.active,
    this.ownerStaffId,
  });

  final String id;
  final String name;
  final String reason;
  final String mode;
  final double value;
  final bool active;
  final String? ownerStaffId;

  factory DiscountPolicy.fromJson(Map<String, dynamic> json) {
    return DiscountPolicy(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      value: _asDouble(json['value']),
      active: _asBool(json['active'], fallback: true),
      ownerStaffId: _nullableString(json['ownerStaffId']),
    );
  }
}

class DiscountPolicyPayload {
  DiscountPolicyPayload({
    required this.name,
    required this.reason,
    required this.mode,
    required this.value,
    required this.active,
    this.ownerStaffId,
  });

  final String name;
  final String reason;
  final String mode;
  final double value;
  final bool active;
  final String? ownerStaffId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'reason': reason,
    'mode': mode,
    'value': value,
    'active': active,
    if (ownerStaffId != null && ownerStaffId!.trim().isNotEmpty)
      'ownerStaffId': ownerStaffId,
  };
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
