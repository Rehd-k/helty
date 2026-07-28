import 'package:flutter/material.dart' show IconData, Icons;

import '../../core/utils/patient_display_name.dart';
import '../../core/utils/patient_initials.dart';
import '../../models/staff_attribution.dart';
import 'archived_encounter_models.dart';

/// Known chart section keys from GET /patients/:id/chart.
class PatientChartSectionKeys {
  static const encounters = 'encounters';
  static const admissions = 'admissions';
  static const medicationOrders = 'medicationOrders';
  static const prescriptions = 'prescriptions';
  static const labOrders = 'labOrders';
  static const labRequests = 'labRequests';
  static const labReports = 'labReports';
  static const radiologyOrders = 'radiologyOrders';
  static const radiologyReports = 'radiologyReports';
  static const vitals = 'vitals';
  static const allergies = 'allergies';
  static const appointments = 'appointments';
  static const invoices = 'invoices';
  static const payments = 'payments';
  static const wallet = 'wallet';
  static const medicalHistories = 'medicalHistories';
  static const doctorReports = 'doctorReports';
  static const archivedEncounters = 'archivedEncounters';

  static const all = [
    encounters,
    admissions,
    medicationOrders,
    prescriptions,
    labOrders,
    labRequests,
    labReports,
    radiologyOrders,
    radiologyReports,
    vitals,
    allergies,
    appointments,
    invoices,
    payments,
    wallet,
    medicalHistories,
    doctorReports,
    archivedEncounters,
  ];

  static const clinicalNurse = [
    encounters,
    admissions,
    medicationOrders,
    prescriptions,
    labOrders,
    labRequests,
    labReports,
    radiologyOrders,
    radiologyReports,
    vitals,
    allergies,
    archivedEncounters,
  ];
}

/// Tab bundle for lazy-loading chart sections.
class PatientChartTabDef {
  const PatientChartTabDef({
    required this.label,
    required this.includeKeys,
    this.icon,
  });

  final String label;
  final List<String> includeKeys;
  final IconData? icon;
}

/// Predefined tab groups (filtered by role at runtime).
final patientChartTabDefs = <PatientChartTabDef>[
  const PatientChartTabDef(
    label: 'Encounters',
    includeKeys: [
      PatientChartSectionKeys.encounters,
      PatientChartSectionKeys.admissions,
    ],
    icon: Icons.event_note_outlined,
  ),
  const PatientChartTabDef(
    label: 'Meds',
    includeKeys: [
      PatientChartSectionKeys.medicationOrders,
      PatientChartSectionKeys.prescriptions,
    ],
    icon: Icons.medication_outlined,
  ),
  const PatientChartTabDef(
    label: 'Labs',
    includeKeys: [
      PatientChartSectionKeys.labOrders,
      PatientChartSectionKeys.labRequests,
      PatientChartSectionKeys.labReports,
    ],
    icon: Icons.biotech_outlined,
  ),
  const PatientChartTabDef(
    label: 'Imaging',
    includeKeys: [
      PatientChartSectionKeys.radiologyOrders,
      PatientChartSectionKeys.radiologyReports,
    ],
    icon: Icons.radar_outlined,
  ),
  const PatientChartTabDef(
    label: 'Vitals',
    includeKeys: [
      PatientChartSectionKeys.vitals,
      PatientChartSectionKeys.allergies,
    ],
    icon: Icons.monitor_heart_outlined,
  ),
  const PatientChartTabDef(
    label: 'Notes',
    includeKeys: [
      PatientChartSectionKeys.medicalHistories,
      PatientChartSectionKeys.doctorReports,
    ],
    icon: Icons.description_outlined,
  ),
  const PatientChartTabDef(
    label: 'Billing',
    includeKeys: [
      PatientChartSectionKeys.invoices,
      PatientChartSectionKeys.payments,
      PatientChartSectionKeys.wallet,
      PatientChartSectionKeys.appointments,
    ],
    icon: Icons.receipt_long_outlined,
  ),
  const PatientChartTabDef(
    label: 'Archived',
    includeKeys: [PatientChartSectionKeys.archivedEncounters],
    icon: Icons.folder_copy_outlined,
  ),
];

class ChartPatientSummary {
  const ChartPatientSummary({
    this.id,
    this.patientId,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
    this.dob,
    this.gender,
    this.phoneNumber,
    this.status,
    this.wardName,
    this.hmoName,
    this.apiDisplayName,
    this.avatarUrl,
    this.updatedAt,
    this.createdBy,
  });

  final String? id;
  final String? patientId;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;
  final DateTime? dob;
  final String? gender;
  final String? phoneNumber;
  final String? status;
  final String? wardName;
  final String? hmoName;
  final String? apiDisplayName;
  final String? avatarUrl;
  final DateTime? updatedAt;
  final String? createdBy;

  String get displayName =>
      preferPatientFormattedName(displayName: apiDisplayName) ??
      patientDisplayNameFromJson(
        {
          'title': title,
          'firstName': firstName,
          'otherName': otherName,
          'surname': surname,
        },
        unknownFallback: 'Patient',
      );

  factory ChartPatientSummary.fromJson(Map<String, dynamic> json) {
    final ward = json['ward'];
    final hmo = json['hmoProvider'];
    return ChartPatientSummary(
      id: json['id'] as String?,
      patientId: json['patientId'] as String?,
      title: json['title'] as String?,
      firstName: json['firstName'] as String?,
      otherName: json['otherName'] as String?,
      surname: (json['surname'] ?? json['lastName']) as String?,
      dob: DateTime.tryParse(json['dob']?.toString() ?? ''),
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      status: json['status'] as String?,
      wardName: ward is Map ? ward['name']?.toString() : null,
      hmoName: hmo is Map ? hmo['name']?.toString() : null,
      apiDisplayName: preferPatientFormattedName(
        patientName: json['patientName']?.toString(),
        name: json['name']?.toString(),
        displayName: json['displayName']?.toString(),
      ),
      avatarUrl: avatarUrlFromJson(json),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      createdBy: formatStaffName(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
    );
  }
}

class ChartSummaryCounts {
  const ChartSummaryCounts({
    this.encounterCount = 0,
    this.admissionCount = 0,
    this.openInvoiceCount = 0,
    this.walletBalance,
    this.archivedEncounterGroupCount = 0,
  });

  final int encounterCount;
  final int admissionCount;
  final int openInvoiceCount;
  final double? walletBalance;
  final int archivedEncounterGroupCount;

  factory ChartSummaryCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChartSummaryCounts();
    return ChartSummaryCounts(
      encounterCount: json['encounterCount'] as int? ?? 0,
      admissionCount: json['admissionCount'] as int? ?? 0,
      openInvoiceCount: json['openInvoiceCount'] as int? ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
      archivedEncounterGroupCount:
          json['archivedEncounterGroupCount'] as int? ?? 0,
    );
  }
}

/// Response from GET /patients/:id/chart (header or with included sections).
class PatientChartResponse {
  const PatientChartResponse({
    required this.patient,
    required this.summary,
    required this.availableSections,
    this.sections = const {},
    this.archivedEncounters = const [],
  });

  final ChartPatientSummary patient;
  final ChartSummaryCounts summary;
  final List<String> availableSections;
  final Map<String, List<Map<String, dynamic>>> sections;
  final List<PatientArchivedEncounter> archivedEncounters;

  factory PatientChartResponse.fromJson(Map<String, dynamic> json) {
    final available = json['availableSections'];
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final key in PatientChartSectionKeys.all) {
      final raw = json[key];
      if (raw is List) {
        sections[key] = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (key == PatientChartSectionKeys.wallet && raw is Map) {
        sections[key] = [Map<String, dynamic>.from(raw)];
      }
    }

    final archivedRaw = json[PatientChartSectionKeys.archivedEncounters];
    final archived = archivedRaw is List
        ? archivedRaw
            .whereType<Map>()
            .map((e) => PatientArchivedEncounter.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <PatientArchivedEncounter>[];

    return PatientChartResponse(
      patient: ChartPatientSummary.fromJson(
        Map<String, dynamic>.from(json['patient'] as Map? ?? {}),
      ),
      summary: ChartSummaryCounts.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : null,
      ),
      availableSections: available is List
          ? available.map((e) => e.toString()).toList()
          : const [],
      sections: sections,
      archivedEncounters: archived,
    );
  }

  List<Map<String, dynamic>> section(String key) => sections[key] ?? const [];
}
