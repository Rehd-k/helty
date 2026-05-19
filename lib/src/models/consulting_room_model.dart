class ConsultingRoomModel {
  const ConsultingRoomModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.capacity = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? location;
  final int capacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ConsultingRoomModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ConsultingRoomModel(
      id: str(json['id']),
      name: str(json['name']),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      capacity: (json['capacity'] is num)
          ? (json['capacity'] as num).toInt()
          : (int.tryParse(json['capacity']?.toString() ?? '') ?? 0),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
    'capacity': capacity,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsultingRoomModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
