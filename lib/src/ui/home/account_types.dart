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
    route: NewPatientRoute(),
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
  MenuItem(
    label: 'Services',
    icon: Icons.view_array_outlined,
    route: ViewServiceRoute(),
    children: [
      MenuItem(
        label: 'View OPD Services',
        icon: Icons.view_array_outlined,
        route: ViewServiceRoute(),
      ),
      MenuItem(
        label: 'Add New Service',
        icon: Icons.view_array_outlined,
        route: AddServiceRoute(),
      ),
      MenuItem(
        label: 'Add New Category',
        icon: Icons.view_array_outlined,
        route: AddCategoryRoute(),
      ),
      MenuItem(
        label: 'Add New Department',
        icon: Icons.view_array_outlined,
        route: AddDepartmentRoute(),
      ),
    ],
  ),
  MenuItem(
    label: 'Enlist For Dialysis Service',
    icon: Icons.verified_user_rounded,
    route: EnlistPaitientRoute(serviceName: 'Dialysis'),
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
    label: 'Render OPD',
    icon: Icons.dataset_outlined,
    route: EnlistPaitientRoute(serviceName: 'OPD'),
  ),
  MenuItem(
    label: 'Render Investigation',
    icon: Icons.science_outlined,
    route: EnlistPaitientRoute(serviceName: 'Investigation'),
  ),
  MenuItem(
    label: 'Render Dialysis',
    icon: Icons.local_hospital_outlined,
    route: EnlistPaitientRoute(serviceName: 'Dialysis'),
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
  MenuItem(
    label: 'Debt/Insurance Payment',
    icon: Icons.personal_injury_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Transaction',
    icon: Icons.list_outlined,
    route: TransactionsRoute(),
  ),

  MenuItem(
    label: 'View Investigation Service',
    icon: Icons.verified_user_rounded,
    route: NotAvailableRoute(),
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
];

final phamDispense = <MenuItem>[
  MenuItem(
    label: 'Medicine Sales',
    icon: Icons.add_alarm_outlined,
    route: EnlistPaitientRoute(serviceName: 'Pharmacy'),
  ),
  MenuItem(
    label: 'Medicine Inventory',
    icon: Icons.inventory_2_outlined,
    route: MedicineInventoryRoute(),
  ),

  MenuItem(
    label: 'Pharmacy Waiting Patient',
    icon: Icons.add_alarm_outlined,
    route: WaitingPatientRoute(),
  ),

  MenuItem(
    label: 'Stock Transfer',
    icon: Icons.move_to_inbox_outlined,
    route: StockTransferRoute(),
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
    label: 'New order',
    icon: Icons.add_circle_outline_rounded,
    route: LabCreateOrderRoute(),
  ),
];
