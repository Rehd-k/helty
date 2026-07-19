/// Result of `POST /notifications/custom`.
class CustomPushResult {
  const CustomPushResult({
    required this.id,
    required this.targetType,
    required this.targetedPatients,
    required this.successCount,
    required this.failureCount,
  });

  final String id;
  final String targetType;
  final int targetedPatients;
  final int successCount;
  final int failureCount;

  bool get isBroadcast => targetType.toUpperCase() == 'ALL';

  factory CustomPushResult.fromJson(Map<String, dynamic> json) {
    return CustomPushResult(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetedPatients: _asInt(json['targetedPatients']),
      successCount: _asInt(json['successCount']),
      failureCount: _asInt(json['failureCount']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

const int kCustomPushTitleMaxLength = 120;
const int kCustomPushBodyMaxLength = 1000;

/// Client-side validation for the custom push form. Returns an error message or null.
String? validateCustomPushFields({
  required String title,
  required String body,
  String? imageUrl,
}) {
  final trimmedTitle = title.trim();
  final trimmedBody = body.trim();
  if (trimmedTitle.isEmpty) return 'Title is required.';
  if (trimmedTitle.length > kCustomPushTitleMaxLength) {
    return 'Title must be at most $kCustomPushTitleMaxLength characters.';
  }
  if (trimmedBody.isEmpty) return 'Message body is required.';
  if (trimmedBody.length > kCustomPushBodyMaxLength) {
    return 'Message body must be at most $kCustomPushBodyMaxLength characters.';
  }
  final url = imageUrl?.trim() ?? '';
  if (url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'Image URL must be a public HTTP(S) URL.';
    }
  }
  return null;
}
