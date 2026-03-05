import '../paitients/patient_model.dart';
import 'consulting_room_model.dart';

class WaitingPatientModel {
  const WaitingPatientModel({
    required this.id,
    required this.patientId,
    required this.consultingRoomId,
    required this.createdAt,
    required this.updatedAt,
    this.patient,
    this.consultingRoom,
    this.consultationName,
    required this.status,
  });

  final String id;
  final String patientId;
  final String consultingRoomId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional expanded relations from the API
  final Patient? patient;
  final ConsultingRoomModel? consultingRoom;

  /// Convenience fields the API may expose so the UI can show
  /// "what consultation was paid for" (e.g. Cardiology, Urology).
  final String? consultationName;
  final String status;

  factory WaitingPatientModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final patientJson = json['patient'] as Map<String, dynamic>?;
    final roomJson = json['consultingRoom'] as Map<String, dynamic>?;

    return WaitingPatientModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      consultingRoomId: json['consultingRoomId'] ?? 'Unassigned',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      patient: patientJson != null ? Patient.fromJson(patientJson) : null,
      consultingRoom: roomJson != null
          ? ConsultingRoomModel.fromJson(roomJson)
          : null,
      consultationName: (json['service']['name'] ?? 'Unknown') as String?,
      status: json['consultingRoom'] != null
          ? json['consultingRoom']['name']
          : 'Waiting',
    );
  }

  /// Minimal body when creating a waiting-patient entry.
  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'consultingRoomId': consultingRoomId,
  };
}
