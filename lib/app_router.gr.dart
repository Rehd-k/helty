// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i141;
import 'package:collection/collection.dart' as _i145;
import 'package:flutter/material.dart' as _i142;
import 'package:helty/src/billings/dashboard.dart' as _i9;
import 'package:helty/src/billings/inpatient.bills.dart' as _i108;
import 'package:helty/src/billings/inpatient_bills_list_screen.dart' as _i59;
import 'package:helty/src/billings/pending.bills.dart' as _i111;
import 'package:helty/src/cmd/alerts_incidents_screen.dart' as _i10;
import 'package:helty/src/cmd/audit_compliance_screen.dart' as _i11;
import 'package:helty/src/cmd/beds_facilities_screen.dart' as _i12;
import 'package:helty/src/cmd/communication_center_screen.dart' as _i13;
import 'package:helty/src/cmd/consulting_rooms_screen.dart' as _i28;
import 'package:helty/src/cmd/dashboard.dart' as _i14;
import 'package:helty/src/cmd/financial_command_screen.dart' as _i15;
import 'package:helty/src/cmd/hospital_overview_screen.dart' as _i16;
import 'package:helty/src/cmd/lab_monitoring_screen.dart' as _i17;
import 'package:helty/src/cmd/patient_experience_screen.dart' as _i18;
import 'package:helty/src/cmd/reports_analytics_screen.dart' as _i19;
import 'package:helty/src/cmd/staff_oversight_screen.dart' as _i20;
import 'package:helty/src/cmd/system_control_screen.dart' as _i21;
import 'package:helty/src/doctor/completed/doctor_completed_encounter_view_screen.dart'
    as _i32;
import 'package:helty/src/doctor/completed/doctor_completed_encounters_screen.dart'
    as _i33;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_diagnosis_tab.dart'
    as _i22;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_examination_tab.dart'
    as _i23;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_follow_up_tab.dart'
    as _i24;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_history_tab.dart'
    as _i25;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_notes_tab.dart'
    as _i26;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_summary_tab.dart'
    as _i27;
import 'package:helty/src/doctor/dashboard/doctor_dashboard_screen.dart'
    as _i34;
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart'
    as _i45;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_admission_tab.dart'
    as _i35;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_diagnosis_tab.dart'
    as _i36;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_examination_tab.dart'
    as _i37;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_follow_up_tab.dart'
    as _i38;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_history_tab.dart'
    as _i39;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_imaging_tab.dart'
    as _i40;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_investigations_tab.dart'
    as _i41;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_notes_tab.dart'
    as _i42;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_prescription_tab.dart'
    as _i43;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_procedures_tab.dart'
    as _i44;
import 'package:helty/src/doctor/outpatient/doctor_outpatient_list_screen.dart'
    as _i46;
import 'package:helty/src/doctor/pending/doctor_pending_imaging_screen.dart'
    as _i47;
import 'package:helty/src/doctor/pending/doctor_pending_labs_screen.dart'
    as _i48;
import 'package:helty/src/doctor/pending/doctor_pending_prescriptions_screen.dart'
    as _i49;
import 'package:helty/src/doctor/profile/doctor_profile_screen.dart' as _i50;
import 'package:helty/src/doctor/templates/doctor_templates_screen.dart'
    as _i51;
import 'package:helty/src/doctor/walk_in/doctor_walk_in_queue_screen.dart'
    as _i52;
import 'package:helty/src/doctor/ward_rounds/ward_rounds_screen.dart' as _i140;
import 'package:helty/src/enlist_services/enlist.paitient.dart' as _i53;
import 'package:helty/src/frontdesk/dashboard.dart' as _i56;
import 'package:helty/src/hospital_service/service_screen.dart' as _i133;
import 'package:helty/src/hospital_service/wards/ward.screen.dart' as _i139;
import 'package:helty/src/lab/ui/lab_config_screen.dart' as _i75;
import 'package:helty/src/lab/ui/lab_create_order_screen.dart' as _i76;
import 'package:helty/src/lab/ui/lab_dashboard_screen.dart' as _i77;
import 'package:helty/src/lab/ui/lab_order_detail_screen.dart' as _i78;
import 'package:helty/src/lab/ui/lab_result_entry_screen.dart' as _i79;
import 'package:helty/src/models/patient_vitals_model.dart' as _i146;
import 'package:helty/src/nurses/dashboard.dart' as _i85;
import 'package:helty/src/nurses/inpatients/inpatient_patient_view_screen.dart'
    as _i70;
import 'package:helty/src/nurses/inpatients/inpatients_list_screen.dart'
    as _i74;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_alerts_tab.dart'
    as _i58;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_care_plan_tab.dart'
    as _i60;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_handover_tab.dart'
    as _i61;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_imaging_results_tab.dart'
    as _i64;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_io_tab.dart' as _i62;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_iv_tab.dart' as _i63;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_lab_results_tab.dart'
    as _i65;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_medications_tab.dart'
    as _i66;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_monitoring_tab.dart'
    as _i67;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_notes_tab.dart'
    as _i68;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_overview_tab.dart'
    as _i69;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_procedures_tab.dart'
    as _i71;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_vitals_tab.dart'
    as _i72;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_ward_round_tab.dart'
    as _i73;
import 'package:helty/src/nurses/waiting_patients.dart' as _i138;
import 'package:helty/src/obstetrics/ui/forms/add_antenatal_visit_screen.dart'
    as _i86;
import 'package:helty/src/obstetrics/ui/forms/add_baby_screen.dart' as _i87;
import 'package:helty/src/obstetrics/ui/forms/add_gynae_procedure_screen.dart'
    as _i88;
import 'package:helty/src/obstetrics/ui/forms/add_labour_delivery_screen.dart'
    as _i89;
import 'package:helty/src/obstetrics/ui/forms/add_partogram_entry_screen.dart'
    as _i90;
import 'package:helty/src/obstetrics/ui/forms/add_postnatal_visit_screen.dart'
    as _i91;
import 'package:helty/src/obstetrics/ui/forms/add_pregnancy_screen.dart'
    as _i92;
import 'package:helty/src/obstetrics/ui/forms/edit_antenatal_visit_screen.dart'
    as _i95;
import 'package:helty/src/obstetrics/ui/forms/edit_baby_screen.dart' as _i96;
import 'package:helty/src/obstetrics/ui/forms/edit_gynae_procedure_screen.dart'
    as _i97;
import 'package:helty/src/obstetrics/ui/forms/register_baby_screen.dart'
    as _i107;
import 'package:helty/src/obstetrics/ui/gynae_procedures_screen.dart' as _i98;
import 'package:helty/src/obstetrics/ui/labour_delivery_view_screen.dart'
    as _i100;
import 'package:helty/src/obstetrics/ui/obstetrics_dashboard_screen.dart'
    as _i94;
import 'package:helty/src/obstetrics/ui/obstetrics_patient_select_screen.dart'
    as _i101;
import 'package:helty/src/obstetrics/ui/postnatal_list_screen.dart' as _i102;
import 'package:helty/src/obstetrics/ui/pregnancies_list_screen.dart' as _i104;
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart' as _i106;
import 'package:helty/src/obstetrics/ui/tabs/antenatal_visits_tab.dart' as _i93;
import 'package:helty/src/obstetrics/ui/tabs/labour_delivery_tab.dart' as _i99;
import 'package:helty/src/obstetrics/ui/tabs/postnatal_tab.dart' as _i103;
import 'package:helty/src/obstetrics/ui/tabs/pregnancy_overview_tab.dart'
    as _i105;
import 'package:helty/src/paitients/patient_form_screen.dart' as _i109;
import 'package:helty/src/paitients/patient_list_screen.dart' as _i110;
import 'package:helty/src/paitients/patient_model.dart' as _i147;
import 'package:helty/src/paitients/view_waiting_patient.dart' as _i83;
import 'package:helty/src/pharmacy/models/pharmacy_model.dart' as _i143;
import 'package:helty/src/pharmacy/services/pharmacy_queue_service.dart'
    as _i148;
import 'package:helty/src/pharmacy/services/pharmacy_service.dart' as _i144;
import 'package:helty/src/pharmacy/ui/add.batches.dart' as _i1;
import 'package:helty/src/pharmacy/ui/add_drug_screen.dart' as _i4;
import 'package:helty/src/pharmacy/ui/add_supplier_screen.dart' as _i6;
import 'package:helty/src/pharmacy/ui/create_requisition.dart' as _i29;
import 'package:helty/src/pharmacy/ui/dispense_screen.dart' as _i31;
import 'package:helty/src/pharmacy/ui/dispensory.screen.dart' as _i115;
import 'package:helty/src/pharmacy/ui/location.screen.dart' as _i114;
import 'package:helty/src/pharmacy/ui/medicine_inventory.dart' as _i81;
import 'package:helty/src/pharmacy/ui/pharmacy_dashboard_screen.dart' as _i113;
import 'package:helty/src/pharmacy/ui/stock_transfer.dart' as _i124;
import 'package:helty/src/pharmacy/ui/suppliy.history.screen.dart' as _i132;
import 'package:helty/src/pharmacy/ui/waiting.patient.dart' as _i137;
import 'package:helty/src/radiology/ui/radiology_create_request_screen.dart'
    as _i116;
import 'package:helty/src/radiology/ui/radiology_dashboard_screen.dart'
    as _i117;
import 'package:helty/src/radiology/ui/radiology_patient_history_screen.dart'
    as _i118;
import 'package:helty/src/radiology/ui/radiology_request_detail_screen.dart'
    as _i119;
import 'package:helty/src/radiology/ui/radiology_worklist_screen.dart' as _i120;
import 'package:helty/src/store/ui/store_analytics_screen.dart' as _i125;
import 'package:helty/src/store/ui/store_categories_screen.dart' as _i126;
import 'package:helty/src/store/ui/store_dashboard_screen.dart' as _i127;
import 'package:helty/src/store/ui/store_items_screen.dart' as _i128;
import 'package:helty/src/store/ui/store_locations_screen.dart' as _i129;
import 'package:helty/src/store/ui/store_movements_screen.dart' as _i130;
import 'package:helty/src/store/ui/store_stock_screen.dart' as _i131;
import 'package:helty/src/transaction/transactions.screen.dart' as _i135;
import 'package:helty/src/ui/appointments/appointment_list_screen.dart' as _i7;
import 'package:helty/src/ui/appointments/create_appointment.dart' as _i82;
import 'package:helty/src/ui/auth/forgot_password_screen.dart' as _i55;
import 'package:helty/src/ui/auth/login_screen.dart' as _i80;
import 'package:helty/src/ui/auth/register_screen.dart' as _i121;
import 'package:helty/src/ui/auth/reset_password_screen.dart' as _i123;
import 'package:helty/src/ui/dashboard/dashboard_screen.dart' as _i30;
import 'package:helty/src/ui/home/home_screen.dart' as _i57;
import 'package:helty/src/ui/patients/today_patients.dart' as _i134;
import 'package:helty/src/ui/patinets_services/add_category_screen.dart' as _i2;
import 'package:helty/src/ui/patinets_services/add_department_screen.dart'
    as _i3;
import 'package:helty/src/ui/patinets_services/add_service_screen.dart' as _i5;
import 'package:helty/src/ui/patinets_services/enlist_service_screen.dart'
    as _i54;
import 'package:helty/src/ui/patinets_services/render_services.dart' as _i122;
import 'package:helty/src/ui/patinets_services/view_services.dart' as _i136;
import 'package:helty/src/ui/system_setup/bank_management_screen.dart' as _i8;
import 'package:helty/src/ui/transactions/pending_transactions.dart' as _i112;
import 'package:helty/src/widgets/not_avaliable.dart' as _i84;

/// generated route for
/// [_i1.AddBatchScreen]
class AddBatchRoute extends _i141.PageRouteInfo<void> {
  const AddBatchRoute({List<_i141.PageRouteInfo>? children})
    : super(AddBatchRoute.name, initialChildren: children);

  static const String name = 'AddBatchRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddBatchScreen();
    },
  );
}

/// generated route for
/// [_i2.AddCategoryScreen]
class AddCategoryRoute extends _i141.PageRouteInfo<void> {
  const AddCategoryRoute({List<_i141.PageRouteInfo>? children})
    : super(AddCategoryRoute.name, initialChildren: children);

  static const String name = 'AddCategoryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i2.AddCategoryScreen();
    },
  );
}

/// generated route for
/// [_i3.AddDepartmentScreen]
class AddDepartmentRoute extends _i141.PageRouteInfo<void> {
  const AddDepartmentRoute({List<_i141.PageRouteInfo>? children})
    : super(AddDepartmentRoute.name, initialChildren: children);

  static const String name = 'AddDepartmentRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddDepartmentScreen();
    },
  );
}

/// generated route for
/// [_i4.AddDrugScreen]
class AddDrugRoute extends _i141.PageRouteInfo<AddDrugRouteArgs> {
  AddDrugRoute({
    _i142.Key? key,
    _i143.Drug? existingDrug,
    _i144.PharmacyApiService? service,
    _i142.VoidCallback? onSaved,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         AddDrugRoute.name,
         args: AddDrugRouteArgs(
           key: key,
           existingDrug: existingDrug,
           service: service,
           onSaved: onSaved,
         ),
         initialChildren: children,
       );

  static const String name = 'AddDrugRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddDrugRouteArgs>(
        orElse: () => const AddDrugRouteArgs(),
      );
      return _i4.AddDrugScreen(
        key: args.key,
        existingDrug: args.existingDrug,
        service: args.service,
        onSaved: args.onSaved,
      );
    },
  );
}

class AddDrugRouteArgs {
  const AddDrugRouteArgs({
    this.key,
    this.existingDrug,
    this.service,
    this.onSaved,
  });

  final _i142.Key? key;

  final _i143.Drug? existingDrug;

  final _i144.PharmacyApiService? service;

  final _i142.VoidCallback? onSaved;

  @override
  String toString() {
    return 'AddDrugRouteArgs{key: $key, existingDrug: $existingDrug, service: $service, onSaved: $onSaved}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddDrugRouteArgs) return false;
    return key == other.key &&
        existingDrug == other.existingDrug &&
        service == other.service &&
        onSaved == other.onSaved;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      existingDrug.hashCode ^
      service.hashCode ^
      onSaved.hashCode;
}

/// generated route for
/// [_i5.AddServiceScreen]
class AddServiceRoute extends _i141.PageRouteInfo<void> {
  const AddServiceRoute({List<_i141.PageRouteInfo>? children})
    : super(AddServiceRoute.name, initialChildren: children);

  static const String name = 'AddServiceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i5.AddServiceScreen();
    },
  );
}

/// generated route for
/// [_i6.AddSupplierScreen]
class AddSupplierRoute extends _i141.PageRouteInfo<void> {
  const AddSupplierRoute({List<_i141.PageRouteInfo>? children})
    : super(AddSupplierRoute.name, initialChildren: children);

  static const String name = 'AddSupplierRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i6.AddSupplierScreen();
    },
  );
}

/// generated route for
/// [_i7.AppointmentListScreen]
class AppointmentListRoute extends _i141.PageRouteInfo<void> {
  const AppointmentListRoute({List<_i141.PageRouteInfo>? children})
    : super(AppointmentListRoute.name, initialChildren: children);

  static const String name = 'AppointmentListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i7.AppointmentListScreen();
    },
  );
}

/// generated route for
/// [_i8.BankManagementScreen]
class BankManagementRoute extends _i141.PageRouteInfo<void> {
  const BankManagementRoute({List<_i141.PageRouteInfo>? children})
    : super(BankManagementRoute.name, initialChildren: children);

  static const String name = 'BankManagementRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i8.BankManagementScreen();
    },
  );
}

/// generated route for
/// [_i9.BillingDashboardScreen]
class BillingDashboardRoute extends _i141.PageRouteInfo<void> {
  const BillingDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(BillingDashboardRoute.name, initialChildren: children);

  static const String name = 'BillingDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i9.BillingDashboardScreen();
    },
  );
}

/// generated route for
/// [_i10.CMDAlertsIncidentsScreen]
class CMDAlertsIncidentsRoute extends _i141.PageRouteInfo<void> {
  const CMDAlertsIncidentsRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDAlertsIncidentsRoute.name, initialChildren: children);

  static const String name = 'CMDAlertsIncidentsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i10.CMDAlertsIncidentsScreen();
    },
  );
}

/// generated route for
/// [_i11.CMDAuditComplianceScreen]
class CMDAuditComplianceRoute extends _i141.PageRouteInfo<void> {
  const CMDAuditComplianceRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDAuditComplianceRoute.name, initialChildren: children);

  static const String name = 'CMDAuditComplianceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i11.CMDAuditComplianceScreen();
    },
  );
}

/// generated route for
/// [_i12.CMDBedsFacilitiesScreen]
class CMDBedsFacilitiesRoute extends _i141.PageRouteInfo<void> {
  const CMDBedsFacilitiesRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDBedsFacilitiesRoute.name, initialChildren: children);

  static const String name = 'CMDBedsFacilitiesRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i12.CMDBedsFacilitiesScreen();
    },
  );
}

/// generated route for
/// [_i13.CMDCommunicationCenterScreen]
class CMDCommunicationCenterRoute extends _i141.PageRouteInfo<void> {
  const CMDCommunicationCenterRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDCommunicationCenterRoute.name, initialChildren: children);

  static const String name = 'CMDCommunicationCenterRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i13.CMDCommunicationCenterScreen();
    },
  );
}

/// generated route for
/// [_i14.CMDDashboardScreen]
class CMDDashboardRoute extends _i141.PageRouteInfo<void> {
  const CMDDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDDashboardRoute.name, initialChildren: children);

  static const String name = 'CMDDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i14.CMDDashboardScreen();
    },
  );
}

/// generated route for
/// [_i15.CMDFinancialCommandScreen]
class CMDFinancialCommandRoute extends _i141.PageRouteInfo<void> {
  const CMDFinancialCommandRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDFinancialCommandRoute.name, initialChildren: children);

  static const String name = 'CMDFinancialCommandRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i15.CMDFinancialCommandScreen();
    },
  );
}

/// generated route for
/// [_i16.CMDHospitalOverviewScreen]
class CMDHospitalOverviewRoute extends _i141.PageRouteInfo<void> {
  const CMDHospitalOverviewRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDHospitalOverviewRoute.name, initialChildren: children);

  static const String name = 'CMDHospitalOverviewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i16.CMDHospitalOverviewScreen();
    },
  );
}

/// generated route for
/// [_i17.CMDLabMonitoringScreen]
class CMDLabMonitoringRoute extends _i141.PageRouteInfo<void> {
  const CMDLabMonitoringRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDLabMonitoringRoute.name, initialChildren: children);

  static const String name = 'CMDLabMonitoringRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i17.CMDLabMonitoringScreen();
    },
  );
}

/// generated route for
/// [_i18.CMDPatientExperienceScreen]
class CMDPatientExperienceRoute extends _i141.PageRouteInfo<void> {
  const CMDPatientExperienceRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDPatientExperienceRoute.name, initialChildren: children);

  static const String name = 'CMDPatientExperienceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i18.CMDPatientExperienceScreen();
    },
  );
}

/// generated route for
/// [_i19.CMDReportsAnalyticsScreen]
class CMDReportsAnalyticsRoute extends _i141.PageRouteInfo<void> {
  const CMDReportsAnalyticsRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDReportsAnalyticsRoute.name, initialChildren: children);

  static const String name = 'CMDReportsAnalyticsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i19.CMDReportsAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i20.CMDStaffOversightScreen]
class CMDStaffOversightRoute extends _i141.PageRouteInfo<void> {
  const CMDStaffOversightRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDStaffOversightRoute.name, initialChildren: children);

  static const String name = 'CMDStaffOversightRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i20.CMDStaffOversightScreen();
    },
  );
}

/// generated route for
/// [_i21.CMDSystemControlScreen]
class CMDSystemControlRoute extends _i141.PageRouteInfo<void> {
  const CMDSystemControlRoute({List<_i141.PageRouteInfo>? children})
    : super(CMDSystemControlRoute.name, initialChildren: children);

  static const String name = 'CMDSystemControlRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i21.CMDSystemControlScreen();
    },
  );
}

/// generated route for
/// [_i22.CompletedEncounterDiagnosisTab]
class CompletedEncounterDiagnosisTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterDiagnosisTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterDiagnosisTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterDiagnosisTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i22.CompletedEncounterDiagnosisTab();
    },
  );
}

/// generated route for
/// [_i23.CompletedEncounterExaminationTab]
class CompletedEncounterExaminationTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterExaminationTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterExaminationTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterExaminationTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i23.CompletedEncounterExaminationTab();
    },
  );
}

/// generated route for
/// [_i24.CompletedEncounterFollowUpTab]
class CompletedEncounterFollowUpTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterFollowUpTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterFollowUpTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterFollowUpTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i24.CompletedEncounterFollowUpTab();
    },
  );
}

/// generated route for
/// [_i25.CompletedEncounterHistoryTab]
class CompletedEncounterHistoryTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterHistoryTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterHistoryTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterHistoryTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i25.CompletedEncounterHistoryTab();
    },
  );
}

/// generated route for
/// [_i26.CompletedEncounterNotesTab]
class CompletedEncounterNotesTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterNotesTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterNotesTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterNotesTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i26.CompletedEncounterNotesTab();
    },
  );
}

/// generated route for
/// [_i27.CompletedEncounterSummaryTab]
class CompletedEncounterSummaryTab extends _i141.PageRouteInfo<void> {
  const CompletedEncounterSummaryTab({List<_i141.PageRouteInfo>? children})
    : super(CompletedEncounterSummaryTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterSummaryTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i27.CompletedEncounterSummaryTab();
    },
  );
}

/// generated route for
/// [_i28.ConsultingRoomsScreen]
class ConsultingRoomsRoute extends _i141.PageRouteInfo<void> {
  const ConsultingRoomsRoute({List<_i141.PageRouteInfo>? children})
    : super(ConsultingRoomsRoute.name, initialChildren: children);

  static const String name = 'ConsultingRoomsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i28.ConsultingRoomsScreen();
    },
  );
}

/// generated route for
/// [_i29.CreateRequisitionScreen]
class CreateRequisitionRoute extends _i141.PageRouteInfo<void> {
  const CreateRequisitionRoute({List<_i141.PageRouteInfo>? children})
    : super(CreateRequisitionRoute.name, initialChildren: children);

  static const String name = 'CreateRequisitionRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i29.CreateRequisitionScreen();
    },
  );
}

/// generated route for
/// [_i30.DashboardScreen]
class DashboardRoute extends _i141.PageRouteInfo<void> {
  const DashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i30.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i31.DispenseScreen]
class DispenseRoute extends _i141.PageRouteInfo<DispenseRouteArgs> {
  DispenseRoute({
    _i142.Key? key,
    required String patientId,
    required String patientName,
    required String id,
    String? invoiceId,
    String? staffId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         DispenseRoute.name,
         args: DispenseRouteArgs(
           key: key,
           patientId: patientId,
           patientName: patientName,
           id: id,
           invoiceId: invoiceId,
           staffId: staffId,
         ),
         initialChildren: children,
       );

  static const String name = 'DispenseRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DispenseRouteArgs>();
      return _i31.DispenseScreen(
        key: args.key,
        patientId: args.patientId,
        patientName: args.patientName,
        id: args.id,
        invoiceId: args.invoiceId,
        staffId: args.staffId,
      );
    },
  );
}

class DispenseRouteArgs {
  const DispenseRouteArgs({
    this.key,
    required this.patientId,
    required this.patientName,
    required this.id,
    this.invoiceId,
    this.staffId,
  });

  final _i142.Key? key;

  final String patientId;

  final String patientName;

  final String id;

  final String? invoiceId;

  final String? staffId;

  @override
  String toString() {
    return 'DispenseRouteArgs{key: $key, patientId: $patientId, patientName: $patientName, id: $id, invoiceId: $invoiceId, staffId: $staffId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DispenseRouteArgs) return false;
    return key == other.key &&
        patientId == other.patientId &&
        patientName == other.patientName &&
        id == other.id &&
        invoiceId == other.invoiceId &&
        staffId == other.staffId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      patientId.hashCode ^
      patientName.hashCode ^
      id.hashCode ^
      invoiceId.hashCode ^
      staffId.hashCode;
}

/// generated route for
/// [_i32.DoctorCompletedEncounterViewScreen]
class DoctorCompletedEncounterViewRoute
    extends _i141.PageRouteInfo<DoctorCompletedEncounterViewRouteArgs> {
  DoctorCompletedEncounterViewRoute({
    _i142.Key? key,
    required String encounterId,
    required String patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         DoctorCompletedEncounterViewRoute.name,
         args: DoctorCompletedEncounterViewRouteArgs(
           key: key,
           encounterId: encounterId,
           patientId: patientId,
         ),
         initialChildren: children,
       );

  static const String name = 'DoctorCompletedEncounterViewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DoctorCompletedEncounterViewRouteArgs>();
      return _i32.DoctorCompletedEncounterViewScreen(
        key: args.key,
        encounterId: args.encounterId,
        patientId: args.patientId,
      );
    },
  );
}

class DoctorCompletedEncounterViewRouteArgs {
  const DoctorCompletedEncounterViewRouteArgs({
    this.key,
    required this.encounterId,
    required this.patientId,
  });

  final _i142.Key? key;

  final String encounterId;

  final String patientId;

  @override
  String toString() {
    return 'DoctorCompletedEncounterViewRouteArgs{key: $key, encounterId: $encounterId, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoctorCompletedEncounterViewRouteArgs) return false;
    return key == other.key &&
        encounterId == other.encounterId &&
        patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ encounterId.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i33.DoctorCompletedEncountersScreen]
class DoctorCompletedEncountersRoute extends _i141.PageRouteInfo<void> {
  const DoctorCompletedEncountersRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorCompletedEncountersRoute.name, initialChildren: children);

  static const String name = 'DoctorCompletedEncountersRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i33.DoctorCompletedEncountersScreen();
    },
  );
}

/// generated route for
/// [_i34.DoctorDashboardScreen]
class DoctorDashboardRoute extends _i141.PageRouteInfo<void> {
  const DoctorDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorDashboardRoute.name, initialChildren: children);

  static const String name = 'DoctorDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i34.DoctorDashboardScreen();
    },
  );
}

/// generated route for
/// [_i35.DoctorEncounterAdmissionTab]
class DoctorEncounterAdmissionTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterAdmissionTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterAdmissionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterAdmissionTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i35.DoctorEncounterAdmissionTab();
    },
  );
}

/// generated route for
/// [_i36.DoctorEncounterDiagnosisTab]
class DoctorEncounterDiagnosisTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterDiagnosisTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterDiagnosisTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterDiagnosisTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i36.DoctorEncounterDiagnosisTab();
    },
  );
}

/// generated route for
/// [_i37.DoctorEncounterExaminationTab]
class DoctorEncounterExaminationTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterExaminationTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterExaminationTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterExaminationTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i37.DoctorEncounterExaminationTab();
    },
  );
}

/// generated route for
/// [_i38.DoctorEncounterFollowUpTab]
class DoctorEncounterFollowUpTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterFollowUpTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterFollowUpTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterFollowUpTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i38.DoctorEncounterFollowUpTab();
    },
  );
}

/// generated route for
/// [_i39.DoctorEncounterHistoryTab]
class DoctorEncounterHistoryTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterHistoryTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterHistoryTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterHistoryTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i39.DoctorEncounterHistoryTab();
    },
  );
}

/// generated route for
/// [_i40.DoctorEncounterImagingTab]
class DoctorEncounterImagingTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterImagingTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterImagingTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterImagingTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i40.DoctorEncounterImagingTab();
    },
  );
}

/// generated route for
/// [_i41.DoctorEncounterInvestigationsTab]
class DoctorEncounterInvestigationsTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterInvestigationsTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterInvestigationsTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterInvestigationsTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i41.DoctorEncounterInvestigationsTab();
    },
  );
}

/// generated route for
/// [_i42.DoctorEncounterNotesTab]
class DoctorEncounterNotesTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterNotesTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterNotesTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterNotesTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i42.DoctorEncounterNotesTab();
    },
  );
}

/// generated route for
/// [_i43.DoctorEncounterPrescriptionTab]
class DoctorEncounterPrescriptionTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterPrescriptionTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterPrescriptionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterPrescriptionTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i43.DoctorEncounterPrescriptionTab();
    },
  );
}

/// generated route for
/// [_i44.DoctorEncounterProceduresTab]
class DoctorEncounterProceduresTab extends _i141.PageRouteInfo<void> {
  const DoctorEncounterProceduresTab({List<_i141.PageRouteInfo>? children})
    : super(DoctorEncounterProceduresTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterProceduresTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i44.DoctorEncounterProceduresTab();
    },
  );
}

/// generated route for
/// [_i45.DoctorEncounterViewScreen]
class DoctorEncounterViewRoute
    extends _i141.PageRouteInfo<DoctorEncounterViewRouteArgs> {
  DoctorEncounterViewRoute({
    _i142.Key? key,
    required String encounterId,
    required String patientId,
    String? patientVitalsJson,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         DoctorEncounterViewRoute.name,
         args: DoctorEncounterViewRouteArgs(
           key: key,
           encounterId: encounterId,
           patientId: patientId,
           patientVitalsJson: patientVitalsJson,
         ),
         initialChildren: children,
       );

  static const String name = 'DoctorEncounterViewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DoctorEncounterViewRouteArgs>();
      return _i45.DoctorEncounterViewScreen(
        key: args.key,
        encounterId: args.encounterId,
        patientId: args.patientId,
        patientVitalsJson: args.patientVitalsJson,
      );
    },
  );
}

class DoctorEncounterViewRouteArgs {
  const DoctorEncounterViewRouteArgs({
    this.key,
    required this.encounterId,
    required this.patientId,
    this.patientVitalsJson,
  });

  final _i142.Key? key;

  final String encounterId;

  final String patientId;

  final String? patientVitalsJson;

  @override
  String toString() {
    return 'DoctorEncounterViewRouteArgs{key: $key, encounterId: $encounterId, patientId: $patientId, patientVitalsJson: $patientVitalsJson}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DoctorEncounterViewRouteArgs) return false;
    return key == other.key &&
        encounterId == other.encounterId &&
        patientId == other.patientId &&
        patientVitalsJson == other.patientVitalsJson;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      encounterId.hashCode ^
      patientId.hashCode ^
      patientVitalsJson.hashCode;
}

/// generated route for
/// [_i46.DoctorOutpatientListScreen]
class DoctorOutpatientListRoute extends _i141.PageRouteInfo<void> {
  const DoctorOutpatientListRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorOutpatientListRoute.name, initialChildren: children);

  static const String name = 'DoctorOutpatientListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i46.DoctorOutpatientListScreen();
    },
  );
}

/// generated route for
/// [_i47.DoctorPendingImagingScreen]
class DoctorPendingImagingRoute extends _i141.PageRouteInfo<void> {
  const DoctorPendingImagingRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorPendingImagingRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingImagingRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i47.DoctorPendingImagingScreen();
    },
  );
}

/// generated route for
/// [_i48.DoctorPendingLabsScreen]
class DoctorPendingLabsRoute extends _i141.PageRouteInfo<void> {
  const DoctorPendingLabsRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorPendingLabsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingLabsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i48.DoctorPendingLabsScreen();
    },
  );
}

/// generated route for
/// [_i49.DoctorPendingPrescriptionsScreen]
class DoctorPendingPrescriptionsRoute extends _i141.PageRouteInfo<void> {
  const DoctorPendingPrescriptionsRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorPendingPrescriptionsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingPrescriptionsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i49.DoctorPendingPrescriptionsScreen();
    },
  );
}

/// generated route for
/// [_i50.DoctorProfileScreen]
class DoctorProfileRoute extends _i141.PageRouteInfo<void> {
  const DoctorProfileRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorProfileRoute.name, initialChildren: children);

  static const String name = 'DoctorProfileRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i50.DoctorProfileScreen();
    },
  );
}

/// generated route for
/// [_i51.DoctorTemplatesScreen]
class DoctorTemplatesRoute extends _i141.PageRouteInfo<void> {
  const DoctorTemplatesRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorTemplatesRoute.name, initialChildren: children);

  static const String name = 'DoctorTemplatesRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i51.DoctorTemplatesScreen();
    },
  );
}

/// generated route for
/// [_i52.DoctorWalkInQueueScreen]
class DoctorWalkInQueueRoute extends _i141.PageRouteInfo<void> {
  const DoctorWalkInQueueRoute({List<_i141.PageRouteInfo>? children})
    : super(DoctorWalkInQueueRoute.name, initialChildren: children);

  static const String name = 'DoctorWalkInQueueRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i52.DoctorWalkInQueueScreen();
    },
  );
}

/// generated route for
/// [_i53.EnlistPaitientScreen]
class EnlistPaitientRoute extends _i141.PageRouteInfo<EnlistPaitientRouteArgs> {
  EnlistPaitientRoute({
    _i142.Key? key,
    required String serviceName,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         EnlistPaitientRoute.name,
         args: EnlistPaitientRouteArgs(key: key, serviceName: serviceName),
         initialChildren: children,
       );

  static const String name = 'EnlistPaitientRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EnlistPaitientRouteArgs>();
      return _i53.EnlistPaitientScreen(
        key: args.key,
        serviceName: args.serviceName,
      );
    },
  );
}

class EnlistPaitientRouteArgs {
  const EnlistPaitientRouteArgs({this.key, required this.serviceName});

  final _i142.Key? key;

  final String serviceName;

  @override
  String toString() {
    return 'EnlistPaitientRouteArgs{key: $key, serviceName: $serviceName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EnlistPaitientRouteArgs) return false;
    return key == other.key && serviceName == other.serviceName;
  }

  @override
  int get hashCode => key.hashCode ^ serviceName.hashCode;
}

/// generated route for
/// [_i54.EnlistServiceScreen]
class EnlistServiceRoute extends _i141.PageRouteInfo<void> {
  const EnlistServiceRoute({List<_i141.PageRouteInfo>? children})
    : super(EnlistServiceRoute.name, initialChildren: children);

  static const String name = 'EnlistServiceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i54.EnlistServiceScreen();
    },
  );
}

/// generated route for
/// [_i55.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i141.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i141.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i55.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i56.FrontDeskDashboardScreen]
class FrontDeskDashboardRoute extends _i141.PageRouteInfo<void> {
  const FrontDeskDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(FrontDeskDashboardRoute.name, initialChildren: children);

  static const String name = 'FrontDeskDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i56.FrontDeskDashboardScreen();
    },
  );
}

/// generated route for
/// [_i57.HomeScreen]
class HomeRoute extends _i141.PageRouteInfo<void> {
  const HomeRoute({List<_i141.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i57.HomeScreen();
    },
  );
}

/// generated route for
/// [_i58.InpatientAlertsScreen]
class InpatientAlertsRoute extends _i141.PageRouteInfo<void> {
  const InpatientAlertsRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientAlertsRoute.name, initialChildren: children);

  static const String name = 'InpatientAlertsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i58.InpatientAlertsScreen();
    },
  );
}

/// generated route for
/// [_i59.InpatientBillsListScreen]
class InpatientBillsListRoute extends _i141.PageRouteInfo<void> {
  const InpatientBillsListRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientBillsListRoute.name, initialChildren: children);

  static const String name = 'InpatientBillsListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i59.InpatientBillsListScreen();
    },
  );
}

/// generated route for
/// [_i60.InpatientCarePlanScreen]
class InpatientCarePlanRoute extends _i141.PageRouteInfo<void> {
  const InpatientCarePlanRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientCarePlanRoute.name, initialChildren: children);

  static const String name = 'InpatientCarePlanRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i60.InpatientCarePlanScreen();
    },
  );
}

/// generated route for
/// [_i61.InpatientHandoverScreen]
class InpatientHandoverRoute extends _i141.PageRouteInfo<void> {
  const InpatientHandoverRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientHandoverRoute.name, initialChildren: children);

  static const String name = 'InpatientHandoverRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i61.InpatientHandoverScreen();
    },
  );
}

/// generated route for
/// [_i62.InpatientIOScreen]
class InpatientIORoute extends _i141.PageRouteInfo<void> {
  const InpatientIORoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientIORoute.name, initialChildren: children);

  static const String name = 'InpatientIORoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i62.InpatientIOScreen();
    },
  );
}

/// generated route for
/// [_i63.InpatientIVScreen]
class InpatientIVRoute extends _i141.PageRouteInfo<void> {
  const InpatientIVRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientIVRoute.name, initialChildren: children);

  static const String name = 'InpatientIVRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i63.InpatientIVScreen();
    },
  );
}

/// generated route for
/// [_i64.InpatientImagingResultsScreen]
class InpatientImagingResultsRoute extends _i141.PageRouteInfo<void> {
  const InpatientImagingResultsRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientImagingResultsRoute.name, initialChildren: children);

  static const String name = 'InpatientImagingResultsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i64.InpatientImagingResultsScreen();
    },
  );
}

/// generated route for
/// [_i65.InpatientLabResultsScreen]
class InpatientLabResultsRoute extends _i141.PageRouteInfo<void> {
  const InpatientLabResultsRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientLabResultsRoute.name, initialChildren: children);

  static const String name = 'InpatientLabResultsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i65.InpatientLabResultsScreen();
    },
  );
}

/// generated route for
/// [_i66.InpatientMedicationsScreen]
class InpatientMedicationsRoute extends _i141.PageRouteInfo<void> {
  const InpatientMedicationsRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientMedicationsRoute.name, initialChildren: children);

  static const String name = 'InpatientMedicationsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i66.InpatientMedicationsScreen();
    },
  );
}

/// generated route for
/// [_i67.InpatientMonitoringScreen]
class InpatientMonitoringRoute extends _i141.PageRouteInfo<void> {
  const InpatientMonitoringRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientMonitoringRoute.name, initialChildren: children);

  static const String name = 'InpatientMonitoringRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i67.InpatientMonitoringScreen();
    },
  );
}

/// generated route for
/// [_i68.InpatientNotesScreen]
class InpatientNotesRoute extends _i141.PageRouteInfo<void> {
  const InpatientNotesRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientNotesRoute.name, initialChildren: children);

  static const String name = 'InpatientNotesRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i68.InpatientNotesScreen();
    },
  );
}

/// generated route for
/// [_i69.InpatientOverviewScreen]
class InpatientOverviewRoute extends _i141.PageRouteInfo<void> {
  const InpatientOverviewRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientOverviewRoute.name, initialChildren: children);

  static const String name = 'InpatientOverviewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i69.InpatientOverviewScreen();
    },
  );
}

/// generated route for
/// [_i70.InpatientPatientViewScreen]
class InpatientPatientViewRoute
    extends _i141.PageRouteInfo<InpatientPatientViewRouteArgs> {
  InpatientPatientViewRoute({
    _i142.Key? key,
    required String admissionId,
    String? ward,
    String? bedNumber,
    String? attendingDoctor,
    String? diagnosis,
    DateTime? admissionDate,
    List<String>? allergies,
    String? codeStatus,
    List<String>? riskFlags,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         InpatientPatientViewRoute.name,
         args: InpatientPatientViewRouteArgs(
           key: key,
           admissionId: admissionId,
           ward: ward,
           bedNumber: bedNumber,
           attendingDoctor: attendingDoctor,
           diagnosis: diagnosis,
           admissionDate: admissionDate,
           allergies: allergies,
           codeStatus: codeStatus,
           riskFlags: riskFlags,
         ),
         initialChildren: children,
       );

  static const String name = 'InpatientPatientViewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InpatientPatientViewRouteArgs>();
      return _i70.InpatientPatientViewScreen(
        key: args.key,
        admissionId: args.admissionId,
        ward: args.ward,
        bedNumber: args.bedNumber,
        attendingDoctor: args.attendingDoctor,
        diagnosis: args.diagnosis,
        admissionDate: args.admissionDate,
        allergies: args.allergies,
        codeStatus: args.codeStatus,
        riskFlags: args.riskFlags,
      );
    },
  );
}

class InpatientPatientViewRouteArgs {
  const InpatientPatientViewRouteArgs({
    this.key,
    required this.admissionId,
    this.ward,
    this.bedNumber,
    this.attendingDoctor,
    this.diagnosis,
    this.admissionDate,
    this.allergies,
    this.codeStatus,
    this.riskFlags,
  });

  final _i142.Key? key;

  final String admissionId;

  final String? ward;

  final String? bedNumber;

  final String? attendingDoctor;

  final String? diagnosis;

  final DateTime? admissionDate;

  final List<String>? allergies;

  final String? codeStatus;

  final List<String>? riskFlags;

  @override
  String toString() {
    return 'InpatientPatientViewRouteArgs{key: $key, admissionId: $admissionId, ward: $ward, bedNumber: $bedNumber, attendingDoctor: $attendingDoctor, diagnosis: $diagnosis, admissionDate: $admissionDate, allergies: $allergies, codeStatus: $codeStatus, riskFlags: $riskFlags}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InpatientPatientViewRouteArgs) return false;
    return key == other.key &&
        admissionId == other.admissionId &&
        ward == other.ward &&
        bedNumber == other.bedNumber &&
        attendingDoctor == other.attendingDoctor &&
        diagnosis == other.diagnosis &&
        admissionDate == other.admissionDate &&
        const _i145.ListEquality<String>().equals(allergies, other.allergies) &&
        codeStatus == other.codeStatus &&
        const _i145.ListEquality<String>().equals(riskFlags, other.riskFlags);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      admissionId.hashCode ^
      ward.hashCode ^
      bedNumber.hashCode ^
      attendingDoctor.hashCode ^
      diagnosis.hashCode ^
      admissionDate.hashCode ^
      const _i145.ListEquality<String>().hash(allergies) ^
      codeStatus.hashCode ^
      const _i145.ListEquality<String>().hash(riskFlags);
}

/// generated route for
/// [_i71.InpatientProceduresScreen]
class InpatientProceduresRoute extends _i141.PageRouteInfo<void> {
  const InpatientProceduresRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientProceduresRoute.name, initialChildren: children);

  static const String name = 'InpatientProceduresRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i71.InpatientProceduresScreen();
    },
  );
}

/// generated route for
/// [_i72.InpatientVitalsScreen]
class InpatientVitalsRoute
    extends _i141.PageRouteInfo<InpatientVitalsRouteArgs> {
  InpatientVitalsRoute({
    _i142.Key? key,
    required List<_i146.PatientVitalsModel> vitals,
    required String admissionId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         InpatientVitalsRoute.name,
         args: InpatientVitalsRouteArgs(
           key: key,
           vitals: vitals,
           admissionId: admissionId,
         ),
         initialChildren: children,
       );

  static const String name = 'InpatientVitalsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InpatientVitalsRouteArgs>();
      return _i72.InpatientVitalsScreen(
        key: args.key,
        vitals: args.vitals,
        admissionId: args.admissionId,
      );
    },
  );
}

class InpatientVitalsRouteArgs {
  const InpatientVitalsRouteArgs({
    this.key,
    required this.vitals,
    required this.admissionId,
  });

  final _i142.Key? key;

  final List<_i146.PatientVitalsModel> vitals;

  final String admissionId;

  @override
  String toString() {
    return 'InpatientVitalsRouteArgs{key: $key, vitals: $vitals, admissionId: $admissionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InpatientVitalsRouteArgs) return false;
    return key == other.key &&
        const _i145.ListEquality<_i146.PatientVitalsModel>().equals(
          vitals,
          other.vitals,
        ) &&
        admissionId == other.admissionId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const _i145.ListEquality<_i146.PatientVitalsModel>().hash(vitals) ^
      admissionId.hashCode;
}

/// generated route for
/// [_i73.InpatientWardRoundTab]
class InpatientWardRoundTab extends _i141.PageRouteInfo<void> {
  const InpatientWardRoundTab({List<_i141.PageRouteInfo>? children})
    : super(InpatientWardRoundTab.name, initialChildren: children);

  static const String name = 'InpatientWardRoundTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i73.InpatientWardRoundTab();
    },
  );
}

/// generated route for
/// [_i74.InpatientsListScreen]
class InpatientsListRoute extends _i141.PageRouteInfo<void> {
  const InpatientsListRoute({List<_i141.PageRouteInfo>? children})
    : super(InpatientsListRoute.name, initialChildren: children);

  static const String name = 'InpatientsListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i74.InpatientsListScreen();
    },
  );
}

/// generated route for
/// [_i75.LabConfigScreen]
class LabConfigRoute extends _i141.PageRouteInfo<void> {
  const LabConfigRoute({List<_i141.PageRouteInfo>? children})
    : super(LabConfigRoute.name, initialChildren: children);

  static const String name = 'LabConfigRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i75.LabConfigScreen();
    },
  );
}

/// generated route for
/// [_i76.LabCreateOrderScreen]
class LabCreateOrderRoute extends _i141.PageRouteInfo<void> {
  const LabCreateOrderRoute({List<_i141.PageRouteInfo>? children})
    : super(LabCreateOrderRoute.name, initialChildren: children);

  static const String name = 'LabCreateOrderRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i76.LabCreateOrderScreen();
    },
  );
}

/// generated route for
/// [_i77.LabDashboardScreen]
class LabDashboardRoute extends _i141.PageRouteInfo<void> {
  const LabDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(LabDashboardRoute.name, initialChildren: children);

  static const String name = 'LabDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i77.LabDashboardScreen();
    },
  );
}

/// generated route for
/// [_i78.LabOrderDetailScreen]
class LabOrderDetailRoute extends _i141.PageRouteInfo<LabOrderDetailRouteArgs> {
  LabOrderDetailRoute({
    _i142.Key? key,
    required String orderId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         LabOrderDetailRoute.name,
         args: LabOrderDetailRouteArgs(key: key, orderId: orderId),
         initialChildren: children,
       );

  static const String name = 'LabOrderDetailRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LabOrderDetailRouteArgs>();
      return _i78.LabOrderDetailScreen(key: args.key, orderId: args.orderId);
    },
  );
}

class LabOrderDetailRouteArgs {
  const LabOrderDetailRouteArgs({this.key, required this.orderId});

  final _i142.Key? key;

  final String orderId;

  @override
  String toString() {
    return 'LabOrderDetailRouteArgs{key: $key, orderId: $orderId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LabOrderDetailRouteArgs) return false;
    return key == other.key && orderId == other.orderId;
  }

  @override
  int get hashCode => key.hashCode ^ orderId.hashCode;
}

/// generated route for
/// [_i79.LabResultEntryScreen]
class LabResultEntryRoute extends _i141.PageRouteInfo<LabResultEntryRouteArgs> {
  LabResultEntryRoute({
    _i142.Key? key,
    required String orderId,
    required String orderItemId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         LabResultEntryRoute.name,
         args: LabResultEntryRouteArgs(
           key: key,
           orderId: orderId,
           orderItemId: orderItemId,
         ),
         initialChildren: children,
       );

  static const String name = 'LabResultEntryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LabResultEntryRouteArgs>();
      return _i79.LabResultEntryScreen(
        key: args.key,
        orderId: args.orderId,
        orderItemId: args.orderItemId,
      );
    },
  );
}

class LabResultEntryRouteArgs {
  const LabResultEntryRouteArgs({
    this.key,
    required this.orderId,
    required this.orderItemId,
  });

  final _i142.Key? key;

  final String orderId;

  final String orderItemId;

  @override
  String toString() {
    return 'LabResultEntryRouteArgs{key: $key, orderId: $orderId, orderItemId: $orderItemId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LabResultEntryRouteArgs) return false;
    return key == other.key &&
        orderId == other.orderId &&
        orderItemId == other.orderItemId;
  }

  @override
  int get hashCode => key.hashCode ^ orderId.hashCode ^ orderItemId.hashCode;
}

/// generated route for
/// [_i80.LoginScreen]
class LoginRoute extends _i141.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i142.Key? key,
    String? redirectTo,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, redirectTo: redirectTo),
         rawQueryParams: {'redirectTo': redirectTo},
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(redirectTo: queryParams.optString('redirectTo')),
      );
      return _i80.LoginScreen(key: args.key, redirectTo: args.redirectTo);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.redirectTo});

  final _i142.Key? key;

  final String? redirectTo;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, redirectTo: $redirectTo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && redirectTo == other.redirectTo;
  }

  @override
  int get hashCode => key.hashCode ^ redirectTo.hashCode;
}

/// generated route for
/// [_i81.MedicineInventoryScreen]
class MedicineInventoryRoute extends _i141.PageRouteInfo<void> {
  const MedicineInventoryRoute({List<_i141.PageRouteInfo>? children})
    : super(MedicineInventoryRoute.name, initialChildren: children);

  static const String name = 'MedicineInventoryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i81.MedicineInventoryScreen();
    },
  );
}

/// generated route for
/// [_i82.NewAppointmentScreen]
class NewAppointmentRoute extends _i141.PageRouteInfo<void> {
  const NewAppointmentRoute({List<_i141.PageRouteInfo>? children})
    : super(NewAppointmentRoute.name, initialChildren: children);

  static const String name = 'NewAppointmentRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i82.NewAppointmentScreen();
    },
  );
}

/// generated route for
/// [_i83.NewPatientScreen]
class NewPatientRoute extends _i141.PageRouteInfo<NewPatientRouteArgs> {
  NewPatientRoute({
    _i142.Key? key,
    String use = 'For Register',
    List<String> categoryQueries = const [],
    List<_i141.PageRouteInfo>? children,
  }) : super(
         NewPatientRoute.name,
         args: NewPatientRouteArgs(
           key: key,
           use: use,
           categoryQueries: categoryQueries,
         ),
         initialChildren: children,
       );

  static const String name = 'NewPatientRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewPatientRouteArgs>(
        orElse: () => const NewPatientRouteArgs(),
      );
      return _i83.NewPatientScreen(
        key: args.key,
        use: args.use,
        categoryQueries: args.categoryQueries,
      );
    },
  );
}

class NewPatientRouteArgs {
  const NewPatientRouteArgs({
    this.key,
    this.use = 'For Register',
    this.categoryQueries = const [],
  });

  final _i142.Key? key;

  final String use;

  final List<String> categoryQueries;

  @override
  String toString() {
    return 'NewPatientRouteArgs{key: $key, use: $use, categoryQueries: $categoryQueries}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewPatientRouteArgs) return false;
    return key == other.key &&
        use == other.use &&
        const _i145.ListEquality<String>().equals(
          categoryQueries,
          other.categoryQueries,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      use.hashCode ^
      const _i145.ListEquality<String>().hash(categoryQueries);
}

/// generated route for
/// [_i84.NotAvailableScreen]
class NotAvailableRoute extends _i141.PageRouteInfo<void> {
  const NotAvailableRoute({List<_i141.PageRouteInfo>? children})
    : super(NotAvailableRoute.name, initialChildren: children);

  static const String name = 'NotAvailableRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i84.NotAvailableScreen();
    },
  );
}

/// generated route for
/// [_i85.NursesDashboardScreen]
class NursesDashboardRoute extends _i141.PageRouteInfo<void> {
  const NursesDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(NursesDashboardRoute.name, initialChildren: children);

  static const String name = 'NursesDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i85.NursesDashboardScreen();
    },
  );
}

/// generated route for
/// [_i86.ObstetricsAddAntenatalVisitScreen]
class ObstetricsAddAntenatalVisitRoute
    extends _i141.PageRouteInfo<ObstetricsAddAntenatalVisitRouteArgs> {
  ObstetricsAddAntenatalVisitRoute({
    _i142.Key? key,
    required String pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddAntenatalVisitRoute.name,
         args: ObstetricsAddAntenatalVisitRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddAntenatalVisitRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddAntenatalVisitRouteArgs>();
      return _i86.ObstetricsAddAntenatalVisitScreen(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsAddAntenatalVisitRouteArgs {
  const ObstetricsAddAntenatalVisitRouteArgs({
    this.key,
    required this.pregnancyId,
  });

  final _i142.Key? key;

  final String pregnancyId;

  @override
  String toString() {
    return 'ObstetricsAddAntenatalVisitRouteArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddAntenatalVisitRouteArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i87.ObstetricsAddBabyScreen]
class ObstetricsAddBabyRoute
    extends _i141.PageRouteInfo<ObstetricsAddBabyRouteArgs> {
  ObstetricsAddBabyRoute({
    _i142.Key? key,
    required String labourDeliveryId,
    required String pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddBabyRoute.name,
         args: ObstetricsAddBabyRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddBabyRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddBabyRouteArgs>();
      return _i87.ObstetricsAddBabyScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsAddBabyRouteArgs {
  const ObstetricsAddBabyRouteArgs({
    this.key,
    required this.labourDeliveryId,
    required this.pregnancyId,
  });

  final _i142.Key? key;

  final String labourDeliveryId;

  final String pregnancyId;

  @override
  String toString() {
    return 'ObstetricsAddBabyRouteArgs{key: $key, labourDeliveryId: $labourDeliveryId, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddBabyRouteArgs) return false;
    return key == other.key &&
        labourDeliveryId == other.labourDeliveryId &&
        pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ labourDeliveryId.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i88.ObstetricsAddGynaeProcedureScreen]
class ObstetricsAddGynaeProcedureRoute
    extends _i141.PageRouteInfo<ObstetricsAddGynaeProcedureRouteArgs> {
  ObstetricsAddGynaeProcedureRoute({
    _i142.Key? key,
    String? patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddGynaeProcedureRoute.name,
         args: ObstetricsAddGynaeProcedureRouteArgs(
           key: key,
           patientId: patientId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddGynaeProcedureRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddGynaeProcedureRouteArgs>(
        orElse: () => const ObstetricsAddGynaeProcedureRouteArgs(),
      );
      return _i88.ObstetricsAddGynaeProcedureScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsAddGynaeProcedureRouteArgs {
  const ObstetricsAddGynaeProcedureRouteArgs({this.key, this.patientId});

  final _i142.Key? key;

  final String? patientId;

  @override
  String toString() {
    return 'ObstetricsAddGynaeProcedureRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddGynaeProcedureRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i89.ObstetricsAddLabourDeliveryScreen]
class ObstetricsAddLabourDeliveryRoute
    extends _i141.PageRouteInfo<ObstetricsAddLabourDeliveryRouteArgs> {
  ObstetricsAddLabourDeliveryRoute({
    _i142.Key? key,
    required String pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddLabourDeliveryRoute.name,
         args: ObstetricsAddLabourDeliveryRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddLabourDeliveryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddLabourDeliveryRouteArgs>();
      return _i89.ObstetricsAddLabourDeliveryScreen(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsAddLabourDeliveryRouteArgs {
  const ObstetricsAddLabourDeliveryRouteArgs({
    this.key,
    required this.pregnancyId,
  });

  final _i142.Key? key;

  final String pregnancyId;

  @override
  String toString() {
    return 'ObstetricsAddLabourDeliveryRouteArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddLabourDeliveryRouteArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i90.ObstetricsAddPartogramEntryScreen]
class ObstetricsAddPartogramEntryRoute
    extends _i141.PageRouteInfo<ObstetricsAddPartogramEntryRouteArgs> {
  ObstetricsAddPartogramEntryRoute({
    _i142.Key? key,
    required String labourDeliveryId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPartogramEntryRoute.name,
         args: ObstetricsAddPartogramEntryRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPartogramEntryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPartogramEntryRouteArgs>();
      return _i90.ObstetricsAddPartogramEntryScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
      );
    },
  );
}

class ObstetricsAddPartogramEntryRouteArgs {
  const ObstetricsAddPartogramEntryRouteArgs({
    this.key,
    required this.labourDeliveryId,
  });

  final _i142.Key? key;

  final String labourDeliveryId;

  @override
  String toString() {
    return 'ObstetricsAddPartogramEntryRouteArgs{key: $key, labourDeliveryId: $labourDeliveryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddPartogramEntryRouteArgs) return false;
    return key == other.key && labourDeliveryId == other.labourDeliveryId;
  }

  @override
  int get hashCode => key.hashCode ^ labourDeliveryId.hashCode;
}

/// generated route for
/// [_i91.ObstetricsAddPostnatalVisitScreen]
class ObstetricsAddPostnatalVisitRoute
    extends _i141.PageRouteInfo<ObstetricsAddPostnatalVisitRouteArgs> {
  ObstetricsAddPostnatalVisitRoute({
    _i142.Key? key,
    required String labourDeliveryId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPostnatalVisitRoute.name,
         args: ObstetricsAddPostnatalVisitRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPostnatalVisitRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPostnatalVisitRouteArgs>();
      return _i91.ObstetricsAddPostnatalVisitScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
      );
    },
  );
}

class ObstetricsAddPostnatalVisitRouteArgs {
  const ObstetricsAddPostnatalVisitRouteArgs({
    this.key,
    required this.labourDeliveryId,
  });

  final _i142.Key? key;

  final String labourDeliveryId;

  @override
  String toString() {
    return 'ObstetricsAddPostnatalVisitRouteArgs{key: $key, labourDeliveryId: $labourDeliveryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddPostnatalVisitRouteArgs) return false;
    return key == other.key && labourDeliveryId == other.labourDeliveryId;
  }

  @override
  int get hashCode => key.hashCode ^ labourDeliveryId.hashCode;
}

/// generated route for
/// [_i92.ObstetricsAddPregnancyScreen]
class ObstetricsAddPregnancyRoute
    extends _i141.PageRouteInfo<ObstetricsAddPregnancyRouteArgs> {
  ObstetricsAddPregnancyRoute({
    _i142.Key? key,
    String? patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPregnancyRoute.name,
         args: ObstetricsAddPregnancyRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPregnancyRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPregnancyRouteArgs>(
        orElse: () => const ObstetricsAddPregnancyRouteArgs(),
      );
      return _i92.ObstetricsAddPregnancyScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsAddPregnancyRouteArgs {
  const ObstetricsAddPregnancyRouteArgs({this.key, this.patientId});

  final _i142.Key? key;

  final String? patientId;

  @override
  String toString() {
    return 'ObstetricsAddPregnancyRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddPregnancyRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i93.ObstetricsAntenatalVisitsTab]
class ObstetricsAntenatalVisitsTab
    extends _i141.PageRouteInfo<ObstetricsAntenatalVisitsTabArgs> {
  ObstetricsAntenatalVisitsTab({
    _i142.Key? key,
    String? pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsAntenatalVisitsTab.name,
         args: ObstetricsAntenatalVisitsTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAntenatalVisitsTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAntenatalVisitsTabArgs>(
        orElse: () => const ObstetricsAntenatalVisitsTabArgs(),
      );
      return _i93.ObstetricsAntenatalVisitsTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsAntenatalVisitsTabArgs {
  const ObstetricsAntenatalVisitsTabArgs({this.key, this.pregnancyId});

  final _i142.Key? key;

  final String? pregnancyId;

  @override
  String toString() {
    return 'ObstetricsAntenatalVisitsTabArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAntenatalVisitsTabArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i94.ObstetricsDashboardScreen]
class ObstetricsDashboardRoute extends _i141.PageRouteInfo<void> {
  const ObstetricsDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(ObstetricsDashboardRoute.name, initialChildren: children);

  static const String name = 'ObstetricsDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i94.ObstetricsDashboardScreen();
    },
  );
}

/// generated route for
/// [_i95.ObstetricsEditAntenatalVisitScreen]
class ObstetricsEditAntenatalVisitRoute
    extends _i141.PageRouteInfo<ObstetricsEditAntenatalVisitRouteArgs> {
  ObstetricsEditAntenatalVisitRoute({
    _i142.Key? key,
    required String visitId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditAntenatalVisitRoute.name,
         args: ObstetricsEditAntenatalVisitRouteArgs(
           key: key,
           visitId: visitId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditAntenatalVisitRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditAntenatalVisitRouteArgs>();
      return _i95.ObstetricsEditAntenatalVisitScreen(
        key: args.key,
        visitId: args.visitId,
      );
    },
  );
}

class ObstetricsEditAntenatalVisitRouteArgs {
  const ObstetricsEditAntenatalVisitRouteArgs({
    this.key,
    required this.visitId,
  });

  final _i142.Key? key;

  final String visitId;

  @override
  String toString() {
    return 'ObstetricsEditAntenatalVisitRouteArgs{key: $key, visitId: $visitId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsEditAntenatalVisitRouteArgs) return false;
    return key == other.key && visitId == other.visitId;
  }

  @override
  int get hashCode => key.hashCode ^ visitId.hashCode;
}

/// generated route for
/// [_i96.ObstetricsEditBabyScreen]
class ObstetricsEditBabyRoute
    extends _i141.PageRouteInfo<ObstetricsEditBabyRouteArgs> {
  ObstetricsEditBabyRoute({
    _i142.Key? key,
    required String babyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditBabyRoute.name,
         args: ObstetricsEditBabyRouteArgs(key: key, babyId: babyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditBabyRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditBabyRouteArgs>();
      return _i96.ObstetricsEditBabyScreen(key: args.key, babyId: args.babyId);
    },
  );
}

class ObstetricsEditBabyRouteArgs {
  const ObstetricsEditBabyRouteArgs({this.key, required this.babyId});

  final _i142.Key? key;

  final String babyId;

  @override
  String toString() {
    return 'ObstetricsEditBabyRouteArgs{key: $key, babyId: $babyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsEditBabyRouteArgs) return false;
    return key == other.key && babyId == other.babyId;
  }

  @override
  int get hashCode => key.hashCode ^ babyId.hashCode;
}

/// generated route for
/// [_i97.ObstetricsEditGynaeProcedureScreen]
class ObstetricsEditGynaeProcedureRoute
    extends _i141.PageRouteInfo<ObstetricsEditGynaeProcedureRouteArgs> {
  ObstetricsEditGynaeProcedureRoute({
    _i142.Key? key,
    required String procedureId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditGynaeProcedureRoute.name,
         args: ObstetricsEditGynaeProcedureRouteArgs(
           key: key,
           procedureId: procedureId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditGynaeProcedureRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditGynaeProcedureRouteArgs>();
      return _i97.ObstetricsEditGynaeProcedureScreen(
        key: args.key,
        procedureId: args.procedureId,
      );
    },
  );
}

class ObstetricsEditGynaeProcedureRouteArgs {
  const ObstetricsEditGynaeProcedureRouteArgs({
    this.key,
    required this.procedureId,
  });

  final _i142.Key? key;

  final String procedureId;

  @override
  String toString() {
    return 'ObstetricsEditGynaeProcedureRouteArgs{key: $key, procedureId: $procedureId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsEditGynaeProcedureRouteArgs) return false;
    return key == other.key && procedureId == other.procedureId;
  }

  @override
  int get hashCode => key.hashCode ^ procedureId.hashCode;
}

/// generated route for
/// [_i98.ObstetricsGynaeProceduresScreen]
class ObstetricsGynaeProceduresRoute
    extends _i141.PageRouteInfo<ObstetricsGynaeProceduresRouteArgs> {
  ObstetricsGynaeProceduresRoute({
    _i142.Key? key,
    String? patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsGynaeProceduresRoute.name,
         args: ObstetricsGynaeProceduresRouteArgs(
           key: key,
           patientId: patientId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsGynaeProceduresRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsGynaeProceduresRouteArgs>(
        orElse: () => const ObstetricsGynaeProceduresRouteArgs(),
      );
      return _i98.ObstetricsGynaeProceduresScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsGynaeProceduresRouteArgs {
  const ObstetricsGynaeProceduresRouteArgs({this.key, this.patientId});

  final _i142.Key? key;

  final String? patientId;

  @override
  String toString() {
    return 'ObstetricsGynaeProceduresRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsGynaeProceduresRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i99.ObstetricsLabourDeliveryTab]
class ObstetricsLabourDeliveryTab
    extends _i141.PageRouteInfo<ObstetricsLabourDeliveryTabArgs> {
  ObstetricsLabourDeliveryTab({
    _i142.Key? key,
    String? pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsLabourDeliveryTab.name,
         args: ObstetricsLabourDeliveryTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsLabourDeliveryTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsLabourDeliveryTabArgs>(
        orElse: () => const ObstetricsLabourDeliveryTabArgs(),
      );
      return _i99.ObstetricsLabourDeliveryTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsLabourDeliveryTabArgs {
  const ObstetricsLabourDeliveryTabArgs({this.key, this.pregnancyId});

  final _i142.Key? key;

  final String? pregnancyId;

  @override
  String toString() {
    return 'ObstetricsLabourDeliveryTabArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsLabourDeliveryTabArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i100.ObstetricsLabourDeliveryViewScreen]
class ObstetricsLabourDeliveryViewRoute
    extends _i141.PageRouteInfo<ObstetricsLabourDeliveryViewRouteArgs> {
  ObstetricsLabourDeliveryViewRoute({
    _i142.Key? key,
    required String labourDeliveryId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsLabourDeliveryViewRoute.name,
         args: ObstetricsLabourDeliveryViewRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsLabourDeliveryViewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsLabourDeliveryViewRouteArgs>();
      return _i100.ObstetricsLabourDeliveryViewScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
      );
    },
  );
}

class ObstetricsLabourDeliveryViewRouteArgs {
  const ObstetricsLabourDeliveryViewRouteArgs({
    this.key,
    required this.labourDeliveryId,
  });

  final _i142.Key? key;

  final String labourDeliveryId;

  @override
  String toString() {
    return 'ObstetricsLabourDeliveryViewRouteArgs{key: $key, labourDeliveryId: $labourDeliveryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsLabourDeliveryViewRouteArgs) return false;
    return key == other.key && labourDeliveryId == other.labourDeliveryId;
  }

  @override
  int get hashCode => key.hashCode ^ labourDeliveryId.hashCode;
}

/// generated route for
/// [_i101.ObstetricsPatientSelectScreen]
class ObstetricsPatientSelectRoute extends _i141.PageRouteInfo<void> {
  const ObstetricsPatientSelectRoute({List<_i141.PageRouteInfo>? children})
    : super(ObstetricsPatientSelectRoute.name, initialChildren: children);

  static const String name = 'ObstetricsPatientSelectRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i101.ObstetricsPatientSelectScreen();
    },
  );
}

/// generated route for
/// [_i102.ObstetricsPostnatalListScreen]
class ObstetricsPostnatalListRoute
    extends _i141.PageRouteInfo<ObstetricsPostnatalListRouteArgs> {
  ObstetricsPostnatalListRoute({
    _i142.Key? key,
    String? labourDeliveryId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsPostnatalListRoute.name,
         args: ObstetricsPostnatalListRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPostnatalListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPostnatalListRouteArgs>(
        orElse: () => const ObstetricsPostnatalListRouteArgs(),
      );
      return _i102.ObstetricsPostnatalListScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
      );
    },
  );
}

class ObstetricsPostnatalListRouteArgs {
  const ObstetricsPostnatalListRouteArgs({this.key, this.labourDeliveryId});

  final _i142.Key? key;

  final String? labourDeliveryId;

  @override
  String toString() {
    return 'ObstetricsPostnatalListRouteArgs{key: $key, labourDeliveryId: $labourDeliveryId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPostnatalListRouteArgs) return false;
    return key == other.key && labourDeliveryId == other.labourDeliveryId;
  }

  @override
  int get hashCode => key.hashCode ^ labourDeliveryId.hashCode;
}

/// generated route for
/// [_i103.ObstetricsPostnatalTab]
class ObstetricsPostnatalTab
    extends _i141.PageRouteInfo<ObstetricsPostnatalTabArgs> {
  ObstetricsPostnatalTab({
    _i142.Key? key,
    String? pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsPostnatalTab.name,
         args: ObstetricsPostnatalTabArgs(key: key, pregnancyId: pregnancyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPostnatalTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPostnatalTabArgs>(
        orElse: () => const ObstetricsPostnatalTabArgs(),
      );
      return _i103.ObstetricsPostnatalTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsPostnatalTabArgs {
  const ObstetricsPostnatalTabArgs({this.key, this.pregnancyId});

  final _i142.Key? key;

  final String? pregnancyId;

  @override
  String toString() {
    return 'ObstetricsPostnatalTabArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPostnatalTabArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i104.ObstetricsPregnanciesListScreen]
class ObstetricsPregnanciesListRoute
    extends _i141.PageRouteInfo<ObstetricsPregnanciesListRouteArgs> {
  ObstetricsPregnanciesListRoute({
    _i142.Key? key,
    String? patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnanciesListRoute.name,
         args: ObstetricsPregnanciesListRouteArgs(
           key: key,
           patientId: patientId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnanciesListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnanciesListRouteArgs>(
        orElse: () => const ObstetricsPregnanciesListRouteArgs(),
      );
      return _i104.ObstetricsPregnanciesListScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsPregnanciesListRouteArgs {
  const ObstetricsPregnanciesListRouteArgs({this.key, this.patientId});

  final _i142.Key? key;

  final String? patientId;

  @override
  String toString() {
    return 'ObstetricsPregnanciesListRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPregnanciesListRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i105.ObstetricsPregnancyOverviewTab]
class ObstetricsPregnancyOverviewTab
    extends _i141.PageRouteInfo<ObstetricsPregnancyOverviewTabArgs> {
  ObstetricsPregnancyOverviewTab({
    _i142.Key? key,
    String? pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnancyOverviewTab.name,
         args: ObstetricsPregnancyOverviewTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnancyOverviewTab';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnancyOverviewTabArgs>(
        orElse: () => const ObstetricsPregnancyOverviewTabArgs(),
      );
      return _i105.ObstetricsPregnancyOverviewTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsPregnancyOverviewTabArgs {
  const ObstetricsPregnancyOverviewTabArgs({this.key, this.pregnancyId});

  final _i142.Key? key;

  final String? pregnancyId;

  @override
  String toString() {
    return 'ObstetricsPregnancyOverviewTabArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPregnancyOverviewTabArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i106.ObstetricsPregnancyViewScreen]
class ObstetricsPregnancyViewRoute
    extends _i141.PageRouteInfo<ObstetricsPregnancyViewRouteArgs> {
  ObstetricsPregnancyViewRoute({
    _i142.Key? key,
    required String pregnancyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnancyViewRoute.name,
         args: ObstetricsPregnancyViewRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnancyViewRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnancyViewRouteArgs>();
      return _i106.ObstetricsPregnancyViewScreen(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsPregnancyViewRouteArgs {
  const ObstetricsPregnancyViewRouteArgs({this.key, required this.pregnancyId});

  final _i142.Key? key;

  final String pregnancyId;

  @override
  String toString() {
    return 'ObstetricsPregnancyViewRouteArgs{key: $key, pregnancyId: $pregnancyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPregnancyViewRouteArgs) return false;
    return key == other.key && pregnancyId == other.pregnancyId;
  }

  @override
  int get hashCode => key.hashCode ^ pregnancyId.hashCode;
}

/// generated route for
/// [_i107.ObstetricsRegisterBabyScreen]
class ObstetricsRegisterBabyRoute
    extends _i141.PageRouteInfo<ObstetricsRegisterBabyRouteArgs> {
  ObstetricsRegisterBabyRoute({
    _i142.Key? key,
    required String babyId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ObstetricsRegisterBabyRoute.name,
         args: ObstetricsRegisterBabyRouteArgs(key: key, babyId: babyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsRegisterBabyRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsRegisterBabyRouteArgs>();
      return _i107.ObstetricsRegisterBabyScreen(
        key: args.key,
        babyId: args.babyId,
      );
    },
  );
}

class ObstetricsRegisterBabyRouteArgs {
  const ObstetricsRegisterBabyRouteArgs({this.key, required this.babyId});

  final _i142.Key? key;

  final String babyId;

  @override
  String toString() {
    return 'ObstetricsRegisterBabyRouteArgs{key: $key, babyId: $babyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsRegisterBabyRouteArgs) return false;
    return key == other.key && babyId == other.babyId;
  }

  @override
  int get hashCode => key.hashCode ^ babyId.hashCode;
}

/// generated route for
/// [_i108.PatientBillingScreen]
class PatientBillingRoute extends _i141.PageRouteInfo<PatientBillingRouteArgs> {
  PatientBillingRoute({
    _i142.Key? key,
    required String invoiceId,
    String patientName = '',
    List<_i141.PageRouteInfo>? children,
  }) : super(
         PatientBillingRoute.name,
         args: PatientBillingRouteArgs(
           key: key,
           invoiceId: invoiceId,
           patientName: patientName,
         ),
         initialChildren: children,
       );

  static const String name = 'PatientBillingRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientBillingRouteArgs>();
      return _i108.PatientBillingScreen(
        key: args.key,
        invoiceId: args.invoiceId,
        patientName: args.patientName,
      );
    },
  );
}

class PatientBillingRouteArgs {
  const PatientBillingRouteArgs({
    this.key,
    required this.invoiceId,
    this.patientName = '',
  });

  final _i142.Key? key;

  final String invoiceId;

  final String patientName;

  @override
  String toString() {
    return 'PatientBillingRouteArgs{key: $key, invoiceId: $invoiceId, patientName: $patientName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PatientBillingRouteArgs) return false;
    return key == other.key &&
        invoiceId == other.invoiceId &&
        patientName == other.patientName;
  }

  @override
  int get hashCode => key.hashCode ^ invoiceId.hashCode ^ patientName.hashCode;
}

/// generated route for
/// [_i109.PatientFormScreen]
class PatientFormRoute extends _i141.PageRouteInfo<PatientFormRouteArgs> {
  PatientFormRoute({
    _i142.Key? key,
    _i147.Patient? patient,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         PatientFormRoute.name,
         args: PatientFormRouteArgs(key: key, patient: patient),
         initialChildren: children,
       );

  static const String name = 'PatientFormRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientFormRouteArgs>(
        orElse: () => const PatientFormRouteArgs(),
      );
      return _i109.PatientFormScreen(key: args.key, patient: args.patient);
    },
  );
}

class PatientFormRouteArgs {
  const PatientFormRouteArgs({this.key, this.patient});

  final _i142.Key? key;

  final _i147.Patient? patient;

  @override
  String toString() {
    return 'PatientFormRouteArgs{key: $key, patient: $patient}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PatientFormRouteArgs) return false;
    return key == other.key && patient == other.patient;
  }

  @override
  int get hashCode => key.hashCode ^ patient.hashCode;
}

/// generated route for
/// [_i110.PatientListScreen]
class PatientListRoute extends _i141.PageRouteInfo<void> {
  const PatientListRoute({List<_i141.PageRouteInfo>? children})
    : super(PatientListRoute.name, initialChildren: children);

  static const String name = 'PatientListRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i110.PatientListScreen();
    },
  );
}

/// generated route for
/// [_i111.PendingBillsScreen]
class PendingBillsRoute extends _i141.PageRouteInfo<void> {
  const PendingBillsRoute({List<_i141.PageRouteInfo>? children})
    : super(PendingBillsRoute.name, initialChildren: children);

  static const String name = 'PendingBillsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i111.PendingBillsScreen();
    },
  );
}

/// generated route for
/// [_i112.PendingTransactionsScreen]
class PendingTransactionsRoute extends _i141.PageRouteInfo<void> {
  const PendingTransactionsRoute({List<_i141.PageRouteInfo>? children})
    : super(PendingTransactionsRoute.name, initialChildren: children);

  static const String name = 'PendingTransactionsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i112.PendingTransactionsScreen();
    },
  );
}

/// generated route for
/// [_i113.PharmacyDashboardScreen]
class PharmacyDashboardRoute extends _i141.PageRouteInfo<void> {
  const PharmacyDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(PharmacyDashboardRoute.name, initialChildren: children);

  static const String name = 'PharmacyDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i113.PharmacyDashboardScreen();
    },
  );
}

/// generated route for
/// [_i114.PharmacyLocationScreen]
class PharmacyLocationRoute extends _i141.PageRouteInfo<void> {
  const PharmacyLocationRoute({List<_i141.PageRouteInfo>? children})
    : super(PharmacyLocationRoute.name, initialChildren: children);

  static const String name = 'PharmacyLocationRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i114.PharmacyLocationScreen();
    },
  );
}

/// generated route for
/// [_i115.PharmacyPOSScreen]
class PharmacyPOSRoute extends _i141.PageRouteInfo<void> {
  const PharmacyPOSRoute({List<_i141.PageRouteInfo>? children})
    : super(PharmacyPOSRoute.name, initialChildren: children);

  static const String name = 'PharmacyPOSRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i115.PharmacyPOSScreen();
    },
  );
}

/// generated route for
/// [_i116.RadiologyCreateRequestScreen]
class RadiologyCreateRequestRoute
    extends _i141.PageRouteInfo<RadiologyCreateRequestRouteArgs> {
  RadiologyCreateRequestRoute({
    _i142.Key? key,
    String? patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         RadiologyCreateRequestRoute.name,
         args: RadiologyCreateRequestRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'RadiologyCreateRequestRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyCreateRequestRouteArgs>(
        orElse: () => const RadiologyCreateRequestRouteArgs(),
      );
      return _i116.RadiologyCreateRequestScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class RadiologyCreateRequestRouteArgs {
  const RadiologyCreateRequestRouteArgs({this.key, this.patientId});

  final _i142.Key? key;

  final String? patientId;

  @override
  String toString() {
    return 'RadiologyCreateRequestRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RadiologyCreateRequestRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i117.RadiologyDashboardScreen]
class RadiologyDashboardRoute extends _i141.PageRouteInfo<void> {
  const RadiologyDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(RadiologyDashboardRoute.name, initialChildren: children);

  static const String name = 'RadiologyDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i117.RadiologyDashboardScreen();
    },
  );
}

/// generated route for
/// [_i118.RadiologyPatientHistoryScreen]
class RadiologyPatientHistoryRoute
    extends _i141.PageRouteInfo<RadiologyPatientHistoryRouteArgs> {
  RadiologyPatientHistoryRoute({
    _i142.Key? key,
    required String patientId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         RadiologyPatientHistoryRoute.name,
         args: RadiologyPatientHistoryRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'RadiologyPatientHistoryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyPatientHistoryRouteArgs>();
      return _i118.RadiologyPatientHistoryScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class RadiologyPatientHistoryRouteArgs {
  const RadiologyPatientHistoryRouteArgs({this.key, required this.patientId});

  final _i142.Key? key;

  final String patientId;

  @override
  String toString() {
    return 'RadiologyPatientHistoryRouteArgs{key: $key, patientId: $patientId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RadiologyPatientHistoryRouteArgs) return false;
    return key == other.key && patientId == other.patientId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode;
}

/// generated route for
/// [_i119.RadiologyRequestDetailScreen]
class RadiologyRequestDetailRoute
    extends _i141.PageRouteInfo<RadiologyRequestDetailRouteArgs> {
  RadiologyRequestDetailRoute({
    _i142.Key? key,
    required String requestId,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         RadiologyRequestDetailRoute.name,
         args: RadiologyRequestDetailRouteArgs(key: key, requestId: requestId),
         initialChildren: children,
       );

  static const String name = 'RadiologyRequestDetailRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyRequestDetailRouteArgs>();
      return _i119.RadiologyRequestDetailScreen(
        key: args.key,
        requestId: args.requestId,
      );
    },
  );
}

class RadiologyRequestDetailRouteArgs {
  const RadiologyRequestDetailRouteArgs({this.key, required this.requestId});

  final _i142.Key? key;

  final String requestId;

  @override
  String toString() {
    return 'RadiologyRequestDetailRouteArgs{key: $key, requestId: $requestId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RadiologyRequestDetailRouteArgs) return false;
    return key == other.key && requestId == other.requestId;
  }

  @override
  int get hashCode => key.hashCode ^ requestId.hashCode;
}

/// generated route for
/// [_i120.RadiologyWorklistScreen]
class RadiologyWorklistRoute extends _i141.PageRouteInfo<void> {
  const RadiologyWorklistRoute({List<_i141.PageRouteInfo>? children})
    : super(RadiologyWorklistRoute.name, initialChildren: children);

  static const String name = 'RadiologyWorklistRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i120.RadiologyWorklistScreen();
    },
  );
}

/// generated route for
/// [_i121.RegisterScreen]
class RegisterRoute extends _i141.PageRouteInfo<void> {
  const RegisterRoute({List<_i141.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i121.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i122.RenderServiceScreen]
class RenderServiceRoute extends _i141.PageRouteInfo<void> {
  const RenderServiceRoute({List<_i141.PageRouteInfo>? children})
    : super(RenderServiceRoute.name, initialChildren: children);

  static const String name = 'RenderServiceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i122.RenderServiceScreen();
    },
  );
}

/// generated route for
/// [_i123.ResetPasswordScreen]
class ResetPasswordRoute extends _i141.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i142.Key? key,
    String? token,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, token: token),
         rawQueryParams: {'token': token},
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ResetPasswordRouteArgs>(
        orElse: () =>
            ResetPasswordRouteArgs(token: queryParams.optString('token')),
      );
      return _i123.ResetPasswordScreen(key: args.key, token: args.token);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, this.token});

  final _i142.Key? key;

  final String? token;

  @override
  String toString() {
    return 'ResetPasswordRouteArgs{key: $key, token: $token}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResetPasswordRouteArgs) return false;
    return key == other.key && token == other.token;
  }

  @override
  int get hashCode => key.hashCode ^ token.hashCode;
}

/// generated route for
/// [_i124.StockTransferScreen]
class StockTransferRoute extends _i141.PageRouteInfo<void> {
  const StockTransferRoute({List<_i141.PageRouteInfo>? children})
    : super(StockTransferRoute.name, initialChildren: children);

  static const String name = 'StockTransferRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i124.StockTransferScreen();
    },
  );
}

/// generated route for
/// [_i125.StoreAnalyticsScreen]
class StoreAnalyticsRoute extends _i141.PageRouteInfo<void> {
  const StoreAnalyticsRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreAnalyticsRoute.name, initialChildren: children);

  static const String name = 'StoreAnalyticsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i125.StoreAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i126.StoreCategoriesScreen]
class StoreCategoriesRoute extends _i141.PageRouteInfo<void> {
  const StoreCategoriesRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreCategoriesRoute.name, initialChildren: children);

  static const String name = 'StoreCategoriesRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i126.StoreCategoriesScreen();
    },
  );
}

/// generated route for
/// [_i127.StoreDashboardScreen]
class StoreDashboardRoute extends _i141.PageRouteInfo<void> {
  const StoreDashboardRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreDashboardRoute.name, initialChildren: children);

  static const String name = 'StoreDashboardRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i127.StoreDashboardScreen();
    },
  );
}

/// generated route for
/// [_i128.StoreItemsScreen]
class StoreItemsRoute extends _i141.PageRouteInfo<void> {
  const StoreItemsRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreItemsRoute.name, initialChildren: children);

  static const String name = 'StoreItemsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i128.StoreItemsScreen();
    },
  );
}

/// generated route for
/// [_i129.StoreLocationsScreen]
class StoreLocationsRoute extends _i141.PageRouteInfo<void> {
  const StoreLocationsRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreLocationsRoute.name, initialChildren: children);

  static const String name = 'StoreLocationsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i129.StoreLocationsScreen();
    },
  );
}

/// generated route for
/// [_i130.StoreMovementsScreen]
class StoreMovementsRoute extends _i141.PageRouteInfo<void> {
  const StoreMovementsRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreMovementsRoute.name, initialChildren: children);

  static const String name = 'StoreMovementsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i130.StoreMovementsScreen();
    },
  );
}

/// generated route for
/// [_i131.StoreStockScreen]
class StoreStockRoute extends _i141.PageRouteInfo<void> {
  const StoreStockRoute({List<_i141.PageRouteInfo>? children})
    : super(StoreStockRoute.name, initialChildren: children);

  static const String name = 'StoreStockRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i131.StoreStockScreen();
    },
  );
}

/// generated route for
/// [_i132.SupplyHistoryScreen]
class SupplyHistoryRoute extends _i141.PageRouteInfo<void> {
  const SupplyHistoryRoute({List<_i141.PageRouteInfo>? children})
    : super(SupplyHistoryRoute.name, initialChildren: children);

  static const String name = 'SupplyHistoryRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i132.SupplyHistoryScreen();
    },
  );
}

/// generated route for
/// [_i133.SystemSetupScreen]
class SystemSetupRoute extends _i141.PageRouteInfo<void> {
  const SystemSetupRoute({List<_i141.PageRouteInfo>? children})
    : super(SystemSetupRoute.name, initialChildren: children);

  static const String name = 'SystemSetupRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i133.SystemSetupScreen();
    },
  );
}

/// generated route for
/// [_i134.TodayPatientsScreen]
class TodayPatientsRoute extends _i141.PageRouteInfo<void> {
  const TodayPatientsRoute({List<_i141.PageRouteInfo>? children})
    : super(TodayPatientsRoute.name, initialChildren: children);

  static const String name = 'TodayPatientsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i134.TodayPatientsScreen();
    },
  );
}

/// generated route for
/// [_i135.TransactionsScreen]
class TransactionsRoute extends _i141.PageRouteInfo<void> {
  const TransactionsRoute({List<_i141.PageRouteInfo>? children})
    : super(TransactionsRoute.name, initialChildren: children);

  static const String name = 'TransactionsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i135.TransactionsScreen();
    },
  );
}

/// generated route for
/// [_i136.ViewServiceScreen]
class ViewServiceRoute extends _i141.PageRouteInfo<void> {
  const ViewServiceRoute({List<_i141.PageRouteInfo>? children})
    : super(ViewServiceRoute.name, initialChildren: children);

  static const String name = 'ViewServiceRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i136.ViewServiceScreen();
    },
  );
}

/// generated route for
/// [_i137.WaitingPatientScreen]
class WaitingPatientRoute extends _i141.PageRouteInfo<WaitingPatientRouteArgs> {
  WaitingPatientRoute({
    _i142.Key? key,
    _i148.IPharmacyQueueService? queueService,
    List<_i141.PageRouteInfo>? children,
  }) : super(
         WaitingPatientRoute.name,
         args: WaitingPatientRouteArgs(key: key, queueService: queueService),
         initialChildren: children,
       );

  static const String name = 'WaitingPatientRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WaitingPatientRouteArgs>(
        orElse: () => const WaitingPatientRouteArgs(),
      );
      return _i137.WaitingPatientScreen(
        key: args.key,
        queueService: args.queueService,
      );
    },
  );
}

class WaitingPatientRouteArgs {
  const WaitingPatientRouteArgs({this.key, this.queueService});

  final _i142.Key? key;

  final _i148.IPharmacyQueueService? queueService;

  @override
  String toString() {
    return 'WaitingPatientRouteArgs{key: $key, queueService: $queueService}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WaitingPatientRouteArgs) return false;
    return key == other.key && queueService == other.queueService;
  }

  @override
  int get hashCode => key.hashCode ^ queueService.hashCode;
}

/// generated route for
/// [_i138.WaitingPatientsScreen]
class WaitingPatientsRoute extends _i141.PageRouteInfo<void> {
  const WaitingPatientsRoute({List<_i141.PageRouteInfo>? children})
    : super(WaitingPatientsRoute.name, initialChildren: children);

  static const String name = 'WaitingPatientsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i138.WaitingPatientsScreen();
    },
  );
}

/// generated route for
/// [_i139.WardManagementScreen]
class WardManagementRoute extends _i141.PageRouteInfo<void> {
  const WardManagementRoute({List<_i141.PageRouteInfo>? children})
    : super(WardManagementRoute.name, initialChildren: children);

  static const String name = 'WardManagementRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i139.WardManagementScreen();
    },
  );
}

/// generated route for
/// [_i140.WardRoundsScreen]
class WardRoundsRoute extends _i141.PageRouteInfo<void> {
  const WardRoundsRoute({List<_i141.PageRouteInfo>? children})
    : super(WardRoundsRoute.name, initialChildren: children);

  static const String name = 'WardRoundsRoute';

  static _i141.PageInfo page = _i141.PageInfo(
    name,
    builder: (data) {
      return const _i140.WardRoundsScreen();
    },
  );
}
