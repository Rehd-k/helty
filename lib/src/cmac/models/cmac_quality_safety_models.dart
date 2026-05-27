enum QualitySafetyEntity { referrals, complaints, incidents, infections }

class QualitySafetyListQuery {
  const QualitySafetyListQuery({
    this.from,
    this.to,
    this.departmentId,
    this.status,
    this.skip = 0,
    this.take = 25,
  });

  final DateTime? from;
  final DateTime? to;
  final String? departmentId;
  final String? status;
  final int skip;
  final int take;

  Map<String, dynamic> toQueryParams() {
    final m = <String, dynamic>{'skip': skip, 'take': take};
    if (from != null) m['from'] = from!.toUtc().toIso8601String();
    if (to != null) m['to'] = to!.toUtc().toIso8601String();
    if (departmentId != null && departmentId!.isNotEmpty) {
      m['departmentId'] = departmentId;
    }
    if (status != null && status!.isNotEmpty) m['status'] = status;
    return m;
  }
}

class QualitySafetyRecord {
  QualitySafetyRecord({
    required this.id,
    required this.entity,
    required this.raw,
  });

  final String id;
  final QualitySafetyEntity entity;
  final Map<String, dynamic> raw;

  String get displayTitle {
    switch (entity) {
      case QualitySafetyEntity.referrals:
        return raw['reason']?.toString() ??
            raw['referringFacility']?.toString() ??
            id;
      case QualitySafetyEntity.complaints:
        return raw['category']?.toString() ?? raw['description']?.toString() ?? id;
      case QualitySafetyEntity.incidents:
        return raw['type']?.toString() ?? raw['description']?.toString() ?? id;
      case QualitySafetyEntity.infections:
        return raw['organism']?.toString() ??
            raw['infectionType']?.toString() ??
            id;
    }
  }

  String? get status => raw['status']?.toString();
  String? get patientId => raw['patientId']?.toString();
  DateTime? get createdAt {
    final v = raw['createdAt'] ?? raw['reportedAt'];
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
