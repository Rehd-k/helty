// ignore_for_file: constant_identifier_names

import 'package:helty/src/core/utils/patient_display_name.dart';
import 'package:helty/src/core/utils/patient_initials.dart';
import 'package:helty/src/models/staff_attribution.dart';

/// Pregnancy status (exact API strings).
enum PregnancyStatus {
  ONGOING,
  DELIVERED,
  LOST,
  TERMINATED;

  String get apiValue => name;

  static PregnancyStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in PregnancyStatus.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// Fetal presentation (antenatal).
enum FetalPresentation {
  CEPHALIC,
  BREECH,
  TRANSVERSE,
  UNKNOWN;

  String get apiValue => name;

  static FetalPresentation? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in FetalPresentation.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// Delivery mode.
enum DeliveryMode {
  SVD,
  ASSISTED_VAGINAL,
  CS_ELECTIVE,
  CS_EMERGENCY,
  BREECH,
  TWIN,
  OTHER;

  String get apiValue => name;

  static DeliveryMode? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in DeliveryMode.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// Delivery outcome.
enum DeliveryOutcome {
  LIVE_BIRTH,
  STILLBIRTH,
  OTHER;

  String get apiValue => name;

  static DeliveryOutcome? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in DeliveryOutcome.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// Baby sex.
enum BabySex {
  M,
  F,
  U;

  String get apiValue => name;

  static BabySex? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in BabySex.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

/// Postnatal visit type.
enum PostnatalVisitType {
  MOTHER,
  BABY;

  String get apiValue => name;

  static PostnatalVisitType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in PostnatalVisitType.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

// ─── Nested patient (from API) ─────────────────────────────────────────────

class ObstetricsPatientRef {
  const ObstetricsPatientRef({
    required this.id,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
    this.avatarUrl,
  });

  final String id;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;
  final String? avatarUrl;

  String get displayName => patientDisplayNameFromJson({
        'title': title,
        'firstName': firstName,
        'otherName': otherName,
        'surname': surname,
      });

  factory ObstetricsPatientRef.fromJson(Map<String, dynamic> json) {
    return ObstetricsPatientRef(
      id: json['id'] as String,
      title: json['title'] as String?,
      firstName: json['firstName'] as String?,
      otherName: json['otherName'] as String?,
      surname: (json['surname'] ?? json['lastName']) as String?,
      avatarUrl: avatarUrlFromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (title != null) 'title': title,
        if (firstName != null) 'firstName': firstName,
        if (otherName != null) 'otherName': otherName,
        if (surname != null) 'surname': surname,
      };
}

// ─── Pregnancy ───────────────────────────────────────────────────────────

// ─── Pregnancy ─────────────────────────────────────────────────────────────

const kBloodGroupOptions = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

const kGenotypeOptions = ['AA', 'AS', 'SS', 'AC', 'SC'];

/// Serology screen results (HCV, HBsAg, VDRL, HIV).
const kSerologyResultOptions = ['Negative', 'Positive', 'Indeterminate'];

class Pregnancy {
  const Pregnancy({
    required this.id,
    required this.patientId,
    required this.gravida,
    required this.para,
    required this.lmp,
    required this.edd,
    this.bookingDate,
    this.status,
    this.outcome,
    this.respiratoryRate,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.spo2,
    this.genotype,
    this.bloodGroup,
    this.pcv,
    this.hcv,
    this.hbsAg,
    this.vdrl,
    this.hiv12,
    this.urinalysisProtein,
    this.urinalysisGlucose,
    this.ttImmunization,
    this.patient,
    this.antenatalVisits,
    this.labourDeliveries,
    this.pregnancyId,
    this.encounterId,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String? pregnancyId; // some APIs use pregnancyId
  final String? encounterId;
  final String patientId;
  final int gravida;
  final int para;
  final String lmp;
  final String edd;
  final String? bookingDate;
  final PregnancyStatus? status;
  final String? outcome;
  final int? respiratoryRate;
  final int? heartRate;
  final int? systolicBP;
  final int? diastolicBP;
  final double? spo2;
  final String? genotype;
  final String? bloodGroup;
  final double? pcv;
  final String? hcv;
  final String? hbsAg;
  final String? vdrl;
  final String? hiv12;
  final String? urinalysisProtein;
  final String? urinalysisGlucose;
  final String? ttImmunization;
  final ObstetricsPatientRef? patient;
  final List<AntenatalVisit>? antenatalVisits;
  final List<LabourDelivery>? labourDeliveries;
  final String? createdByName;
  final String? updatedByName;

  factory Pregnancy.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['pregnancyId'] as String? ?? '';
    final encounterRaw = json['encounter'];
    final nestedEncounterId = encounterRaw is Map<String, dynamic>
        ? encounterRaw['id'] as String?
        : null;
    return Pregnancy(
      id: id,
      pregnancyId: json['pregnancyId'] as String?,
      encounterId:
          json['encounterId'] as String? ?? nestedEncounterId,
      patientId: json['patientId'] as String,
      gravida: (json['gravida'] as num?)?.toInt() ?? 0,
      para: (json['para'] as num?)?.toInt() ?? 0,
      lmp: json['lmp'] as String? ?? '',
      edd: json['edd'] as String? ?? '',
      bookingDate: json['bookingDate'] as String?,
      status: PregnancyStatus.fromString(json['status'] as String?),
      outcome: json['outcome'] as String?,
      respiratoryRate: (json['respiratoryRate'] as num?)?.toInt(),
      heartRate: (json['heartRate'] as num?)?.toInt(),
      systolicBP: (json['systolicBP'] as num?)?.toInt(),
      diastolicBP: (json['diastolicBP'] as num?)?.toInt(),
      spo2: (json['spo2'] as num?)?.toDouble(),
      genotype: json['genotype'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      pcv: (json['pcv'] as num?)?.toDouble(),
      hcv: json['hcv'] as String?,
      hbsAg: json['hbsAg'] as String?,
      vdrl: json['vdrl'] as String?,
      hiv12: json['hiv12'] as String?,
      urinalysisProtein: json['urinalysisProtein'] as String?,
      urinalysisGlucose: json['urinalysisGlucose'] as String?,
      ttImmunization: json['ttImmunization'] as String?,
      patient: json['patient'] != null
          ? ObstetricsPatientRef.fromJson(
              json['patient'] as Map<String, dynamic>)
          : null,
      antenatalVisits: (json['antenatalVisits'] as List<dynamic>?)
          ?.map((e) => AntenatalVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      labourDeliveries: (json['labourDeliveries'] as List<dynamic>?)
          ?.map((e) => LabourDelivery.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdByName: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
      updatedByName: formatStaffName(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'gravida': gravida,
        'para': para,
        'lmp': lmp,
        'edd': edd,
        if (bookingDate != null) 'bookingDate': bookingDate,
        if (status != null) 'status': status!.apiValue,
        if (outcome != null) 'outcome': outcome,
        if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
        if (heartRate != null) 'heartRate': heartRate,
        if (systolicBP != null) 'systolicBP': systolicBP,
        if (diastolicBP != null) 'diastolicBP': diastolicBP,
        if (spo2 != null) 'spo2': spo2,
        if (genotype != null) 'genotype': genotype,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (pcv != null) 'pcv': pcv,
        if (hcv != null) 'hcv': hcv,
        if (hbsAg != null) 'hbsAg': hbsAg,
        if (vdrl != null) 'vdrl': vdrl,
        if (hiv12 != null) 'hiv12': hiv12,
        if (urinalysisProtein != null) 'urinalysisProtein': urinalysisProtein,
        if (urinalysisGlucose != null) 'urinalysisGlucose': urinalysisGlucose,
        if (ttImmunization != null) 'ttImmunization': ttImmunization,
      };
}

// ─── Antenatal visit ───────────────────────────────────────────────────────

/// Fetal head descent options (palpable abdominally).
const kFetalDescentOptions = ['1/5', '2/5', '3/5', '4/5', '5/5'];

/// Urine dipstick result options (protein and glucose).
const kUrineDipstickOptions = ['Negative', 'Trace', '1+', '2+', '3+'];

class AntenatalVisit {
  const AntenatalVisit({
    required this.id,
    required this.pregnancyId,
    required this.visitDate,
    required this.staffId,
    this.gestationWeeks,
    this.gestationDays,
    this.systolicBP,
    this.diastolicBP,
    this.weight,
    this.fundalHeight,
    this.fetalHeartRate,
    this.presentation,
    this.descent,
    this.urineProtein,
    this.urineGlucose,
    this.pcv,
    this.notes,
    this.ultrasoundFindings,
    this.labResultsJson,
    this.encounterId,
  });

  final String id;
  final String pregnancyId;
  final String visitDate;
  final String staffId;
  final double? gestationWeeks;
  final int? gestationDays;
  final int? systolicBP;
  final int? diastolicBP;
  final double? weight;
  final double? fundalHeight;
  final int? fetalHeartRate;
  final FetalPresentation? presentation;
  final String? descent;
  final String? urineProtein;
  final String? urineGlucose;
  final double? pcv;
  final String? notes;
  final String? ultrasoundFindings;
  final Map<String, dynamic>? labResultsJson;
  final String? encounterId;

  factory AntenatalVisit.fromJson(Map<String, dynamic> json) {
    return AntenatalVisit(
      id: json['id'] as String,
      pregnancyId: json['pregnancyId'] as String? ?? '',
      visitDate: json['visitDate'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      gestationWeeks: (json['gestationWeeks'] as num?)?.toDouble(),
      gestationDays: (json['gestationDays'] as num?)?.toInt(),
      systolicBP: (json['systolicBP'] as num?)?.toInt(),
      diastolicBP: (json['diastolicBP'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      fundalHeight: (json['fundalHeight'] as num?)?.toDouble(),
      fetalHeartRate: (json['fetalHeartRate'] as num?)?.toInt(),
      presentation: FetalPresentation.fromString(json['presentation'] as String?),
      descent: json['descent'] as String?,
      urineProtein: json['urineProtein'] as String?,
      urineGlucose: json['urineGlucose'] as String?,
      pcv: (json['pcv'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      ultrasoundFindings: json['ultrasoundFindings'] as String?,
      labResultsJson: json['labResultsJson'] as Map<String, dynamic>?,
      encounterId: json['encounterId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'visitDate': visitDate,
        'staffId': staffId,
        if (gestationWeeks != null) 'gestationWeeks': gestationWeeks,
        if (gestationDays != null) 'gestationDays': gestationDays,
        if (systolicBP != null) 'systolicBP': systolicBP,
        if (diastolicBP != null) 'diastolicBP': diastolicBP,
        if (weight != null) 'weight': weight,
        if (fundalHeight != null) 'fundalHeight': fundalHeight,
        if (fetalHeartRate != null) 'fetalHeartRate': fetalHeartRate,
        if (presentation != null) 'presentation': presentation!.apiValue,
        if (descent != null) 'descent': descent,
        if (urineProtein != null) 'urineProtein': urineProtein,
        if (urineGlucose != null) 'urineGlucose': urineGlucose,
        if (pcv != null) 'pcv': pcv,
        if (notes != null) 'notes': notes,
        if (ultrasoundFindings != null) 'ultrasoundFindings': ultrasoundFindings,
        if (labResultsJson != null) 'labResultsJson': labResultsJson,
        if (encounterId != null) 'encounterId': encounterId,
      };
}

// ─── Labour & delivery ────────────────────────────────────────────────────

class LabourDelivery {
  const LabourDelivery({
    required this.id,
    required this.pregnancyId,
    required this.deliveryDateTime,
    required this.mode,
    required this.outcome,
    required this.deliveredById,
    this.admissionId,
    this.bloodLossMl,
    this.placentaComplete,
    this.episiotomy,
    this.perinealTearGrade,
    this.notes,
    this.partogram,
    this.babies,
  });

  final String id;
  final String pregnancyId;
  final String deliveryDateTime;
  final DeliveryMode mode;
  final DeliveryOutcome outcome;
  final String deliveredById;
  final String? admissionId;
  final int? bloodLossMl;
  final bool? placentaComplete;
  final bool? episiotomy;
  final String? perinealTearGrade;
  final String? notes;
  final List<PartogramEntry>? partogram;
  final List<Baby>? babies;

  factory LabourDelivery.fromJson(Map<String, dynamic> json) {
    return LabourDelivery(
      id: json['id'] as String,
      pregnancyId: json['pregnancyId'] as String? ?? '',
      deliveryDateTime: json['deliveryDateTime'] as String? ?? '',
      mode: DeliveryMode.fromString(json['mode'] as String?) ?? DeliveryMode.OTHER,
      outcome: DeliveryOutcome.fromString(json['outcome'] as String?) ??
          DeliveryOutcome.OTHER,
      deliveredById: json['deliveredById'] as String? ?? '',
      admissionId: json['admissionId'] as String?,
      bloodLossMl: (json['bloodLossMl'] as num?)?.toInt(),
      placentaComplete: json['placentaComplete'] as bool?,
      episiotomy: json['episiotomy'] as bool?,
      perinealTearGrade: json['perinealTearGrade'] as String?,
      notes: json['notes'] as String?,
      partogram: (json['partogram'] as List<dynamic>?)
          ?.map((e) => PartogramEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      babies: (json['babies'] as List<dynamic>?)
          ?.map((e) => Baby.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'deliveryDateTime': deliveryDateTime,
        'mode': mode.apiValue,
        'outcome': outcome.apiValue,
        'deliveredById': deliveredById,
        if (admissionId != null) 'admissionId': admissionId,
        if (bloodLossMl != null) 'bloodLossMl': bloodLossMl,
        if (placentaComplete != null) 'placentaComplete': placentaComplete,
        if (episiotomy != null) 'episiotomy': episiotomy,
        if (perinealTearGrade != null) 'perinealTearGrade': perinealTearGrade,
        if (notes != null) 'notes': notes,
      };
}

/// Response for GET /obstetrics/pregnancies/:pregnancyId/labour-deliveries.
class LabourDeliveriesListResponse {
  const LabourDeliveriesListResponse({
    required this.labourDeliveries,
    this.total = 0,
    this.skip = 0,
    this.take = 20,
  });

  final List<LabourDelivery> labourDeliveries;
  final int total;
  final int skip;
  final int take;

  factory LabourDeliveriesListResponse.fromJson(dynamic data) {
    if (data is List) {
      return LabourDeliveriesListResponse(
        labourDeliveries: data
            .map((e) => LabourDelivery.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: data.length,
      );
    }
    final json = data as Map<String, dynamic>;
    final list = json['labourDeliveries'] as List<dynamic>? ??
        json['deliveries'] as List<dynamic>? ??
        [];
    return LabourDeliveriesListResponse(
      labourDeliveries: list
          .map((e) => LabourDelivery.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? list.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}

// ─── Partogram entry ───────────────────────────────────────────────────────

class PartogramEntry {
  const PartogramEntry({
    required this.id,
    required this.labourDeliveryId,
    required this.recordedAt,
    required this.recordedById,
    this.cervicalDilationCm,
    this.station,
    this.contractionsPer10Min,
    this.fetalHeartRate,
    this.moulding,
    this.descent,
    this.oxytocin,
    this.comments,
  });

  final String id;
  final String labourDeliveryId;
  final String recordedAt;
  final String recordedById;
  final double? cervicalDilationCm;
  final double? station;
  final int? contractionsPer10Min;
  final int? fetalHeartRate;
  final String? moulding;
  final String? descent;
  final String? oxytocin;
  final String? comments;

  factory PartogramEntry.fromJson(Map<String, dynamic> json) {
    return PartogramEntry(
      id: json['id'] as String,
      labourDeliveryId: json['labourDeliveryId'] as String? ?? '',
      recordedAt: json['recordedAt'] as String? ?? '',
      recordedById: json['recordedById'] as String? ?? '',
      cervicalDilationCm: (json['cervicalDilationCm'] as num?)?.toDouble(),
      station: (json['station'] as num?)?.toDouble(),
      contractionsPer10Min: (json['contractionsPer10Min'] as num?)?.toInt(),
      fetalHeartRate: (json['fetalHeartRate'] as num?)?.toInt(),
      moulding: json['moulding'] as String?,
      descent: json['descent'] as String?,
      oxytocin: json['oxytocin'] as String?,
      comments: json['comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'recordedAt': recordedAt,
        'recordedById': recordedById,
        if (cervicalDilationCm != null) 'cervicalDilationCm': cervicalDilationCm,
        if (station != null) 'station': station,
        if (contractionsPer10Min != null)
          'contractionsPer10Min': contractionsPer10Min,
        if (fetalHeartRate != null) 'fetalHeartRate': fetalHeartRate,
        if (moulding != null) 'moulding': moulding,
        if (descent != null) 'descent': descent,
        if (oxytocin != null) 'oxytocin': oxytocin,
        if (comments != null) 'comments': comments,
      };
}

// ─── Baby ──────────────────────────────────────────────────────────────────

class Baby {
  const Baby({
    required this.id,
    required this.labourDeliveryId,
    required this.motherId,
    required this.sex,
    this.birthWeightG,
    this.birthLengthCm,
    this.apgar1,
    this.apgar5,
    this.resuscitation,
    this.birthOrder = 1,
    this.registeredPatientId,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String labourDeliveryId;
  final String motherId;
  final BabySex sex;
  final int? birthWeightG;
  final double? birthLengthCm;
  final int? apgar1;
  final int? apgar5;
  final String? resuscitation;
  final int birthOrder;
  final String? registeredPatientId;
  final String? createdByName;
  final String? updatedByName;

  factory Baby.fromJson(Map<String, dynamic> json) {
    return Baby(
      id: json['id'] as String,
      labourDeliveryId: json['labourDeliveryId'] as String? ?? '',
      motherId: json['motherId'] as String? ?? '',
      sex: BabySex.fromString(json['sex'] as String?) ?? BabySex.U,
      birthWeightG: (json['birthWeightG'] as num?)?.toInt(),
      birthLengthCm: (json['birthLengthCm'] as num?)?.toDouble(),
      apgar1: (json['apgar1'] as num?)?.toInt(),
      apgar5: (json['apgar5'] as num?)?.toInt(),
      resuscitation: json['resuscitation'] as String?,
      birthOrder: (json['birthOrder'] as num?)?.toInt() ?? 1,
      registeredPatientId: json['registeredPatientId'] as String?,
      createdByName: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
      updatedByName: formatStaffName(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'motherId': motherId,
        'sex': sex.apiValue,
        if (birthWeightG != null) 'birthWeightG': birthWeightG,
        if (birthLengthCm != null) 'birthLengthCm': birthLengthCm,
        if (apgar1 != null) 'apgar1': apgar1,
        if (apgar5 != null) 'apgar5': apgar5,
        if (resuscitation != null) 'resuscitation': resuscitation,
        'birthOrder': birthOrder,
      };

  Map<String, dynamic> toPatchJson() => {
        if (birthWeightG != null) 'birthWeightG': birthWeightG,
        if (birthLengthCm != null) 'birthLengthCm': birthLengthCm,
        if (apgar1 != null) 'apgar1': apgar1,
        if (apgar5 != null) 'apgar5': apgar5,
        if (resuscitation != null) 'resuscitation': resuscitation,
      };
}

// ─── Postnatal visit ────────────────────────────────────────────────────────

class PostnatalVisit {
  const PostnatalVisit({
    required this.id,
    required this.labourDeliveryId,
    required this.type,
    required this.visitDate,
    required this.staffId,
    this.patientId,
    this.babyId,
    this.uterusInvolution,
    this.lochia,
    this.perineum,
    this.bloodPressure,
    this.temperature,
    this.breastfeeding,
    this.weight,
    this.feeding,
    this.jaundice,
    this.immunisationGiven,
    this.notes,
  });

  final String id;
  final String labourDeliveryId;
  final PostnatalVisitType type;
  final String visitDate;
  final String staffId;
  final String? patientId;
  final String? babyId;
  final String? uterusInvolution;
  final String? lochia;
  final String? perineum;
  final String? bloodPressure;
  final double? temperature;
  final String? breastfeeding;
  final double? weight;
  final String? feeding;
  final String? jaundice;
  final String? immunisationGiven;
  final String? notes;

  factory PostnatalVisit.fromJson(Map<String, dynamic> json) {
    return PostnatalVisit(
      id: json['id'] as String,
      labourDeliveryId: json['labourDeliveryId'] as String? ?? '',
      type: PostnatalVisitType.fromString(json['type'] as String?) ??
          PostnatalVisitType.MOTHER,
      visitDate: json['visitDate'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      patientId: json['patientId'] as String?,
      babyId: json['babyId'] as String?,
      uterusInvolution: json['uterusInvolution'] as String?,
      lochia: json['lochia'] as String?,
      perineum: json['perineum'] as String?,
      bloodPressure: json['bloodPressure'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      breastfeeding: json['breastfeeding'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      feeding: json['feeding'] as String?,
      jaundice: json['jaundice'] as String?,
      immunisationGiven: json['immunisationGiven'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'labourDeliveryId': labourDeliveryId,
        'type': type.apiValue,
        'visitDate': visitDate,
        'staffId': staffId,
        if (patientId != null) 'patientId': patientId,
        if (babyId != null) 'babyId': babyId,
        if (uterusInvolution != null) 'uterusInvolution': uterusInvolution,
        if (lochia != null) 'lochia': lochia,
        if (perineum != null) 'perineum': perineum,
        if (bloodPressure != null) 'bloodPressure': bloodPressure,
        if (temperature != null) 'temperature': temperature,
        if (breastfeeding != null) 'breastfeeding': breastfeeding,
        if (weight != null) 'weight': weight,
        if (feeding != null) 'feeding': feeding,
        if (jaundice != null) 'jaundice': jaundice,
        if (immunisationGiven != null) 'immunisationGiven': immunisationGiven,
        if (notes != null) 'notes': notes,
      };
}

// ─── Gynae procedure ───────────────────────────────────────────────────────

class GynaeProcedure {
  const GynaeProcedure({
    required this.id,
    required this.patientId,
    required this.procedureType,
    required this.procedureDate,
    required this.surgeonId,
    this.encounterId,
    this.admissionId,
    this.assistantId,
    this.findings,
    this.complications,
    this.notes,
  });

  final String id;
  final String patientId;
  final String procedureType;
  final String procedureDate;
  final String surgeonId;
  final String? encounterId;
  final String? admissionId;
  final String? assistantId;
  final String? findings;
  final String? complications;
  final String? notes;

  factory GynaeProcedure.fromJson(Map<String, dynamic> json) {
    return GynaeProcedure(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      procedureType: json['procedureType'] as String? ?? '',
      procedureDate: json['procedureDate'] as String? ?? '',
      surgeonId: json['surgeonId'] as String? ?? '',
      encounterId: json['encounterId'] as String?,
      admissionId: json['admissionId'] as String?,
      assistantId: json['assistantId'] as String?,
      findings: json['findings'] as String?,
      complications: json['complications'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'procedureType': procedureType,
        'procedureDate': procedureDate,
        'surgeonId': surgeonId,
        if (encounterId != null) 'encounterId': encounterId,
        if (admissionId != null) 'admissionId': admissionId,
        if (assistantId != null) 'assistantId': assistantId,
        if (findings != null) 'findings': findings,
        if (complications != null) 'complications': complications,
        if (notes != null) 'notes': notes,
      };
}

// ─── Paginated list responses ──────────────────────────────────────────────

class PregnanciesListResponse {
  const PregnanciesListResponse({
    required this.pregnancies,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<Pregnancy> pregnancies;
  final int total;
  final int skip;
  final int take;

  factory PregnanciesListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['pregnancies'] as List<dynamic>? ?? [];
    return PregnanciesListResponse(
      pregnancies:
          list.map((e) => Pregnancy.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}

class AntenatalVisitsListResponse {
  const AntenatalVisitsListResponse({
    required this.visits,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<AntenatalVisit> visits;
  final int total;
  final int skip;
  final int take;

  factory AntenatalVisitsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['visits'] as List<dynamic>? ?? [];
    return AntenatalVisitsListResponse(
      visits: list
          .map((e) => AntenatalVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 50,
    );
  }
}

class BabiesListResponse {
  const BabiesListResponse({
    required this.babies,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<Baby> babies;
  final int total;
  final int skip;
  final int take;

  factory BabiesListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['babies'] as List<dynamic>? ?? [];
    return BabiesListResponse(
      babies: list.map((e) => Baby.fromJson(e as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}

class PostnatalVisitsListResponse {
  const PostnatalVisitsListResponse({
    required this.visits,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<PostnatalVisit> visits;
  final int total;
  final int skip;
  final int take;

  factory PostnatalVisitsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['visits'] as List<dynamic>? ?? [];
    return PostnatalVisitsListResponse(
      visits: list
          .map((e) => PostnatalVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 50,
    );
  }
}

class GynaeProceduresListResponse {
  const GynaeProceduresListResponse({
    required this.procedures,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<GynaeProcedure> procedures;
  final int total;
  final int skip;
  final int take;

  factory GynaeProceduresListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['procedures'] as List<dynamic>? ?? [];
    return GynaeProceduresListResponse(
      procedures: list
          .map((e) => GynaeProcedure.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? 20,
    );
  }
}
