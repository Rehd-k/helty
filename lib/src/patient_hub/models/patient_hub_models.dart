import 'package:flutter/material.dart' show IconData, Icons;

/// Tab definition for Patient Hub nested routes.
class PatientHubTabDef {
  const PatientHubTabDef({
    required this.label,
    required this.routeName,
    this.icon,
  });

  final String label;
  final String routeName;
  final IconData? icon;
}

/// All Patient Hub tabs in display order.
const patientHubTabDefs = <PatientHubTabDef>[
  PatientHubTabDef(
    label: 'Overview',
    routeName: 'HubOverviewRoute',
    icon: Icons.dashboard_outlined,
  ),
  PatientHubTabDef(
    label: 'Profile',
    routeName: 'HubProfileRoute',
    icon: Icons.person_outline,
  ),
  PatientHubTabDef(
    label: 'Encounters',
    routeName: 'HubEncountersRoute',
    icon: Icons.event_note_outlined,
  ),
  PatientHubTabDef(
    label: 'Vitals',
    routeName: 'HubVitalsRoute',
    icon: Icons.monitor_heart_outlined,
  ),
  PatientHubTabDef(
    label: 'Labs',
    routeName: 'HubLabsRoute',
    icon: Icons.biotech_outlined,
  ),
  PatientHubTabDef(
    label: 'Imaging',
    routeName: 'HubImagingRoute',
    icon: Icons.radar_outlined,
  ),
  PatientHubTabDef(
    label: 'Meds',
    routeName: 'HubMedsRoute',
    icon: Icons.medication_outlined,
  ),
  PatientHubTabDef(
    label: 'Dialysis',
    routeName: 'HubDialysisRoute',
    icon: Icons.bloodtype_outlined,
  ),
  PatientHubTabDef(
    label: 'Theatre',
    routeName: 'HubTheatreRoute',
    icon: Icons.medical_services_outlined,
  ),
  PatientHubTabDef(
    label: 'Documents',
    routeName: 'HubDocumentsRoute',
    icon: Icons.folder_copy_outlined,
  ),
  PatientHubTabDef(
    label: 'Notes',
    routeName: 'HubNotesRoute',
    icon: Icons.description_outlined,
  ),
];

/// Global date-range filter for historical hub tabs.
class PatientHubDateRange {
  const PatientHubDateRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  PatientHubDateRange copyWith({DateTime? from, DateTime? to}) {
    return PatientHubDateRange(from: from ?? this.from, to: to ?? this.to);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientHubDateRange && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);
}

enum HubDatePreset { last7Days, last30Days, last90Days, all, custom }

enum HubSortOrder { newestFirst, oldestFirst }

enum HubEncounterFilter { all, outpatient, inpatient, emergency }

enum HubMedsFilter { all, active }

enum HubLabStatusFilter { all, pending, completed }

/// Max rows per hub list/chart request (backend caps often at 100).
const patientHubMaxTake = 99;
