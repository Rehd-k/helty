import '../paitients/patient_model.dart';
import 'consulting_room_model.dart';
import 'patient_vitals_model.dart';

class WaitingPatientModel {
  const WaitingPatientModel({
    required this.id,
    required this.invoiceId,
    this.invoiceDisplayId,
    required this.patientId,
    required this.consultingRoomId,
    required this.createdAt,
    required this.updatedAt,
    this.patient,
    this.consultingRoom,
    this.consultationNames = const [],
    required this.status,
    this.patientVitals,
    this.seen = false,
  });

  final String id;
  final String invoiceId;
  final String? invoiceDisplayId;
  final String patientId;
  final String consultingRoomId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional expanded relations from the API
  final Patient? patient;
  final ConsultingRoomModel? consultingRoom;

  /// Latest vitals (nurses have already recorded); may be included in API response.
  final PatientVitalsModel? patientVitals;

  /// Convenience fields the API may expose so the UI can show
  /// "what consultation was paid for" (e.g. Cardiology, Urology).
  final List<String> consultationNames;
  String? get consultationName =>
      consultationNames.isEmpty ? null : consultationNames.first;
  final String status;
  final bool seen;

  factory WaitingPatientModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final patientJson = json['patient'] is Map<String, dynamic>
        ? json['patient'] as Map<String, dynamic>
        : null;
    final roomJson = json['consultingRoom'] is Map<String, dynamic>
        ? json['consultingRoom'] as Map<String, dynamic>
        : null;
    final vitalsJson = json['vitals'] ?? json['patientVitals'];
    PatientVitalsModel? patientVitals;
    if (vitalsJson is Map<String, dynamic>) {
      try {
        patientVitals = PatientVitalsModel.fromJson(vitalsJson);
      } catch (_) {
        patientVitals = null;
      }
    }

    Patient? patient;
    if (patientJson != null) {
      try {
        patient = Patient.fromJson(patientJson);
      } catch (_) {
        patient = null;
      }
    }

    ConsultingRoomModel? consultingRoom;
    if (roomJson != null) {
      try {
        consultingRoom = ConsultingRoomModel.fromJson(roomJson);
      } catch (_) {
        consultingRoom = null;
      }
    }

    final servicesRaw = json['consultationServices'];
    final consultationNames = <String>[];
    if (servicesRaw is List) {
      for (final e in servicesRaw) {
        if (e is Map && e['name'] != null) {
          final name = e['name'].toString().trim();
          if (name.isNotEmpty) consultationNames.add(name);
        }
      }
    }
    if (consultationNames.isEmpty) {
      final service = json['service'];
      if (service is Map<String, dynamic> && service['name'] != null) {
        consultationNames.add(service['name'].toString());
      }
    }

    final roomMap = json['consultingRoom'];
    final status = (roomMap is Map<String, dynamic> && roomMap['name'] != null)
        ? roomMap['name'].toString()
        : 'Waiting';

    return WaitingPatientModel(
      id: str(json['id']),
      invoiceId: str(json['invoiceId']).isNotEmpty
          ? str(json['invoiceId'])
          : str(json['id']),
      invoiceDisplayId: str(json['invoiceID']).isNotEmpty
          ? str(json['invoiceID'])
          : null,
      patientId: str(json['patientId']),
      consultingRoomId: str(json['consultingRoomId']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      patient: patient,
      consultingRoom: consultingRoom,
      consultationNames: consultationNames,
      status: status,
      patientVitals: patientVitals,
      seen: json['seen'] == true || json['encounter'] != null,
    );
  }

  /// Minimal body when creating a waiting-patient entry.
  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceId': invoiceId,
    if (invoiceDisplayId != null) 'invoiceID': invoiceDisplayId,
    'patientId': patientId,
    'consultingRoomId': consultingRoomId,
  };
}
