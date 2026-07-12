// Models for GET /frontdesk/dashboard/summary and GET /frontdesk/dashboard/queue.

import '../core/utils/patient_initials.dart';

class FrontdeskDashboardSummary {
  const FrontdeskDashboardSummary({
    required this.asOf,
    required this.window,
    required this.appointmentsToday,
    required this.appointmentsYesterday,
    required this.appointmentsChange,
    required this.checkInsToday,
    required this.waitingRoomCount,
    required this.dischargesToday,
  });

  final DateTime asOf;
  final FrontdeskDayWindow window;
  final int appointmentsToday;
  final int appointmentsYesterday;
  final AppointmentsChange appointmentsChange;
  final int checkInsToday;
  final int waitingRoomCount;
  final int dischargesToday;

  factory FrontdeskDashboardSummary.fromJson(Map<String, dynamic> json) {
    final windowJson = json['window'] as Map<String, dynamic>?;
    return FrontdeskDashboardSummary(
      asOf: DateTime.parse(json['asOf'] as String),
      window: windowJson != null
          ? FrontdeskDayWindow.fromJson(windowJson)
          : FrontdeskDayWindow(
              start: DateTime.parse(json['asOf'] as String),
              end: DateTime.parse(json['asOf'] as String),
            ),
      appointmentsToday: (json['appointmentsToday'] as num?)?.toInt() ?? 0,
      appointmentsYesterday: (json['appointmentsYesterday'] as num?)?.toInt() ?? 0,
      appointmentsChange: AppointmentsChange.fromJson(
        json['appointmentsChange'] as Map<String, dynamic>? ?? const {},
      ),
      checkInsToday: (json['checkInsToday'] as num?)?.toInt() ?? 0,
      waitingRoomCount: (json['waitingRoomCount'] as num?)?.toInt() ?? 0,
      dischargesToday: (json['dischargesToday'] as num?)?.toInt() ?? 0,
    );
  }
}

class FrontdeskDayWindow {
  const FrontdeskDayWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory FrontdeskDayWindow.fromJson(Map<String, dynamic> json) =>
      FrontdeskDayWindow(
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
      );
}

class AppointmentsChange {
  const AppointmentsChange({this.percentChange, required this.direction});

  final double? percentChange;
  final String direction;

  factory AppointmentsChange.fromJson(Map<String, dynamic> json) =>
      AppointmentsChange(
        percentChange: json['percentChange'] == null
            ? null
            : (json['percentChange'] as num).toDouble(),
        direction: json['direction'] as String? ?? 'flat',
      );
}

class FrontdeskQueueDoctor {
  const FrontdeskQueueDoctor({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName';

  factory FrontdeskQueueDoctor.fromJson(Map<String, dynamic> json) =>
      FrontdeskQueueDoctor(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
      );
}

class FrontdeskAssignedRoom {
  const FrontdeskAssignedRoom({required this.id, required this.name});

  final String id;
  final String name;

  factory FrontdeskAssignedRoom.fromJson(Map<String, dynamic> json) =>
      FrontdeskAssignedRoom(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class FrontdeskQueueRow {
  const FrontdeskQueueRow({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.time,
    this.doctor,
    required this.status,
    this.assignedRoom,
    this.waitingPatientId,
    this.encounterId,
    this.firstName,
    this.surname,
    this.avatarUrl,
  });

  final String id;
  final String patientId;
  final String patientName;
  final DateTime time;
  final FrontdeskQueueDoctor? doctor;
  final String status;
  final FrontdeskAssignedRoom? assignedRoom;
  final String? waitingPatientId;
  final String? encounterId;
  final String? firstName;
  final String? surname;
  final String? avatarUrl;

  factory FrontdeskQueueRow.fromJson(Map<String, dynamic> json) {
    final doctorJson = json['doctor'];
    final roomJson = json['assignedRoom'];
    return FrontdeskQueueRow(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String? ?? '',
      time: DateTime.parse(json['time'] as String),
      doctor: doctorJson is Map<String, dynamic>
          ? FrontdeskQueueDoctor.fromJson(doctorJson)
          : null,
      status: json['status'] as String? ?? '',
      assignedRoom: roomJson is Map<String, dynamic>
          ? FrontdeskAssignedRoom.fromJson(roomJson)
          : null,
      waitingPatientId: json['waitingPatientId'] as String?,
      encounterId: json['encounterId'] as String?,
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      avatarUrl: avatarUrlFromJson(json),
    );
  }
}
