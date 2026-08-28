class SystemAnnouncement {
  SystemAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    this.isActive = false,
    this.sortOrder = 0,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool isActive;
  final int sortOrder;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SystemAnnouncement.fromJson(Map<String, dynamic> json) {
    return SystemAnnouncement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'info',
      isActive: json['isActive'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class SystemAnnouncementWritePayload {
  SystemAnnouncementWritePayload({
    required this.title,
    required this.description,
    required this.iconKey,
    this.isActive,
    this.sortOrder,
    this.expiresAt,
  });

  final String title;
  final String description;
  final String iconKey;
  final bool? isActive;
  final int? sortOrder;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'iconKey': iconKey,
    if (isActive != null) 'isActive': isActive,
    if (sortOrder != null) 'sortOrder': sortOrder,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };
}
