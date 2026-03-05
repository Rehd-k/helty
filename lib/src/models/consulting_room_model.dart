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
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ConsultingRoomModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
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
}
