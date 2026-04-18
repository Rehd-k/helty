import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import 'home_screen.dart';

final frontDesk = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: FrontDeskDashboardRoute(),
  ),
  MenuItem(
    label: 'View Waiting Patients',
    icon: Icons.add_alarm_outlined,
    route: NewPatientRoute(use: 'For Register'),
  ),
  MenuItem(
    label: 'Patients',
    icon: Icons.view_agenda_outlined,
    route: PatientListRoute(),
    children: [
      MenuItem(
        label: 'Add New Patient',
        icon: Icons.view_agenda_outlined,
        route: PatientFormRoute(),
      ),
      MenuItem(
        label: 'View Patients',
        icon: Icons.add_alarm_outlined,
        route: PatientListRoute(),
      ),
    ],
  ),
  MenuItem(
    label: 'Appointments',
    icon: Icons.calendar_month,
    route: AppointmentListRoute(),
    children: [
      MenuItem(
        label: 'Add New Appointment',
        icon: Icons.view_agenda_outlined,
        route: NewAppointmentRoute(),
      ),
      MenuItem(
        label: 'View Appointments',
        icon: Icons.add_alarm_outlined,
        route: AppointmentListRoute(),
      ),
    ],
  ),
];

/// Same entries as [frontDesk] plus completed encounters (medical records only).
final medicalRecordsMenu = <MenuItem>[
  ...frontDesk,
  MenuItem(
    label: 'Completed Encounters',
    icon: Icons.check_circle_outline,
    route: DoctorCompletedEncountersRoute(),
  ),
];

final bills = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_customize_outlined,
    route: BillingDashboardRoute(),
  ),
  MenuItem(
    label: 'Pending Transaction',
    icon: Icons.pending_actions_outlined,
    route: PendingBillsRoute(),
  ),
  MenuItem(
    label: 'Render Service',
    icon: Icons.dataset_outlined,
    route: EnlistPaitientRoute(serviceName: 'OPD'),
  ),
  MenuItem(
    label: 'Process Ward Payment',
    icon: Icons.access_time_filled_outlined,
    route: EnlistPaitientRoute(serviceName: 'inpatient'),
  ),
  MenuItem(
    label: 'Add Service',
    icon: Icons.add_box_outlined,
    route: SystemSetupRoute(),
  ),
  // MenuItem(
  //   label: 'Debt/Insurance Payment',
  //   icon: Icons.personal_injury_outlined,
  //   route: NotAvailableRoute(),
  // ),
  MenuItem(
    label: 'Transaction',
    icon: Icons.list_outlined,
    route: TransactionsRoute(),
  ),
];

final nurses = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: NursesDashboardRoute(),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientsRoute(),
  ),
  MenuItem(
    label: 'Inpatients (Ward Census)',
    icon: Icons.bed,
    route: InpatientsListRoute(),
  ),
  MenuItem(
    label: 'O&G Dashboard',
    icon: Icons.pregnant_woman_rounded,
    route: ObstetricsDashboardRoute(),
  ),
  MenuItem(
    label: 'Pregnancies (by patient)',
    icon: Icons.family_restroom_rounded,
    route: ObstetricsPatientSelectRoute(),
  ),
  MenuItem(
    label: 'Gynaecology procedures',
    icon: Icons.medical_services_rounded,
    route: ObstetricsGynaeProceduresRoute(),
  ),
  MenuItem(
    label: 'Radiology',
    icon: Icons.radar_rounded,
    route: RadiologyDashboardRoute(),
  ),
  MenuItem(
    label: 'Appointments',
    icon: Icons.calendar_month,
    route: AppointmentListRoute(),
    children: [
      MenuItem(
        label: 'Add New Appointment',
        icon: Icons.view_agenda_outlined,
        route: NewAppointmentRoute(),
      ),
      MenuItem(
        label: 'View Appointments',
        icon: Icons.add_alarm_outlined,
        route: AppointmentListRoute(),
      ),
    ],
  ),
];

final doctors = <MenuItem>[
  MenuItem(
    label: 'My Appointments',
    icon: Icons.calendar_today_outlined,
    route: DoctorOutpatientListRoute(),
  ),
  MenuItem(
    label: 'Walk-in Queue',
    icon: Icons.people_outline,
    route: DoctorWalkInQueueRoute(),
  ),
  MenuItem(
    label: 'Ward Rounds',
    icon: Icons.medical_services_outlined,
    route: WardRoundsRoute(),
  ),
  MenuItem(label: 'Inpatients', icon: Icons.bed, route: InpatientsListRoute()),
  MenuItem(
    label: 'O&G Dashboard',
    icon: Icons.pregnant_woman_rounded,
    route: ObstetricsDashboardRoute(),
  ),
  MenuItem(
    label: 'Pregnancies (by patient)',
    icon: Icons.family_restroom_rounded,
    route: ObstetricsPatientSelectRoute(),
  ),
  MenuItem(
    label: 'Gynaecology procedures',
    icon: Icons.medical_services_rounded,
    route: ObstetricsGynaeProceduresRoute(),
  ),

  MenuItem(
    label: 'Completed Encounters',
    icon: Icons.check_circle_outline,
    route: DoctorCompletedEncountersRoute(),
  ),
  MenuItem(
    label: 'Templates',
    icon: Icons.description_outlined,
    route: DoctorTemplatesRoute(),
  ),
  MenuItem(
    label: 'Profile',
    icon: Icons.person_outline,
    route: DoctorProfileRoute(),
  ),
];

final pharmacy = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: PharmacyDashboardRoute(),
  ),
  MenuItem(
    label: 'Medicine Inventory',
    icon: Icons.inventory_2_outlined,
    route: MedicineInventoryRoute(),
  ),

  MenuItem(
    label: 'Add Supplier',
    icon: Icons.person_add_alt_1_outlined,
    route: AddSupplierRoute(),
  ),
  MenuItem(
    label: 'Add Supply',
    icon: Icons.add_box_outlined,
    route: AddBatchRoute(),
  ),
  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: StockTransferRoute(),
  ),
  MenuItem(
    label: 'Create Requisition',
    icon: Icons.receipt_long_outlined,
    route: CreateRequisitionRoute(),
  ),
  MenuItem(
    label: 'Supply History',
    icon: Icons.list_alt_outlined,
    route: SupplyHistoryRoute(),
  ),
  MenuItem(
    label: 'Pharmacy Locations',
    icon: Icons.location_on_outlined,
    route: PharmacyLocationRoute(),
  ),
  MenuItem(
    label: 'Medicine Sales',
    icon: Icons.add_alarm_outlined,
    route: EnlistPaitientRoute(serviceName: 'Pharmacy'),
  ),

  MenuItem(
    label: 'Pharmacy Waiting Patient',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientRoute(),
  ),
];

final phamDispense = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: PharmacyDashboardRoute(),
  ),
  MenuItem(
    label: 'Medicine Inventory',
    icon: Icons.inventory_2_outlined,
    route: MedicineInventoryRoute(),
  ),

  MenuItem(
    label: 'Add Supplier',
    icon: Icons.person_add_alt_1_outlined,
    route: AddSupplierRoute(),
  ),
  MenuItem(
    label: 'Add Supply',
    icon: Icons.add_box_outlined,
    route: AddBatchRoute(),
  ),
  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: StockTransferRoute(),
  ),
  MenuItem(
    label: 'Create Requisition',
    icon: Icons.receipt_long_outlined,
    route: CreateRequisitionRoute(),
  ),
  MenuItem(
    label: 'Supply History',
    icon: Icons.list_alt_outlined,
    route: SupplyHistoryRoute(),
  ),
  MenuItem(
    label: 'Pharmacy Locations',
    icon: Icons.location_on_outlined,
    route: PharmacyLocationRoute(),
  ),
  MenuItem(
    label: 'Medicine Sales',
    icon: Icons.add_alarm_outlined,
    route: EnlistPaitientRoute(serviceName: 'Pharmacy'),
  ),

  MenuItem(
    label: 'Pharmacy Waiting Patient',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientRoute(),
  ),
];

final obstetrics = <MenuItem>[];

final labMenu = <MenuItem>[
  MenuItem(
    label: 'Laboratory',
    icon: Icons.biotech_rounded,
    route: LabDashboardRoute(),
  ),

  MenuItem(
    label: 'New patient',
    icon: Icons.add_circle_outline_rounded,
    route: EnlistPaitientRoute(serviceName: 'lab'),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.receipt_long_outlined,
    route: NewPatientRoute(
      use: 'Laboratory',
      categoryQueries: const ['Laboratory', 'Laboratory Tests'],
    ),
  ),
];

final radiologyMenu = <MenuItem>[
  MenuItem(
    label: 'Radiology',
    icon: Icons.radar_rounded,
    route: RadiologyDashboardRoute(),
  ),
  MenuItem(
    label: 'Worklist',
    icon: Icons.list_alt_rounded,
    route: RadiologyWorklistRoute(),
  ),
  MenuItem(
    label: 'New patient',
    icon: Icons.add_circle_outline_rounded,
    route: EnlistPaitientRoute(serviceName: 'Radiology'),
  ),
  MenuItem(
    label: 'Waiting Patients',
    icon: Icons.receipt_long_outlined,
    route: NewPatientRoute(
      use: 'Radiology',
      categoryQueries: const ['Radiology & Imaging'],
    ),
  ),
];

final storeMenu = <MenuItem>[
  MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: StoreDashboardRoute(),
  ),
  MenuItem(
    label: 'Categories',
    icon: Icons.category_outlined,
    route: StoreCategoriesRoute(),
  ),
  MenuItem(
    label: 'Items',
    icon: Icons.inventory_2_outlined,
    route: StoreItemsRoute(),
  ),
  MenuItem(
    label: 'Locations',
    icon: Icons.location_on_outlined,
    route: StoreLocationsRoute(),
  ),
  MenuItem(
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    route: StoreStockRoute(),
  ),
  MenuItem(
    label: 'Movements',
    icon: Icons.move_to_inbox_outlined,
    route: StoreMovementsRoute(),
  ),
  MenuItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    route: StoreAnalyticsRoute(),
  ),
];
