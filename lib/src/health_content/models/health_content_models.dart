class HealthCampaign {
  HealthCampaign({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.publishedAt,
    this.expiresAt,
    this.isPublished = false,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isPublished;

  factory HealthCampaign.fromJson(Map<String, dynamic> json) {
    return HealthCampaign(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      isPublished: json['isPublished'] == true,
    );
  }
}

class HealthNewsArticle {
  HealthNewsArticle({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.publishedAt,
    this.expiresAt,
    this.isPublished = false,
  });

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isPublished;

  factory HealthNewsArticle.fromJson(Map<String, dynamic> json) {
    return HealthNewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      isPublished: json['isPublished'] == true,
    );
  }
}

class HealthContentWritePayload {
  HealthContentWritePayload({
    required this.title,
    required this.body,
    this.imageUrl,
    this.publishedAt,
    this.expiresAt,
    this.isPublished,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool? isPublished;

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    if (imageUrl != null && imageUrl!.trim().isNotEmpty)
      'imageUrl': imageUrl!.trim(),
    if (publishedAt != null) 'publishedAt': publishedAt!.toUtc().toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    if (isPublished != null) 'isPublished': isPublished,
  };
}
