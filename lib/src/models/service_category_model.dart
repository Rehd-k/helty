/// Simple client-side representation of a service category. Mirrors
/// the backend Prisma `ServiceCategory` model.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.location,
  });

  final String id;
  final String name;
  final String? description;
  final String? location;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
      );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
  };
}
