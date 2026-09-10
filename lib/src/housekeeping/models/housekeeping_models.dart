enum HousekeepingAreaKind {
  room('ROOM', 'Room'),
  ward('WARD', 'Ward'),
  corridor('CORRIDOR', 'Corridor'),
  toilet('TOILET', 'Toilet'),
  grounds('GROUNDS', 'Grounds'),
  other('OTHER', 'Other');

  const HousekeepingAreaKind(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HousekeepingAreaKind fromString(String? value) {
    final k = (value ?? '').toUpperCase();
    return HousekeepingAreaKind.values.firstWhere(
      (e) => e.apiValue == k,
      orElse: () => HousekeepingAreaKind.other,
    );
  }
}

enum HousekeepingSupplyAction {
  issued('ISSUED', 'Issued'),
  used('USED', 'Used'),
  restocked('RESTOCKED', 'Restocked');

  const HousekeepingSupplyAction(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static HousekeepingSupplyAction fromString(String? value) {
    final k = (value ?? '').toUpperCase();
    return HousekeepingSupplyAction.values.firstWhere(
      (e) => e.apiValue == k,
      orElse: () => HousekeepingSupplyAction.used,
    );
  }
}

class HousekeepingWorker {
  const HousekeepingWorker({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.isActive = true,
    this.notes,
    this.areas = const [],
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool isActive;
  final String? notes;
  final List<HousekeepingArea> areas;

  String get fullName => '$firstName $lastName';

  factory HousekeepingWorker.fromJson(Map<String, dynamic> json) {
    final assignments = json['assignments'];
    final areas = <HousekeepingArea>[];
    if (assignments is List) {
      for (final raw in assignments) {
        if (raw is! Map) continue;
        final area = raw['area'];
        if (area is Map) {
          areas.add(
            HousekeepingArea.fromJson(Map<String, dynamic>.from(area)),
          );
        }
      }
    }
    return HousekeepingWorker(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isActive: json['isActive'] != false,
      notes: json['notes']?.toString(),
      areas: areas,
    );
  }
}

class HousekeepingArea {
  const HousekeepingArea({
    required this.id,
    required this.name,
    required this.kind,
    this.isActive = true,
    this.notes,
  });

  final String id;
  final String name;
  final HousekeepingAreaKind kind;
  final bool isActive;
  final String? notes;

  factory HousekeepingArea.fromJson(Map<String, dynamic> json) {
    return HousekeepingArea(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      kind: HousekeepingAreaKind.fromString(json['kind']?.toString()),
      isActive: json['isActive'] != false,
      notes: json['notes']?.toString(),
    );
  }
}

class HousekeepingShiftEntry {
  const HousekeepingShiftEntry({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.shiftType,
    required this.shiftDate,
  });

  final String id;
  final String workerId;
  final String workerName;
  final String shiftType;
  final DateTime shiftDate;

  factory HousekeepingShiftEntry.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] is Map
        ? Map<String, dynamic>.from(json['worker'] as Map)
        : null;
    return HousekeepingShiftEntry(
      id: json['id']?.toString() ?? '',
      workerId: json['workerId']?.toString() ?? worker?['id']?.toString() ?? '',
      workerName: worker == null
          ? ''
          : '${worker['firstName'] ?? ''} ${worker['lastName'] ?? ''}'.trim(),
      shiftType: json['shiftType']?.toString() ?? '',
      shiftDate: DateTime.tryParse(json['shiftDate']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class HousekeepingSupplyLog {
  const HousekeepingSupplyLog({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.action,
    this.note,
    this.workerName,
    this.createdAt,
  });

  final String id;
  final String itemName;
  final String quantity;
  final String unit;
  final HousekeepingSupplyAction action;
  final String? note;
  final String? workerName;
  final DateTime? createdAt;

  factory HousekeepingSupplyLog.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] is Map
        ? Map<String, dynamic>.from(json['worker'] as Map)
        : null;
    return HousekeepingSupplyLog(
      id: json['id']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      action: HousekeepingSupplyAction.fromString(json['action']?.toString()),
      note: json['note']?.toString(),
      workerName: worker == null
          ? null
          : '${worker['firstName'] ?? ''} ${worker['lastName'] ?? ''}'.trim(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
