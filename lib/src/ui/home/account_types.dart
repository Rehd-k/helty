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
      MenuItem(
        label: 'View Waiting Patients',
        icon: Icons.add_alarm_outlined,
        route: WaitingPatientRoute(),
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
    label: 'View OPD Services',
    icon: Icons.view_array_outlined,
    route: ViewServiceRoute(),
  ),
  MenuItem(
    label: 'Enlist For OPD Service',
    icon: Icons.add_card_outlined,
    route: EnlistPaitientRoute(),
  ),
  MenuItem(
    label: 'Enlist For Investigation Service',
    icon: Icons.biotech_outlined,
    route: EnlistPaitientRoute(),
  ),
  MenuItem(
    label: 'Enlist For Dialysis Service',
    icon: Icons.verified_user_rounded,
    route: EnlistPaitientRoute(),
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
    route: EnlistPaitientRoute(),
  ),
  MenuItem(
    label: 'Render Investigation',
    icon: Icons.science_outlined,
    route: EnlistPaitientRoute(),
  ),
  MenuItem(
    label: 'Render Dialysis',
    icon: Icons.local_hospital_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Render Morturay Servies',
    icon: Icons.time_to_leave_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Process Ward Payment',
    icon: Icons.access_time_filled_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Debt/Insurance Payment',
    icon: Icons.personal_injury_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Transaction',
    icon: Icons.list_outlined,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'View Ward Services',
    icon: Icons.dry_cleaning_sharp,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'View Investigation Service',
    icon: Icons.verified_user_rounded,
    route: NotAvailableRoute(),
  ),
  MenuItem(
    label: 'Transaction',
    icon: Icons.verified_user_rounded,
    route: NotAvailableRoute(),
  ),
];
