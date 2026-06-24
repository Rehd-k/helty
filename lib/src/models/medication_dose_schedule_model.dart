import '../core/utils/api_decimal.dart';
import '../medications/rx_schedule_utils.dart';

/// Dose schedule state for a medication order (from API `doseSchedule` block).
class MedicationDoseScheduleModel {
  const MedicationDoseScheduleModel({
    this.scheduleStartedAt,
    this.courseEndsAt,
    this.nextDueAt,
    this.lastAdministeredAt,
    this.doseSequenceNumber = 0,
    this.scheduleStatus = MedicationScheduleStatus.notStarted,
    this.dosesPerDay,
    this.frequencyIntervalHours,
    this.durationValue,
    this.durationUnit,
    this.beyondDurationConsentAt,
    this.beyondDurationConsentById,
    this.beyondDurationConsentNote,
  });

  final DateTime? scheduleStartedAt;
  final DateTime? courseEndsAt;
  final DateTime? nextDueAt;
  final DateTime? lastAdministeredAt;
  final int doseSequenceNumber;
  final MedicationScheduleStatus scheduleStatus;
  final double? dosesPerDay;
  final double? frequencyIntervalHours;
  final int? durationValue;
  final RxDurationUnit? durationUnit;
  final DateTime? beyondDurationConsentAt;
  final String? beyondDurationConsentById;
  final String? beyondDurationConsentNote;

  bool get hasBeyondDurationConsent => beyondDurationConsentAt != null;

  bool get isNotStarted =>
      scheduleStatus == MedicationScheduleStatus.notStarted ||
      scheduleStartedAt == null;

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static double? _dec(dynamic v) => tryParseApiDecimal(v);

  factory MedicationDoseScheduleModel.fromJson(Map<String, dynamic> json) {
    final unitRaw = json['durationUnit'] ?? json['duration_unit'];
    return MedicationDoseScheduleModel(
      scheduleStartedAt: _dt(
        json['scheduleStartedAt'] ?? json['schedule_started_at'],
      ),
      courseEndsAt: _dt(json['courseEndsAt'] ?? json['course_ends_at']),
      nextDueAt: _dt(json['nextDueAt'] ?? json['next_due_at']),
      lastAdministeredAt: _dt(
        json['lastAdministeredAt'] ?? json['last_administered_at'],
      ),
      doseSequenceNumber: json['doseSequenceNumber'] is int
          ? json['doseSequenceNumber'] as int
          : int.tryParse(
                  json['doseSequenceNumber']?.toString() ??
                      json['dose_sequence_number']?.toString() ??
                      '0',
                ) ??
              0,
      scheduleStatus: MedicationScheduleStatus.fromApi(
        json['scheduleStatus']?.toString() ??
            json['schedule_status']?.toString(),
      ),
      dosesPerDay: _dec(json['dosesPerDay'] ?? json['doses_per_day']),
      frequencyIntervalHours: _dec(
        json['frequencyIntervalHours'] ?? json['frequency_interval_hours'],
      ),
      durationValue: json['durationValue'] is int
          ? json['durationValue'] as int
          : int.tryParse(
              json['durationValue']?.toString() ??
                  json['duration_value']?.toString() ??
                  '',
            ),
      durationUnit: RxDurationUnit.fromApi(unitRaw?.toString()),
      beyondDurationConsentAt: _dt(
        json['beyondDurationConsentAt'] ?? json['beyond_duration_consent_at'],
      ),
      beyondDurationConsentById: json['beyondDurationConsentById']?.toString() ??
          json['beyond_duration_consent_by_id']?.toString(),
      beyondDurationConsentNote:
          json['beyondDurationConsentNote']?.toString() ??
              json['beyond_duration_consent_note']?.toString(),
    );
  }
}

/// Row from GET `/admissions/:admissionId/medication-dose-schedules`.
class MedicationDoseScheduleItemModel {
  const MedicationDoseScheduleItemModel({
    required this.medicationOrderId,
    required this.drugName,
    this.dose,
    this.frequency,
    this.duration,
    this.administrationStatus,
    this.doseSchedule,
  });

  final String medicationOrderId;
  final String drugName;
  final String? dose;
  final String? frequency;
  final String? duration;
  final String? administrationStatus;
  final MedicationDoseScheduleModel? doseSchedule;

  factory MedicationDoseScheduleItemModel.fromJson(Map<String, dynamic> json) {
    final scheduleRaw = json['doseSchedule'] ?? json['dose_schedule'];
    return MedicationDoseScheduleItemModel(
      medicationOrderId: json['medicationOrderId']?.toString() ??
          json['medication_order_id']?.toString() ??
          '',
      drugName: json['drugName']?.toString() ??
          json['drug_name']?.toString() ??
          '',
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      administrationStatus: json['administrationStatus']?.toString() ??
          json['administration_status']?.toString(),
      doseSchedule: scheduleRaw is Map<String, dynamic>
          ? MedicationDoseScheduleModel.fromJson(scheduleRaw)
          : null,
    );
  }
}

/// Thrown when POST administration returns 409 COURSE_DURATION_EXPIRED.
class MedicationCourseDurationExpiredException implements Exception {
  MedicationCourseDurationExpiredException({
    required this.message,
    this.courseEndsAt,
    this.medicationOrderId,
  });

  final String message;
  final DateTime? courseEndsAt;
  final String? medicationOrderId;

  factory MedicationCourseDurationExpiredException.fromResponse(
    Map<String, dynamic> data,
  ) {
    return MedicationCourseDurationExpiredException(
      message: data['message']?.toString() ??
          'Prescribed duration has ended. Obtain doctor consent before administering.',
      courseEndsAt: DateTime.tryParse(data['courseEndsAt']?.toString() ?? ''),
      medicationOrderId: data['medicationOrderId']?.toString(),
    );
  }

  @override
  String toString() => message;
}
