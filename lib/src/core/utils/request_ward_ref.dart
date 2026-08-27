/// Lightweight ward snapshot returned on request list payloads.
class RequestWardRef {
  const RequestWardRef({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory RequestWardRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RequestWardRef(id: '', name: '');
    }
    return RequestWardRef(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? '').trim(),
    );
  }

  /// Display label for waiting queues: ward name at request time, or OPD.
  String get displayLabel {
    if (name.isNotEmpty) return name;
    return 'OPD';
  }

  static String labelFrom({
    RequestWardRef? ward,
    String? wardId,
  }) {
    final name = ward?.name.trim() ?? '';
    if (name.isNotEmpty) return name;
    // wardId alone is not a display name; treat missing name as OPD.
    return 'OPD';
  }
}
