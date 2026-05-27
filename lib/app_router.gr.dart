// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i179;
import 'package:collection/collection.dart' as _i183;
import 'package:flutter/material.dart' as _i180;
import 'package:helty/src/billings/dashboard.dart' as _i10;
import 'package:helty/src/billings/inpatient.bills.dart' as _i133;
import 'package:helty/src/billings/inpatient_bills_list_screen.dart' as _i83;
import 'package:helty/src/billings/pending.bills.dart' as _i138;
import 'package:helty/src/chat/ui/staff_chat_screen.dart' as _i153;
import 'package:helty/src/chat/ui/staff_chat_thread_screen.dart' as _i154;
import 'package:helty/src/cmac/ui/cmac_clinical_screen.dart' as _i23;
import 'package:helty/src/cmac/ui/cmac_insights_screen.dart' as _i24;
import 'package:helty/src/cmac/ui/cmac_laboratory_screen.dart' as _i25;
import 'package:helty/src/cmac/ui/cmac_operations_screen.dart' as _i26;
import 'package:helty/src/cmac/ui/cmac_overview_screen.dart' as _i27;
import 'package:helty/src/cmac/ui/cmac_patient_activity_screen.dart' as _i28;
import 'package:helty/src/cmac/ui/cmac_pharmacy_screen.dart' as _i29;
import 'package:helty/src/cmac/ui/cmac_quality_screen.dart' as _i33;
import 'package:helty/src/cmac/ui/cmac_staff_screen.dart' as _i34;
import 'package:helty/src/cmac/ui/quality_safety/cmac_quality_detail_screen.dart'
    as _i31;
import 'package:helty/src/cmac/ui/quality_safety/cmac_quality_list_screen.dart'
    as _i30;
import 'package:helty/src/cmac/ui/quality_safety/cmac_quality_safety_hub_screen.dart'
    as _i32;
import 'package:helty/src/cmd/alerts_incidents_screen.dart' as _i11;
import 'package:helty/src/cmd/audit_compliance_screen.dart' as _i12;
import 'package:helty/src/cmd/beds_facilities_screen.dart' as _i13;
import 'package:helty/src/cmd/communication_center_screen.dart' as _i14;
import 'package:helty/src/cmd/consulting_rooms_screen.dart' as _i45;
import 'package:helty/src/cmd/dashboard.dart' as _i15;
import 'package:helty/src/cmd/financial_command_screen.dart' as _i16;
import 'package:helty/src/cmd/hospital_overview_screen.dart' as _i17;
import 'package:helty/src/cmd/lab_monitoring_screen.dart' as _i18;
import 'package:helty/src/cmd/patient_experience_screen.dart' as _i19;
import 'package:helty/src/cmd/reports_analytics_screen.dart' as _i20;
import 'package:helty/src/cmd/staff_oversight_screen.dart' as _i21;
import 'package:helty/src/cmd/system_control_screen.dart' as _i22;
import 'package:helty/src/discount_policies/ui/discount_policy_management_screen.dart'
    as _i48;
import 'package:helty/src/doctor/completed/doctor_completed_encounter_view_screen.dart'
    as _i51;
import 'package:helty/src/doctor/completed/doctor_completed_encounters_screen.dart'
    as _i52;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_appointments_tab.dart'
    as _i35;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_diagnosis_tab.dart'
    as _i36;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_examination_tab.dart'
    as _i37;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_follow_up_tab.dart'
    as _i38;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_history_tab.dart'
    as _i39;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_imaging_tab.dart'
    as _i40;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_labs_tab.dart'
    as _i41;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_notes_tab.dart'
    as _i42;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_prescriptions_tab.dart'
    as _i43;
import 'package:helty/src/doctor/completed/tabs/completed_encounter_summary_tab.dart'
    as _i44;
import 'package:helty/src/doctor/dashboard/doctor_dashboard_screen.dart'
    as _i53;
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart'
    as _i64;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_admission_tab.dart'
    as _i54;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_diagnosis_tab.dart'
    as _i55;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_examination_tab.dart'
    as _i56;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_follow_up_tab.dart'
    as _i57;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_history_tab.dart'
    as _i58;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_imaging_tab.dart'
    as _i59;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_investigations_tab.dart'
    as _i60;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_notes_tab.dart'
    as _i61;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_prescription_tab.dart'
    as _i62;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_procedures_tab.dart'
    as _i63;
import 'package:helty/src/doctor/outpatient/doctor_outpatient_list_screen.dart'
    as _i65;
import 'package:helty/src/doctor/pending/doctor_pending_imaging_screen.dart'
    as _i66;
import 'package:helty/src/doctor/pending/doctor_pending_labs_screen.dart'
    as _i67;
import 'package:helty/src/doctor/pending/doctor_pending_prescriptions_screen.dart'
    as _i68;
import 'package:helty/src/doctor/profile/doctor_profile_screen.dart' as _i69;
import 'package:helty/src/doctor/templates/doctor_templates_screen.dart'
    as _i70;
import 'package:helty/src/doctor/walk_in/doctor_walk_in_queue_screen.dart'
    as _i71;
import 'package:helty/src/doctor/ward_rounds/ward_rounds_screen.dart' as _i178;
import 'package:helty/src/enlist_services/enlist.paitient.dart' as _i72;
import 'package:helty/src/frontdesk/dashboard.dart' as _i75;
import 'package:helty/src/help/ui/help_center_screen.dart' as _i76;
import 'package:helty/src/help/ui/support_ticket_detail_screen.dart' as _i170;
import 'package:helty/src/hmo/ui/hmo_detail_screen.dart' as _i77;
import 'package:helty/src/hmo/ui/hmo_form_screen.dart' as _i78;
import 'package:helty/src/hmo/ui/hmo_list_screen.dart' as _i79;
import 'package:helty/src/hmo/ui/hmo_service_pricing_screen.dart' as _i80;
import 'package:helty/src/hospital_service/service_screen.dart' as _i171;
import 'package:helty/src/hospital_service/wards/ward.screen.dart' as _i177;
import 'package:helty/src/lab/ui/lab_config_screen.dart' as _i99;
import 'package:helty/src/lab/ui/lab_create_order_screen.dart' as _i100;
import 'package:helty/src/lab/ui/lab_dashboard_screen.dart' as _i101;
import 'package:helty/src/lab/ui/lab_order_detail_screen.dart' as _i102;
import 'package:helty/src/lab/ui/lab_result_entry_screen.dart' as _i103;
import 'package:helty/src/models/patient_vitals_model.dart' as _i184;
import 'package:helty/src/nurses/dashboard.dart' as _i110;
import 'package:helty/src/nurses/inpatients/inpatient_patient_view_screen.dart'
    as _i94;
import 'package:helty/src/nurses/inpatients/inpatients_list_screen.dart'
    as _i98;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_alerts_tab.dart'
    as _i82;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_care_plan_tab.dart'
    as _i84;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_handover_tab.dart'
    as _i85;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_imaging_results_tab.dart'
    as _i88;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_io_tab.dart' as _i86;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_iv_tab.dart' as _i87;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_lab_results_tab.dart'
    as _i89;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_medications_tab.dart'
    as _i90;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_monitoring_tab.dart'
    as _i91;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_notes_tab.dart'
    as _i92;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_overview_tab.dart'
    as _i93;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_procedures_tab.dart'
    as _i95;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_vitals_tab.dart'
    as _i96;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_ward_round_tab.dart'
    as _i97;
import 'package:helty/src/nurses/ui/nurse_consumable_usage_screen.dart'
    as _i109;
import 'package:helty/src/nurses/waiting_patients.dart' as _i176;
import 'package:helty/src/obstetrics/ui/forms/add_antenatal_visit_screen.dart'
    as _i111;
import 'package:helty/src/obstetrics/ui/forms/add_baby_screen.dart' as _i112;
import 'package:helty/src/obstetrics/ui/forms/add_gynae_procedure_screen.dart'
    as _i113;
import 'package:helty/src/obstetrics/ui/forms/add_labour_delivery_screen.dart'
    as _i114;
import 'package:helty/src/obstetrics/ui/forms/add_partogram_entry_screen.dart'
    as _i115;
import 'package:helty/src/obstetrics/ui/forms/add_postnatal_visit_screen.dart'
    as _i116;
import 'package:helty/src/obstetrics/ui/forms/add_pregnancy_screen.dart'
    as _i117;
import 'package:helty/src/obstetrics/ui/forms/edit_antenatal_visit_screen.dart'
    as _i120;
import 'package:helty/src/obstetrics/ui/forms/edit_baby_screen.dart' as _i121;
import 'package:helty/src/obstetrics/ui/forms/edit_gynae_procedure_screen.dart'
    as _i122;
import 'package:helty/src/obstetrics/ui/forms/register_baby_screen.dart'
    as _i132;
import 'package:helty/src/obstetrics/ui/gynae_procedures_screen.dart' as _i123;
import 'package:helty/src/obstetrics/ui/labour_delivery_view_screen.dart'
    as _i125;
import 'package:helty/src/obstetrics/ui/obstetrics_dashboard_screen.dart'
    as _i119;
import 'package:helty/src/obstetrics/ui/obstetrics_patient_select_screen.dart'
    as _i126;
import 'package:helty/src/obstetrics/ui/postnatal_list_screen.dart' as _i127;
import 'package:helty/src/obstetrics/ui/pregnancies_list_screen.dart' as _i129;
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart' as _i131;
import 'package:helty/src/obstetrics/ui/tabs/antenatal_visits_tab.dart'
    as _i118;
import 'package:helty/src/obstetrics/ui/tabs/labour_delivery_tab.dart' as _i124;
import 'package:helty/src/obstetrics/ui/tabs/postnatal_tab.dart' as _i128;
import 'package:helty/src/obstetrics/ui/tabs/pregnancy_overview_tab.dart'
    as _i130;
import 'package:helty/src/paitients/patient_form_screen.dart' as _i136;
import 'package:helty/src/paitients/patient_list_screen.dart' as _i137;
import 'package:helty/src/paitients/patient_model.dart' as _i185;
import 'package:helty/src/paitients/view_waiting_patient.dart' as _i107;
import 'package:helty/src/patient_chart/ui/patient_chart_screen.dart' as _i134;
import 'package:helty/src/patient_chart/ui/patient_chart_select_screen.dart'
    as _i135;
import 'package:helty/src/pharmacy/models/pharmacy_model.dart' as _i181;
import 'package:helty/src/pharmacy/services/pharmacy_queue_service.dart'
    as _i186;
import 'package:helty/src/pharmacy/services/pharmacy_service.dart' as _i182;
import 'package:helty/src/pharmacy/ui/add.batches.dart' as _i1;
import 'package:helty/src/pharmacy/ui/add_drug_screen.dart' as _i4;
import 'package:helty/src/pharmacy/ui/add_supplier_screen.dart' as _i6;
import 'package:helty/src/pharmacy/ui/batches_preview_ward_pricing_screen.dart'
    as _i9;
import 'package:helty/src/pharmacy/ui/create_requisition.dart' as _i46;
import 'package:helty/src/pharmacy/ui/dispense_history_screen.dart' as _i49;
import 'package:helty/src/pharmacy/ui/dispense_screen.dart' as _i50;
import 'package:helty/src/pharmacy/ui/dispensory.screen.dart' as _i142;
import 'package:helty/src/pharmacy/ui/location.screen.dart' as _i141;
import 'package:helty/src/pharmacy/ui/medicine_inventory.dart' as _i105;
import 'package:helty/src/pharmacy/ui/pharmacy_dashboard_screen.dart' as _i140;
import 'package:helty/src/pharmacy/ui/stock_transfer.dart' as _i155;
import 'package:helty/src/pharmacy/ui/suppliy.history.screen.dart' as _i169;
import 'package:helty/src/pharmacy/ui/waiting.patient.dart' as _i175;
import 'package:helty/src/radiology/ui/radiology_create_request_screen.dart'
    as _i143;
import 'package:helty/src/radiology/ui/radiology_dashboard_screen.dart'
    as _i144;
import 'package:helty/src/radiology/ui/radiology_patient_history_screen.dart'
    as _i145;
import 'package:helty/src/radiology/ui/radiology_request_detail_screen.dart'
    as _i146;
import 'package:helty/src/radiology/ui/radiology_worklist_screen.dart' as _i147;
import 'package:helty/src/receivables/ui/receivables_analytics_screen.dart'
    as _i148;
import 'package:helty/src/receivables/ui/receivables_home_screen.dart' as _i149;
import 'package:helty/src/store/ui/store_analytics_screen.dart' as _i156;
import 'package:helty/src/store/ui/store_categories_screen.dart' as _i157;
import 'package:helty/src/store/ui/store_consumable_analytics_screen.dart'
    as _i158;
import 'package:helty/src/store/ui/store_consumable_detail_screen.dart'
    as _i159;
import 'package:helty/src/store/ui/store_consumables_catalog_screen.dart'
    as _i160;
import 'package:helty/src/store/ui/store_dashboard_screen.dart' as _i161;
import 'package:helty/src/store/ui/store_items_screen.dart' as _i162;
import 'package:helty/src/store/ui/store_locations_screen.dart' as _i163;
import 'package:helty/src/store/ui/store_movements_screen.dart' as _i164;
import 'package:helty/src/store/ui/store_stock_screen.dart' as _i165;
import 'package:helty/src/transaction/transactions.screen.dart' as _i173;
import 'package:helty/src/ui/appointments/appointment_list_screen.dart' as _i7;
import 'package:helty/src/ui/appointments/create_appointment.dart' as _i106;
import 'package:helty/src/ui/auth/forgot_password_screen.dart' as _i74;
import 'package:helty/src/ui/auth/login_screen.dart' as _i104;
import 'package:helty/src/ui/auth/register_screen.dart' as _i150;
import 'package:helty/src/ui/auth/reset_password_screen.dart' as _i152;
import 'package:helty/src/ui/dashboard/dashboard_screen.dart' as _i47;
import 'package:helty/src/ui/home/home_screen.dart' as _i81;
import 'package:helty/src/ui/patients/today_patients.dart' as _i172;
import 'package:helty/src/ui/patinets_services/add_category_screen.dart' as _i2;
import 'package:helty/src/ui/patinets_services/add_department_screen.dart'
    as _i3;
import 'package:helty/src/ui/patinets_services/add_service_screen.dart' as _i5;
import 'package:helty/src/ui/patinets_services/enlist_service_screen.dart'
    as _i73;
import 'package:helty/src/ui/patinets_services/render_services.dart' as _i151;
import 'package:helty/src/ui/patinets_services/view_services.dart' as _i174;
import 'package:helty/src/ui/super_admin/super_admin_hub_screen.dart' as _i166;
import 'package:helty/src/ui/super_admin/super_admin_staff_detail_screen.dart'
    as _i167;
import 'package:helty/src/ui/super_admin/super_admin_staff_list_screen.dart'
    as _i168;
import 'package:helty/src/ui/system_setup/bank_management_screen.dart' as _i8;
import 'package:helty/src/ui/transactions/pending_transactions.dart' as _i139;
import 'package:helty/src/widgets/not_avaliable.dart' as _i108;

/// generated route for
/// [_i1.AddBatchScreen]
class AddBatchRoute extends _i179.PageRouteInfo<void> {
  const AddBatchRoute({List<_i179.PageRouteInfo>? children})
    : super(AddBatchRoute.name, initialChildren: children);

  static const String name = 'AddBatchRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddBatchScreen();
    },
  );
}

/// generated route for
/// [_i2.AddCategoryScreen]
class AddCategoryRoute extends _i179.PageRouteInfo<void> {
  const AddCategoryRoute({List<_i179.PageRouteInfo>? children})
    : super(AddCategoryRoute.name, initialChildren: children);

  static const String name = 'AddCategoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i2.AddCategoryScreen();
    },
  );
}

/// generated route for
/// [_i3.AddDepartmentScreen]
class AddDepartmentRoute extends _i179.PageRouteInfo<void> {
  const AddDepartmentRoute({List<_i179.PageRouteInfo>? children})
    : super(AddDepartmentRoute.name, initialChildren: children);

  static const String name = 'AddDepartmentRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddDepartmentScreen();
    },
  );
}

/// generated route for
/// [_i4.AddDrugScreen]
class AddDrugRoute extends _i179.PageRouteInfo<AddDrugRouteArgs> {
  AddDrugRoute({
    _i180.Key? key,
    _i181.Drug? existingDrug,
    _i182.PharmacyApiService? service,
    _i180.VoidCallback? onSaved,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
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

  final _i180.Key? key;

  final _i181.Drug? existingDrug;

  final _i182.PharmacyApiService? service;

  final _i180.VoidCallback? onSaved;

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
class AddServiceRoute extends _i179.PageRouteInfo<void> {
  const AddServiceRoute({List<_i179.PageRouteInfo>? children})
    : super(AddServiceRoute.name, initialChildren: children);

  static const String name = 'AddServiceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i5.AddServiceScreen();
    },
  );
}

/// generated route for
/// [_i6.AddSupplierScreen]
class AddSupplierRoute extends _i179.PageRouteInfo<void> {
  const AddSupplierRoute({List<_i179.PageRouteInfo>? children})
    : super(AddSupplierRoute.name, initialChildren: children);

  static const String name = 'AddSupplierRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i6.AddSupplierScreen();
    },
  );
}

/// generated route for
/// [_i7.AppointmentListScreen]
class AppointmentListRoute extends _i179.PageRouteInfo<void> {
  const AppointmentListRoute({List<_i179.PageRouteInfo>? children})
    : super(AppointmentListRoute.name, initialChildren: children);

  static const String name = 'AppointmentListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i7.AppointmentListScreen();
    },
  );
}

/// generated route for
/// [_i8.BankManagementScreen]
class BankManagementRoute extends _i179.PageRouteInfo<void> {
  const BankManagementRoute({List<_i179.PageRouteInfo>? children})
    : super(BankManagementRoute.name, initialChildren: children);

  static const String name = 'BankManagementRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i8.BankManagementScreen();
    },
  );
}

/// generated route for
/// [_i9.BatchesPreviewWardPricingScreen]
class BatchesPreviewWardPricingRoute
    extends _i179.PageRouteInfo<BatchesPreviewWardPricingRouteArgs> {
  BatchesPreviewWardPricingRoute({
    _i180.Key? key,
    required String id,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         BatchesPreviewWardPricingRoute.name,
         args: BatchesPreviewWardPricingRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'BatchesPreviewWardPricingRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<BatchesPreviewWardPricingRouteArgs>(
        orElse: () =>
            BatchesPreviewWardPricingRouteArgs(id: pathParams.getString('id')),
      );
      return _i9.BatchesPreviewWardPricingScreen(key: args.key, id: args.id);
    },
  );
}

class BatchesPreviewWardPricingRouteArgs {
  const BatchesPreviewWardPricingRouteArgs({this.key, required this.id});

  final _i180.Key? key;

  final String id;

  @override
  String toString() {
    return 'BatchesPreviewWardPricingRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BatchesPreviewWardPricingRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [_i10.BillingDashboardScreen]
class BillingDashboardRoute extends _i179.PageRouteInfo<void> {
  const BillingDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(BillingDashboardRoute.name, initialChildren: children);

  static const String name = 'BillingDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i10.BillingDashboardScreen();
    },
  );
}

/// generated route for
/// [_i11.CMDAlertsIncidentsScreen]
class CMDAlertsIncidentsRoute extends _i179.PageRouteInfo<void> {
  const CMDAlertsIncidentsRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDAlertsIncidentsRoute.name, initialChildren: children);

  static const String name = 'CMDAlertsIncidentsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i11.CMDAlertsIncidentsScreen();
    },
  );
}

/// generated route for
/// [_i12.CMDAuditComplianceScreen]
class CMDAuditComplianceRoute extends _i179.PageRouteInfo<void> {
  const CMDAuditComplianceRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDAuditComplianceRoute.name, initialChildren: children);

  static const String name = 'CMDAuditComplianceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i12.CMDAuditComplianceScreen();
    },
  );
}

/// generated route for
/// [_i13.CMDBedsFacilitiesScreen]
class CMDBedsFacilitiesRoute extends _i179.PageRouteInfo<void> {
  const CMDBedsFacilitiesRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDBedsFacilitiesRoute.name, initialChildren: children);

  static const String name = 'CMDBedsFacilitiesRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i13.CMDBedsFacilitiesScreen();
    },
  );
}

/// generated route for
/// [_i14.CMDCommunicationCenterScreen]
class CMDCommunicationCenterRoute extends _i179.PageRouteInfo<void> {
  const CMDCommunicationCenterRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDCommunicationCenterRoute.name, initialChildren: children);

  static const String name = 'CMDCommunicationCenterRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i14.CMDCommunicationCenterScreen();
    },
  );
}

/// generated route for
/// [_i15.CMDDashboardScreen]
class CMDDashboardRoute extends _i179.PageRouteInfo<void> {
  const CMDDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDDashboardRoute.name, initialChildren: children);

  static const String name = 'CMDDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i15.CMDDashboardScreen();
    },
  );
}

/// generated route for
/// [_i16.CMDFinancialCommandScreen]
class CMDFinancialCommandRoute extends _i179.PageRouteInfo<void> {
  const CMDFinancialCommandRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDFinancialCommandRoute.name, initialChildren: children);

  static const String name = 'CMDFinancialCommandRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i16.CMDFinancialCommandScreen();
    },
  );
}

/// generated route for
/// [_i17.CMDHospitalOverviewScreen]
class CMDHospitalOverviewRoute extends _i179.PageRouteInfo<void> {
  const CMDHospitalOverviewRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDHospitalOverviewRoute.name, initialChildren: children);

  static const String name = 'CMDHospitalOverviewRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i17.CMDHospitalOverviewScreen();
    },
  );
}

/// generated route for
/// [_i18.CMDLabMonitoringScreen]
class CMDLabMonitoringRoute extends _i179.PageRouteInfo<void> {
  const CMDLabMonitoringRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDLabMonitoringRoute.name, initialChildren: children);

  static const String name = 'CMDLabMonitoringRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i18.CMDLabMonitoringScreen();
    },
  );
}

/// generated route for
/// [_i19.CMDPatientExperienceScreen]
class CMDPatientExperienceRoute extends _i179.PageRouteInfo<void> {
  const CMDPatientExperienceRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDPatientExperienceRoute.name, initialChildren: children);

  static const String name = 'CMDPatientExperienceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i19.CMDPatientExperienceScreen();
    },
  );
}

/// generated route for
/// [_i20.CMDReportsAnalyticsScreen]
class CMDReportsAnalyticsRoute extends _i179.PageRouteInfo<void> {
  const CMDReportsAnalyticsRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDReportsAnalyticsRoute.name, initialChildren: children);

  static const String name = 'CMDReportsAnalyticsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i20.CMDReportsAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i21.CMDStaffOversightScreen]
class CMDStaffOversightRoute extends _i179.PageRouteInfo<void> {
  const CMDStaffOversightRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDStaffOversightRoute.name, initialChildren: children);

  static const String name = 'CMDStaffOversightRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i21.CMDStaffOversightScreen();
    },
  );
}

/// generated route for
/// [_i22.CMDSystemControlScreen]
class CMDSystemControlRoute extends _i179.PageRouteInfo<void> {
  const CMDSystemControlRoute({List<_i179.PageRouteInfo>? children})
    : super(CMDSystemControlRoute.name, initialChildren: children);

  static const String name = 'CMDSystemControlRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i22.CMDSystemControlScreen();
    },
  );
}

/// generated route for
/// [_i23.CmacClinicalScreen]
class CmacClinicalRoute extends _i179.PageRouteInfo<void> {
  const CmacClinicalRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacClinicalRoute.name, initialChildren: children);

  static const String name = 'CmacClinicalRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i23.CmacClinicalScreen();
    },
  );
}

/// generated route for
/// [_i24.CmacInsightsScreen]
class CmacInsightsRoute extends _i179.PageRouteInfo<void> {
  const CmacInsightsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacInsightsRoute.name, initialChildren: children);

  static const String name = 'CmacInsightsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i24.CmacInsightsScreen();
    },
  );
}

/// generated route for
/// [_i25.CmacLaboratoryScreen]
class CmacLaboratoryRoute extends _i179.PageRouteInfo<void> {
  const CmacLaboratoryRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacLaboratoryRoute.name, initialChildren: children);

  static const String name = 'CmacLaboratoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i25.CmacLaboratoryScreen();
    },
  );
}

/// generated route for
/// [_i26.CmacOperationsScreen]
class CmacOperationsRoute extends _i179.PageRouteInfo<void> {
  const CmacOperationsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacOperationsRoute.name, initialChildren: children);

  static const String name = 'CmacOperationsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i26.CmacOperationsScreen();
    },
  );
}

/// generated route for
/// [_i27.CmacOverviewScreen]
class CmacOverviewRoute extends _i179.PageRouteInfo<void> {
  const CmacOverviewRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacOverviewRoute.name, initialChildren: children);

  static const String name = 'CmacOverviewRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i27.CmacOverviewScreen();
    },
  );
}

/// generated route for
/// [_i28.CmacPatientActivityScreen]
class CmacPatientActivityRoute extends _i179.PageRouteInfo<void> {
  const CmacPatientActivityRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacPatientActivityRoute.name, initialChildren: children);

  static const String name = 'CmacPatientActivityRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i28.CmacPatientActivityScreen();
    },
  );
}

/// generated route for
/// [_i29.CmacPharmacyScreen]
class CmacPharmacyRoute extends _i179.PageRouteInfo<void> {
  const CmacPharmacyRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacPharmacyRoute.name, initialChildren: children);

  static const String name = 'CmacPharmacyRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i29.CmacPharmacyScreen();
    },
  );
}

/// generated route for
/// [_i30.CmacQualityComplaintsScreen]
class CmacQualityComplaintsRoute extends _i179.PageRouteInfo<void> {
  const CmacQualityComplaintsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualityComplaintsRoute.name, initialChildren: children);

  static const String name = 'CmacQualityComplaintsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i30.CmacQualityComplaintsScreen();
    },
  );
}

/// generated route for
/// [_i31.CmacQualityDetailScreen]
class CmacQualityDetailRoute
    extends _i179.PageRouteInfo<CmacQualityDetailRouteArgs> {
  CmacQualityDetailRoute({
    _i180.Key? key,
    required String entity,
    required String recordId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         CmacQualityDetailRoute.name,
         args: CmacQualityDetailRouteArgs(
           key: key,
           entity: entity,
           recordId: recordId,
         ),
         rawPathParams: {'entity': entity, 'recordId': recordId},
         initialChildren: children,
       );

  static const String name = 'CmacQualityDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<CmacQualityDetailRouteArgs>(
        orElse: () => CmacQualityDetailRouteArgs(
          entity: pathParams.getString('entity'),
          recordId: pathParams.getString('recordId'),
        ),
      );
      return _i31.CmacQualityDetailScreen(
        key: args.key,
        entity: args.entity,
        recordId: args.recordId,
      );
    },
  );
}

class CmacQualityDetailRouteArgs {
  const CmacQualityDetailRouteArgs({
    this.key,
    required this.entity,
    required this.recordId,
  });

  final _i180.Key? key;

  final String entity;

  final String recordId;

  @override
  String toString() {
    return 'CmacQualityDetailRouteArgs{key: $key, entity: $entity, recordId: $recordId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CmacQualityDetailRouteArgs) return false;
    return key == other.key &&
        entity == other.entity &&
        recordId == other.recordId;
  }

  @override
  int get hashCode => key.hashCode ^ entity.hashCode ^ recordId.hashCode;
}

/// generated route for
/// [_i30.CmacQualityIncidentsScreen]
class CmacQualityIncidentsRoute extends _i179.PageRouteInfo<void> {
  const CmacQualityIncidentsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualityIncidentsRoute.name, initialChildren: children);

  static const String name = 'CmacQualityIncidentsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i30.CmacQualityIncidentsScreen();
    },
  );
}

/// generated route for
/// [_i30.CmacQualityInfectionsScreen]
class CmacQualityInfectionsRoute extends _i179.PageRouteInfo<void> {
  const CmacQualityInfectionsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualityInfectionsRoute.name, initialChildren: children);

  static const String name = 'CmacQualityInfectionsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i30.CmacQualityInfectionsScreen();
    },
  );
}

/// generated route for
/// [_i30.CmacQualityReferralsScreen]
class CmacQualityReferralsRoute extends _i179.PageRouteInfo<void> {
  const CmacQualityReferralsRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualityReferralsRoute.name, initialChildren: children);

  static const String name = 'CmacQualityReferralsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i30.CmacQualityReferralsScreen();
    },
  );
}

/// generated route for
/// [_i32.CmacQualitySafetyHubScreen]
class CmacQualitySafetyHubRoute extends _i179.PageRouteInfo<void> {
  const CmacQualitySafetyHubRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualitySafetyHubRoute.name, initialChildren: children);

  static const String name = 'CmacQualitySafetyHubRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i32.CmacQualitySafetyHubScreen();
    },
  );
}

/// generated route for
/// [_i33.CmacQualityScreen]
class CmacQualityRoute extends _i179.PageRouteInfo<void> {
  const CmacQualityRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacQualityRoute.name, initialChildren: children);

  static const String name = 'CmacQualityRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i33.CmacQualityScreen();
    },
  );
}

/// generated route for
/// [_i34.CmacStaffScreen]
class CmacStaffRoute extends _i179.PageRouteInfo<void> {
  const CmacStaffRoute({List<_i179.PageRouteInfo>? children})
    : super(CmacStaffRoute.name, initialChildren: children);

  static const String name = 'CmacStaffRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i34.CmacStaffScreen();
    },
  );
}

/// generated route for
/// [_i35.CompletedEncounterAppointmentsTab]
class CompletedEncounterAppointmentsTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterAppointmentsTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterAppointmentsTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterAppointmentsTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i35.CompletedEncounterAppointmentsTab();
    },
  );
}

/// generated route for
/// [_i36.CompletedEncounterDiagnosisTab]
class CompletedEncounterDiagnosisTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterDiagnosisTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterDiagnosisTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterDiagnosisTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i36.CompletedEncounterDiagnosisTab();
    },
  );
}

/// generated route for
/// [_i37.CompletedEncounterExaminationTab]
class CompletedEncounterExaminationTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterExaminationTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterExaminationTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterExaminationTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i37.CompletedEncounterExaminationTab();
    },
  );
}

/// generated route for
/// [_i38.CompletedEncounterFollowUpTab]
class CompletedEncounterFollowUpTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterFollowUpTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterFollowUpTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterFollowUpTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i38.CompletedEncounterFollowUpTab();
    },
  );
}

/// generated route for
/// [_i39.CompletedEncounterHistoryTab]
class CompletedEncounterHistoryTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterHistoryTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterHistoryTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterHistoryTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i39.CompletedEncounterHistoryTab();
    },
  );
}

/// generated route for
/// [_i40.CompletedEncounterImagingTab]
class CompletedEncounterImagingTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterImagingTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterImagingTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterImagingTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i40.CompletedEncounterImagingTab();
    },
  );
}

/// generated route for
/// [_i41.CompletedEncounterLabsTab]
class CompletedEncounterLabsTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterLabsTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterLabsTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterLabsTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i41.CompletedEncounterLabsTab();
    },
  );
}

/// generated route for
/// [_i42.CompletedEncounterNotesTab]
class CompletedEncounterNotesTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterNotesTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterNotesTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterNotesTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i42.CompletedEncounterNotesTab();
    },
  );
}

/// generated route for
/// [_i43.CompletedEncounterPrescriptionsTab]
class CompletedEncounterPrescriptionsTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterPrescriptionsTab({
    List<_i179.PageRouteInfo>? children,
  }) : super(
         CompletedEncounterPrescriptionsTab.name,
         initialChildren: children,
       );

  static const String name = 'CompletedEncounterPrescriptionsTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i43.CompletedEncounterPrescriptionsTab();
    },
  );
}

/// generated route for
/// [_i44.CompletedEncounterSummaryTab]
class CompletedEncounterSummaryTab extends _i179.PageRouteInfo<void> {
  const CompletedEncounterSummaryTab({List<_i179.PageRouteInfo>? children})
    : super(CompletedEncounterSummaryTab.name, initialChildren: children);

  static const String name = 'CompletedEncounterSummaryTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i44.CompletedEncounterSummaryTab();
    },
  );
}

/// generated route for
/// [_i45.ConsultingRoomsScreen]
class ConsultingRoomsRoute extends _i179.PageRouteInfo<void> {
  const ConsultingRoomsRoute({List<_i179.PageRouteInfo>? children})
    : super(ConsultingRoomsRoute.name, initialChildren: children);

  static const String name = 'ConsultingRoomsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i45.ConsultingRoomsScreen();
    },
  );
}

/// generated route for
/// [_i46.CreateRequisitionScreen]
class CreateRequisitionRoute extends _i179.PageRouteInfo<void> {
  const CreateRequisitionRoute({List<_i179.PageRouteInfo>? children})
    : super(CreateRequisitionRoute.name, initialChildren: children);

  static const String name = 'CreateRequisitionRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i46.CreateRequisitionScreen();
    },
  );
}

/// generated route for
/// [_i47.DashboardScreen]
class DashboardRoute extends _i179.PageRouteInfo<void> {
  const DashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i47.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i48.DiscountPolicyManagementScreen]
class DiscountPolicyManagementRoute extends _i179.PageRouteInfo<void> {
  const DiscountPolicyManagementRoute({List<_i179.PageRouteInfo>? children})
    : super(DiscountPolicyManagementRoute.name, initialChildren: children);

  static const String name = 'DiscountPolicyManagementRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i48.DiscountPolicyManagementScreen();
    },
  );
}

/// generated route for
/// [_i49.DispenseHistoryScreen]
class DispenseHistoryRoute
    extends _i179.PageRouteInfo<DispenseHistoryRouteArgs> {
  DispenseHistoryRoute({
    _i180.Key? key,
    String? fromDate,
    String? toDate,
    String? drugId,
    String? patientQuery,
    int? page,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         DispenseHistoryRoute.name,
         args: DispenseHistoryRouteArgs(
           key: key,
           fromDate: fromDate,
           toDate: toDate,
           drugId: drugId,
           patientQuery: patientQuery,
           page: page,
         ),
         rawQueryParams: {
           'fromDate': fromDate,
           'toDate': toDate,
           'drugId': drugId,
           'patientQuery': patientQuery,
           'page': page,
         },
         initialChildren: children,
       );

  static const String name = 'DispenseHistoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<DispenseHistoryRouteArgs>(
        orElse: () => DispenseHistoryRouteArgs(
          fromDate: queryParams.optString('fromDate'),
          toDate: queryParams.optString('toDate'),
          drugId: queryParams.optString('drugId'),
          patientQuery: queryParams.optString('patientQuery'),
          page: queryParams.optInt('page'),
        ),
      );
      return _i49.DispenseHistoryScreen(
        key: args.key,
        fromDate: args.fromDate,
        toDate: args.toDate,
        drugId: args.drugId,
        patientQuery: args.patientQuery,
        page: args.page,
      );
    },
  );
}

class DispenseHistoryRouteArgs {
  const DispenseHistoryRouteArgs({
    this.key,
    this.fromDate,
    this.toDate,
    this.drugId,
    this.patientQuery,
    this.page,
  });

  final _i180.Key? key;

  final String? fromDate;

  final String? toDate;

  final String? drugId;

  final String? patientQuery;

  final int? page;

  @override
  String toString() {
    return 'DispenseHistoryRouteArgs{key: $key, fromDate: $fromDate, toDate: $toDate, drugId: $drugId, patientQuery: $patientQuery, page: $page}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DispenseHistoryRouteArgs) return false;
    return key == other.key &&
        fromDate == other.fromDate &&
        toDate == other.toDate &&
        drugId == other.drugId &&
        patientQuery == other.patientQuery &&
        page == other.page;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      fromDate.hashCode ^
      toDate.hashCode ^
      drugId.hashCode ^
      patientQuery.hashCode ^
      page.hashCode;
}

/// generated route for
/// [_i50.DispenseScreen]
class DispenseRoute extends _i179.PageRouteInfo<DispenseRouteArgs> {
  DispenseRoute({
    _i180.Key? key,
    required String patientId,
    required String patientName,
    required String id,
    String? invoiceId,
    String? staffId,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DispenseRouteArgs>();
      return _i50.DispenseScreen(
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

  final _i180.Key? key;

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
/// [_i51.DoctorCompletedEncounterViewScreen]
class DoctorCompletedEncounterViewRoute
    extends _i179.PageRouteInfo<DoctorCompletedEncounterViewRouteArgs> {
  DoctorCompletedEncounterViewRoute({
    _i180.Key? key,
    required String encounterId,
    required String patientId,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DoctorCompletedEncounterViewRouteArgs>();
      return _i51.DoctorCompletedEncounterViewScreen(
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

  final _i180.Key? key;

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
/// [_i52.DoctorCompletedEncountersScreen]
class DoctorCompletedEncountersRoute extends _i179.PageRouteInfo<void> {
  const DoctorCompletedEncountersRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorCompletedEncountersRoute.name, initialChildren: children);

  static const String name = 'DoctorCompletedEncountersRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i52.DoctorCompletedEncountersScreen();
    },
  );
}

/// generated route for
/// [_i53.DoctorDashboardScreen]
class DoctorDashboardRoute extends _i179.PageRouteInfo<void> {
  const DoctorDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorDashboardRoute.name, initialChildren: children);

  static const String name = 'DoctorDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i53.DoctorDashboardScreen();
    },
  );
}

/// generated route for
/// [_i54.DoctorEncounterAdmissionTab]
class DoctorEncounterAdmissionTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterAdmissionTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterAdmissionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterAdmissionTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i54.DoctorEncounterAdmissionTab();
    },
  );
}

/// generated route for
/// [_i55.DoctorEncounterDiagnosisTab]
class DoctorEncounterDiagnosisTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterDiagnosisTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterDiagnosisTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterDiagnosisTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i55.DoctorEncounterDiagnosisTab();
    },
  );
}

/// generated route for
/// [_i56.DoctorEncounterExaminationTab]
class DoctorEncounterExaminationTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterExaminationTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterExaminationTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterExaminationTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i56.DoctorEncounterExaminationTab();
    },
  );
}

/// generated route for
/// [_i57.DoctorEncounterFollowUpTab]
class DoctorEncounterFollowUpTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterFollowUpTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterFollowUpTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterFollowUpTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i57.DoctorEncounterFollowUpTab();
    },
  );
}

/// generated route for
/// [_i58.DoctorEncounterHistoryTab]
class DoctorEncounterHistoryTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterHistoryTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterHistoryTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterHistoryTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i58.DoctorEncounterHistoryTab();
    },
  );
}

/// generated route for
/// [_i59.DoctorEncounterImagingTab]
class DoctorEncounterImagingTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterImagingTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterImagingTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterImagingTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i59.DoctorEncounterImagingTab();
    },
  );
}

/// generated route for
/// [_i60.DoctorEncounterInvestigationsTab]
class DoctorEncounterInvestigationsTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterInvestigationsTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterInvestigationsTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterInvestigationsTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i60.DoctorEncounterInvestigationsTab();
    },
  );
}

/// generated route for
/// [_i61.DoctorEncounterNotesTab]
class DoctorEncounterNotesTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterNotesTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterNotesTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterNotesTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i61.DoctorEncounterNotesTab();
    },
  );
}

/// generated route for
/// [_i62.DoctorEncounterPrescriptionTab]
class DoctorEncounterPrescriptionTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterPrescriptionTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterPrescriptionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterPrescriptionTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i62.DoctorEncounterPrescriptionTab();
    },
  );
}

/// generated route for
/// [_i63.DoctorEncounterProceduresTab]
class DoctorEncounterProceduresTab extends _i179.PageRouteInfo<void> {
  const DoctorEncounterProceduresTab({List<_i179.PageRouteInfo>? children})
    : super(DoctorEncounterProceduresTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterProceduresTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i63.DoctorEncounterProceduresTab();
    },
  );
}

/// generated route for
/// [_i64.DoctorEncounterViewScreen]
class DoctorEncounterViewRoute
    extends _i179.PageRouteInfo<DoctorEncounterViewRouteArgs> {
  DoctorEncounterViewRoute({
    _i180.Key? key,
    required String encounterId,
    required String patientId,
    String? patientVitalsJson,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DoctorEncounterViewRouteArgs>();
      return _i64.DoctorEncounterViewScreen(
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

  final _i180.Key? key;

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
/// [_i65.DoctorOutpatientListScreen]
class DoctorOutpatientListRoute extends _i179.PageRouteInfo<void> {
  const DoctorOutpatientListRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorOutpatientListRoute.name, initialChildren: children);

  static const String name = 'DoctorOutpatientListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i65.DoctorOutpatientListScreen();
    },
  );
}

/// generated route for
/// [_i66.DoctorPendingImagingScreen]
class DoctorPendingImagingRoute extends _i179.PageRouteInfo<void> {
  const DoctorPendingImagingRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorPendingImagingRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingImagingRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i66.DoctorPendingImagingScreen();
    },
  );
}

/// generated route for
/// [_i67.DoctorPendingLabsScreen]
class DoctorPendingLabsRoute extends _i179.PageRouteInfo<void> {
  const DoctorPendingLabsRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorPendingLabsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingLabsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i67.DoctorPendingLabsScreen();
    },
  );
}

/// generated route for
/// [_i68.DoctorPendingPrescriptionsScreen]
class DoctorPendingPrescriptionsRoute extends _i179.PageRouteInfo<void> {
  const DoctorPendingPrescriptionsRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorPendingPrescriptionsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingPrescriptionsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i68.DoctorPendingPrescriptionsScreen();
    },
  );
}

/// generated route for
/// [_i69.DoctorProfileScreen]
class DoctorProfileRoute extends _i179.PageRouteInfo<void> {
  const DoctorProfileRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorProfileRoute.name, initialChildren: children);

  static const String name = 'DoctorProfileRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i69.DoctorProfileScreen();
    },
  );
}

/// generated route for
/// [_i70.DoctorTemplatesScreen]
class DoctorTemplatesRoute extends _i179.PageRouteInfo<void> {
  const DoctorTemplatesRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorTemplatesRoute.name, initialChildren: children);

  static const String name = 'DoctorTemplatesRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i70.DoctorTemplatesScreen();
    },
  );
}

/// generated route for
/// [_i71.DoctorWalkInQueueScreen]
class DoctorWalkInQueueRoute extends _i179.PageRouteInfo<void> {
  const DoctorWalkInQueueRoute({List<_i179.PageRouteInfo>? children})
    : super(DoctorWalkInQueueRoute.name, initialChildren: children);

  static const String name = 'DoctorWalkInQueueRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i71.DoctorWalkInQueueScreen();
    },
  );
}

/// generated route for
/// [_i72.EnlistPaitientScreen]
class EnlistPaitientRoute extends _i179.PageRouteInfo<EnlistPaitientRouteArgs> {
  EnlistPaitientRoute({
    _i180.Key? key,
    required String serviceName,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         EnlistPaitientRoute.name,
         args: EnlistPaitientRouteArgs(key: key, serviceName: serviceName),
         initialChildren: children,
       );

  static const String name = 'EnlistPaitientRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EnlistPaitientRouteArgs>();
      return _i72.EnlistPaitientScreen(
        key: args.key,
        serviceName: args.serviceName,
      );
    },
  );
}

class EnlistPaitientRouteArgs {
  const EnlistPaitientRouteArgs({this.key, required this.serviceName});

  final _i180.Key? key;

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
/// [_i73.EnlistServiceScreen]
class EnlistServiceRoute extends _i179.PageRouteInfo<void> {
  const EnlistServiceRoute({List<_i179.PageRouteInfo>? children})
    : super(EnlistServiceRoute.name, initialChildren: children);

  static const String name = 'EnlistServiceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i73.EnlistServiceScreen();
    },
  );
}

/// generated route for
/// [_i74.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i179.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i179.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i74.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i75.FrontDeskDashboardScreen]
class FrontDeskDashboardRoute extends _i179.PageRouteInfo<void> {
  const FrontDeskDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(FrontDeskDashboardRoute.name, initialChildren: children);

  static const String name = 'FrontDeskDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i75.FrontDeskDashboardScreen();
    },
  );
}

/// generated route for
/// [_i76.HelpCenterScreen]
class HelpCenterRoute extends _i179.PageRouteInfo<void> {
  const HelpCenterRoute({List<_i179.PageRouteInfo>? children})
    : super(HelpCenterRoute.name, initialChildren: children);

  static const String name = 'HelpCenterRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i76.HelpCenterScreen();
    },
  );
}

/// generated route for
/// [_i77.HmoDetailScreen]
class HmoDetailRoute extends _i179.PageRouteInfo<HmoDetailRouteArgs> {
  HmoDetailRoute({
    _i180.Key? key,
    required String hmoId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         HmoDetailRoute.name,
         args: HmoDetailRouteArgs(key: key, hmoId: hmoId),
         initialChildren: children,
       );

  static const String name = 'HmoDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HmoDetailRouteArgs>();
      return _i77.HmoDetailScreen(key: args.key, hmoId: args.hmoId);
    },
  );
}

class HmoDetailRouteArgs {
  const HmoDetailRouteArgs({this.key, required this.hmoId});

  final _i180.Key? key;

  final String hmoId;

  @override
  String toString() {
    return 'HmoDetailRouteArgs{key: $key, hmoId: $hmoId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HmoDetailRouteArgs) return false;
    return key == other.key && hmoId == other.hmoId;
  }

  @override
  int get hashCode => key.hashCode ^ hmoId.hashCode;
}

/// generated route for
/// [_i78.HmoFormScreen]
class HmoFormRoute extends _i179.PageRouteInfo<HmoFormRouteArgs> {
  HmoFormRoute({
    _i180.Key? key,
    String? hmoId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         HmoFormRoute.name,
         args: HmoFormRouteArgs(key: key, hmoId: hmoId),
         initialChildren: children,
       );

  static const String name = 'HmoFormRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HmoFormRouteArgs>(
        orElse: () => const HmoFormRouteArgs(),
      );
      return _i78.HmoFormScreen(key: args.key, hmoId: args.hmoId);
    },
  );
}

class HmoFormRouteArgs {
  const HmoFormRouteArgs({this.key, this.hmoId});

  final _i180.Key? key;

  final String? hmoId;

  @override
  String toString() {
    return 'HmoFormRouteArgs{key: $key, hmoId: $hmoId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HmoFormRouteArgs) return false;
    return key == other.key && hmoId == other.hmoId;
  }

  @override
  int get hashCode => key.hashCode ^ hmoId.hashCode;
}

/// generated route for
/// [_i79.HmoListScreen]
class HmoListRoute extends _i179.PageRouteInfo<void> {
  const HmoListRoute({List<_i179.PageRouteInfo>? children})
    : super(HmoListRoute.name, initialChildren: children);

  static const String name = 'HmoListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i79.HmoListScreen();
    },
  );
}

/// generated route for
/// [_i80.HmoServicePricingScreen]
class HmoServicePricingRoute
    extends _i179.PageRouteInfo<HmoServicePricingRouteArgs> {
  HmoServicePricingRoute({
    _i180.Key? key,
    String? initialHmoId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         HmoServicePricingRoute.name,
         args: HmoServicePricingRouteArgs(key: key, initialHmoId: initialHmoId),
         initialChildren: children,
       );

  static const String name = 'HmoServicePricingRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HmoServicePricingRouteArgs>(
        orElse: () => const HmoServicePricingRouteArgs(),
      );
      return _i80.HmoServicePricingScreen(
        key: args.key,
        initialHmoId: args.initialHmoId,
      );
    },
  );
}

class HmoServicePricingRouteArgs {
  const HmoServicePricingRouteArgs({this.key, this.initialHmoId});

  final _i180.Key? key;

  final String? initialHmoId;

  @override
  String toString() {
    return 'HmoServicePricingRouteArgs{key: $key, initialHmoId: $initialHmoId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HmoServicePricingRouteArgs) return false;
    return key == other.key && initialHmoId == other.initialHmoId;
  }

  @override
  int get hashCode => key.hashCode ^ initialHmoId.hashCode;
}

/// generated route for
/// [_i81.HomeScreen]
class HomeRoute extends _i179.PageRouteInfo<void> {
  const HomeRoute({List<_i179.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i81.HomeScreen();
    },
  );
}

/// generated route for
/// [_i82.InpatientAlertsScreen]
class InpatientAlertsRoute extends _i179.PageRouteInfo<void> {
  const InpatientAlertsRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientAlertsRoute.name, initialChildren: children);

  static const String name = 'InpatientAlertsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i82.InpatientAlertsScreen();
    },
  );
}

/// generated route for
/// [_i83.InpatientBillsListScreen]
class InpatientBillsListRoute extends _i179.PageRouteInfo<void> {
  const InpatientBillsListRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientBillsListRoute.name, initialChildren: children);

  static const String name = 'InpatientBillsListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i83.InpatientBillsListScreen();
    },
  );
}

/// generated route for
/// [_i84.InpatientCarePlanScreen]
class InpatientCarePlanRoute extends _i179.PageRouteInfo<void> {
  const InpatientCarePlanRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientCarePlanRoute.name, initialChildren: children);

  static const String name = 'InpatientCarePlanRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i84.InpatientCarePlanScreen();
    },
  );
}

/// generated route for
/// [_i85.InpatientHandoverScreen]
class InpatientHandoverRoute extends _i179.PageRouteInfo<void> {
  const InpatientHandoverRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientHandoverRoute.name, initialChildren: children);

  static const String name = 'InpatientHandoverRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i85.InpatientHandoverScreen();
    },
  );
}

/// generated route for
/// [_i86.InpatientIOScreen]
class InpatientIORoute extends _i179.PageRouteInfo<void> {
  const InpatientIORoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientIORoute.name, initialChildren: children);

  static const String name = 'InpatientIORoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i86.InpatientIOScreen();
    },
  );
}

/// generated route for
/// [_i87.InpatientIVScreen]
class InpatientIVRoute extends _i179.PageRouteInfo<void> {
  const InpatientIVRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientIVRoute.name, initialChildren: children);

  static const String name = 'InpatientIVRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i87.InpatientIVScreen();
    },
  );
}

/// generated route for
/// [_i88.InpatientImagingResultsScreen]
class InpatientImagingResultsRoute extends _i179.PageRouteInfo<void> {
  const InpatientImagingResultsRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientImagingResultsRoute.name, initialChildren: children);

  static const String name = 'InpatientImagingResultsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i88.InpatientImagingResultsScreen();
    },
  );
}

/// generated route for
/// [_i89.InpatientLabResultsScreen]
class InpatientLabResultsRoute extends _i179.PageRouteInfo<void> {
  const InpatientLabResultsRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientLabResultsRoute.name, initialChildren: children);

  static const String name = 'InpatientLabResultsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i89.InpatientLabResultsScreen();
    },
  );
}

/// generated route for
/// [_i90.InpatientMedicationsScreen]
class InpatientMedicationsRoute extends _i179.PageRouteInfo<void> {
  const InpatientMedicationsRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientMedicationsRoute.name, initialChildren: children);

  static const String name = 'InpatientMedicationsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i90.InpatientMedicationsScreen();
    },
  );
}

/// generated route for
/// [_i91.InpatientMonitoringScreen]
class InpatientMonitoringRoute extends _i179.PageRouteInfo<void> {
  const InpatientMonitoringRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientMonitoringRoute.name, initialChildren: children);

  static const String name = 'InpatientMonitoringRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i91.InpatientMonitoringScreen();
    },
  );
}

/// generated route for
/// [_i92.InpatientNotesScreen]
class InpatientNotesRoute extends _i179.PageRouteInfo<void> {
  const InpatientNotesRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientNotesRoute.name, initialChildren: children);

  static const String name = 'InpatientNotesRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i92.InpatientNotesScreen();
    },
  );
}

/// generated route for
/// [_i93.InpatientOverviewScreen]
class InpatientOverviewRoute extends _i179.PageRouteInfo<void> {
  const InpatientOverviewRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientOverviewRoute.name, initialChildren: children);

  static const String name = 'InpatientOverviewRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i93.InpatientOverviewScreen();
    },
  );
}

/// generated route for
/// [_i94.InpatientPatientViewScreen]
class InpatientPatientViewRoute
    extends _i179.PageRouteInfo<InpatientPatientViewRouteArgs> {
  InpatientPatientViewRoute({
    _i180.Key? key,
    required String admissionId,
    String? ward,
    String? bedNumber,
    String? attendingDoctor,
    String? diagnosis,
    DateTime? admissionDate,
    List<String>? allergies,
    String? codeStatus,
    List<String>? riskFlags,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InpatientPatientViewRouteArgs>();
      return _i94.InpatientPatientViewScreen(
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

  final _i180.Key? key;

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
        const _i183.ListEquality<String>().equals(allergies, other.allergies) &&
        codeStatus == other.codeStatus &&
        const _i183.ListEquality<String>().equals(riskFlags, other.riskFlags);
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
      const _i183.ListEquality<String>().hash(allergies) ^
      codeStatus.hashCode ^
      const _i183.ListEquality<String>().hash(riskFlags);
}

/// generated route for
/// [_i95.InpatientProceduresScreen]
class InpatientProceduresRoute extends _i179.PageRouteInfo<void> {
  const InpatientProceduresRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientProceduresRoute.name, initialChildren: children);

  static const String name = 'InpatientProceduresRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i95.InpatientProceduresScreen();
    },
  );
}

/// generated route for
/// [_i96.InpatientVitalsScreen]
class InpatientVitalsRoute
    extends _i179.PageRouteInfo<InpatientVitalsRouteArgs> {
  InpatientVitalsRoute({
    _i180.Key? key,
    required List<_i184.PatientVitalsModel> vitals,
    required String admissionId,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InpatientVitalsRouteArgs>();
      return _i96.InpatientVitalsScreen(
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

  final _i180.Key? key;

  final List<_i184.PatientVitalsModel> vitals;

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
        const _i183.ListEquality<_i184.PatientVitalsModel>().equals(
          vitals,
          other.vitals,
        ) &&
        admissionId == other.admissionId;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      const _i183.ListEquality<_i184.PatientVitalsModel>().hash(vitals) ^
      admissionId.hashCode;
}

/// generated route for
/// [_i97.InpatientWardRoundTab]
class InpatientWardRoundTab extends _i179.PageRouteInfo<void> {
  const InpatientWardRoundTab({List<_i179.PageRouteInfo>? children})
    : super(InpatientWardRoundTab.name, initialChildren: children);

  static const String name = 'InpatientWardRoundTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i97.InpatientWardRoundTab();
    },
  );
}

/// generated route for
/// [_i98.InpatientsListScreen]
class InpatientsListRoute extends _i179.PageRouteInfo<void> {
  const InpatientsListRoute({List<_i179.PageRouteInfo>? children})
    : super(InpatientsListRoute.name, initialChildren: children);

  static const String name = 'InpatientsListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i98.InpatientsListScreen();
    },
  );
}

/// generated route for
/// [_i99.LabConfigScreen]
class LabConfigRoute extends _i179.PageRouteInfo<void> {
  const LabConfigRoute({List<_i179.PageRouteInfo>? children})
    : super(LabConfigRoute.name, initialChildren: children);

  static const String name = 'LabConfigRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i99.LabConfigScreen();
    },
  );
}

/// generated route for
/// [_i100.LabCreateOrderScreen]
class LabCreateOrderRoute extends _i179.PageRouteInfo<void> {
  const LabCreateOrderRoute({List<_i179.PageRouteInfo>? children})
    : super(LabCreateOrderRoute.name, initialChildren: children);

  static const String name = 'LabCreateOrderRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i100.LabCreateOrderScreen();
    },
  );
}

/// generated route for
/// [_i101.LabDashboardScreen]
class LabDashboardRoute extends _i179.PageRouteInfo<void> {
  const LabDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(LabDashboardRoute.name, initialChildren: children);

  static const String name = 'LabDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i101.LabDashboardScreen();
    },
  );
}

/// generated route for
/// [_i102.LabOrderDetailScreen]
class LabOrderDetailRoute extends _i179.PageRouteInfo<LabOrderDetailRouteArgs> {
  LabOrderDetailRoute({
    _i180.Key? key,
    required String orderId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         LabOrderDetailRoute.name,
         args: LabOrderDetailRouteArgs(key: key, orderId: orderId),
         initialChildren: children,
       );

  static const String name = 'LabOrderDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LabOrderDetailRouteArgs>();
      return _i102.LabOrderDetailScreen(key: args.key, orderId: args.orderId);
    },
  );
}

class LabOrderDetailRouteArgs {
  const LabOrderDetailRouteArgs({this.key, required this.orderId});

  final _i180.Key? key;

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
/// [_i103.LabResultEntryScreen]
class LabResultEntryRoute extends _i179.PageRouteInfo<LabResultEntryRouteArgs> {
  LabResultEntryRoute({
    _i180.Key? key,
    required String orderId,
    required String orderItemId,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<LabResultEntryRouteArgs>();
      return _i103.LabResultEntryScreen(
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

  final _i180.Key? key;

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
/// [_i104.LoginScreen]
class LoginRoute extends _i179.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i180.Key? key,
    String? redirectTo,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, redirectTo: redirectTo),
         rawQueryParams: {'redirectTo': redirectTo},
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(redirectTo: queryParams.optString('redirectTo')),
      );
      return _i104.LoginScreen(key: args.key, redirectTo: args.redirectTo);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.redirectTo});

  final _i180.Key? key;

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
/// [_i105.MedicineInventoryScreen]
class MedicineInventoryRoute extends _i179.PageRouteInfo<void> {
  const MedicineInventoryRoute({List<_i179.PageRouteInfo>? children})
    : super(MedicineInventoryRoute.name, initialChildren: children);

  static const String name = 'MedicineInventoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i105.MedicineInventoryScreen();
    },
  );
}

/// generated route for
/// [_i106.NewAppointmentScreen]
class NewAppointmentRoute extends _i179.PageRouteInfo<void> {
  const NewAppointmentRoute({List<_i179.PageRouteInfo>? children})
    : super(NewAppointmentRoute.name, initialChildren: children);

  static const String name = 'NewAppointmentRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i106.NewAppointmentScreen();
    },
  );
}

/// generated route for
/// [_i107.NewPatientScreen]
class NewPatientRoute extends _i179.PageRouteInfo<NewPatientRouteArgs> {
  NewPatientRoute({
    _i180.Key? key,
    String use = 'For Register',
    List<String> categoryQueries = const ['Laboratory', 'Laboratory Tests'],
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewPatientRouteArgs>(
        orElse: () => const NewPatientRouteArgs(),
      );
      return _i107.NewPatientScreen(
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
    this.categoryQueries = const ['Laboratory', 'Laboratory Tests'],
  });

  final _i180.Key? key;

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
        const _i183.ListEquality<String>().equals(
          categoryQueries,
          other.categoryQueries,
        );
  }

  @override
  int get hashCode =>
      key.hashCode ^
      use.hashCode ^
      const _i183.ListEquality<String>().hash(categoryQueries);
}

/// generated route for
/// [_i108.NotAvailableScreen]
class NotAvailableRoute extends _i179.PageRouteInfo<void> {
  const NotAvailableRoute({List<_i179.PageRouteInfo>? children})
    : super(NotAvailableRoute.name, initialChildren: children);

  static const String name = 'NotAvailableRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i108.NotAvailableScreen();
    },
  );
}

/// generated route for
/// [_i109.NurseConsumableUsageScreen]
class NurseConsumableUsageRoute extends _i179.PageRouteInfo<void> {
  const NurseConsumableUsageRoute({List<_i179.PageRouteInfo>? children})
    : super(NurseConsumableUsageRoute.name, initialChildren: children);

  static const String name = 'NurseConsumableUsageRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i109.NurseConsumableUsageScreen();
    },
  );
}

/// generated route for
/// [_i110.NursesDashboardScreen]
class NursesDashboardRoute extends _i179.PageRouteInfo<void> {
  const NursesDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(NursesDashboardRoute.name, initialChildren: children);

  static const String name = 'NursesDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i110.NursesDashboardScreen();
    },
  );
}

/// generated route for
/// [_i111.ObstetricsAddAntenatalVisitScreen]
class ObstetricsAddAntenatalVisitRoute
    extends _i179.PageRouteInfo<ObstetricsAddAntenatalVisitRouteArgs> {
  ObstetricsAddAntenatalVisitRoute({
    _i180.Key? key,
    required String pregnancyId,
    String? encounterId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddAntenatalVisitRoute.name,
         args: ObstetricsAddAntenatalVisitRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
           encounterId: encounterId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddAntenatalVisitRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddAntenatalVisitRouteArgs>();
      return _i111.ObstetricsAddAntenatalVisitScreen(
        key: args.key,
        pregnancyId: args.pregnancyId,
        encounterId: args.encounterId,
      );
    },
  );
}

class ObstetricsAddAntenatalVisitRouteArgs {
  const ObstetricsAddAntenatalVisitRouteArgs({
    this.key,
    required this.pregnancyId,
    this.encounterId,
  });

  final _i180.Key? key;

  final String pregnancyId;

  final String? encounterId;

  @override
  String toString() {
    return 'ObstetricsAddAntenatalVisitRouteArgs{key: $key, pregnancyId: $pregnancyId, encounterId: $encounterId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddAntenatalVisitRouteArgs) return false;
    return key == other.key &&
        pregnancyId == other.pregnancyId &&
        encounterId == other.encounterId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ pregnancyId.hashCode ^ encounterId.hashCode;
}

/// generated route for
/// [_i112.ObstetricsAddBabyScreen]
class ObstetricsAddBabyRoute
    extends _i179.PageRouteInfo<ObstetricsAddBabyRouteArgs> {
  ObstetricsAddBabyRoute({
    _i180.Key? key,
    required String labourDeliveryId,
    required String pregnancyId,
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddBabyRouteArgs>();
      return _i112.ObstetricsAddBabyScreen(
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

  final _i180.Key? key;

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
/// [_i113.ObstetricsAddGynaeProcedureScreen]
class ObstetricsAddGynaeProcedureRoute
    extends _i179.PageRouteInfo<ObstetricsAddGynaeProcedureRouteArgs> {
  ObstetricsAddGynaeProcedureRoute({
    _i180.Key? key,
    String? patientId,
    String? encounterId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddGynaeProcedureRoute.name,
         args: ObstetricsAddGynaeProcedureRouteArgs(
           key: key,
           patientId: patientId,
           encounterId: encounterId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddGynaeProcedureRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddGynaeProcedureRouteArgs>(
        orElse: () => const ObstetricsAddGynaeProcedureRouteArgs(),
      );
      return _i113.ObstetricsAddGynaeProcedureScreen(
        key: args.key,
        patientId: args.patientId,
        encounterId: args.encounterId,
      );
    },
  );
}

class ObstetricsAddGynaeProcedureRouteArgs {
  const ObstetricsAddGynaeProcedureRouteArgs({
    this.key,
    this.patientId,
    this.encounterId,
  });

  final _i180.Key? key;

  final String? patientId;

  final String? encounterId;

  @override
  String toString() {
    return 'ObstetricsAddGynaeProcedureRouteArgs{key: $key, patientId: $patientId, encounterId: $encounterId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsAddGynaeProcedureRouteArgs) return false;
    return key == other.key &&
        patientId == other.patientId &&
        encounterId == other.encounterId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode ^ encounterId.hashCode;
}

/// generated route for
/// [_i114.ObstetricsAddLabourDeliveryScreen]
class ObstetricsAddLabourDeliveryRoute
    extends _i179.PageRouteInfo<ObstetricsAddLabourDeliveryRouteArgs> {
  ObstetricsAddLabourDeliveryRoute({
    _i180.Key? key,
    required String pregnancyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddLabourDeliveryRoute.name,
         args: ObstetricsAddLabourDeliveryRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddLabourDeliveryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddLabourDeliveryRouteArgs>();
      return _i114.ObstetricsAddLabourDeliveryScreen(
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

  final _i180.Key? key;

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
/// [_i115.ObstetricsAddPartogramEntryScreen]
class ObstetricsAddPartogramEntryRoute
    extends _i179.PageRouteInfo<ObstetricsAddPartogramEntryRouteArgs> {
  ObstetricsAddPartogramEntryRoute({
    _i180.Key? key,
    required String labourDeliveryId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPartogramEntryRoute.name,
         args: ObstetricsAddPartogramEntryRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPartogramEntryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPartogramEntryRouteArgs>();
      return _i115.ObstetricsAddPartogramEntryScreen(
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

  final _i180.Key? key;

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
/// [_i116.ObstetricsAddPostnatalVisitScreen]
class ObstetricsAddPostnatalVisitRoute
    extends _i179.PageRouteInfo<ObstetricsAddPostnatalVisitRouteArgs> {
  ObstetricsAddPostnatalVisitRoute({
    _i180.Key? key,
    required String labourDeliveryId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPostnatalVisitRoute.name,
         args: ObstetricsAddPostnatalVisitRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPostnatalVisitRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPostnatalVisitRouteArgs>();
      return _i116.ObstetricsAddPostnatalVisitScreen(
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

  final _i180.Key? key;

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
/// [_i117.ObstetricsAddPregnancyScreen]
class ObstetricsAddPregnancyRoute
    extends _i179.PageRouteInfo<ObstetricsAddPregnancyRouteArgs> {
  ObstetricsAddPregnancyRoute({
    _i180.Key? key,
    String? patientId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAddPregnancyRoute.name,
         args: ObstetricsAddPregnancyRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAddPregnancyRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAddPregnancyRouteArgs>(
        orElse: () => const ObstetricsAddPregnancyRouteArgs(),
      );
      return _i117.ObstetricsAddPregnancyScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsAddPregnancyRouteArgs {
  const ObstetricsAddPregnancyRouteArgs({this.key, this.patientId});

  final _i180.Key? key;

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
/// [_i118.ObstetricsAntenatalVisitsTab]
class ObstetricsAntenatalVisitsTab
    extends _i179.PageRouteInfo<ObstetricsAntenatalVisitsTabArgs> {
  ObstetricsAntenatalVisitsTab({
    _i180.Key? key,
    String? pregnancyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsAntenatalVisitsTab.name,
         args: ObstetricsAntenatalVisitsTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsAntenatalVisitsTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsAntenatalVisitsTabArgs>(
        orElse: () => const ObstetricsAntenatalVisitsTabArgs(),
      );
      return _i118.ObstetricsAntenatalVisitsTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsAntenatalVisitsTabArgs {
  const ObstetricsAntenatalVisitsTabArgs({this.key, this.pregnancyId});

  final _i180.Key? key;

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
/// [_i119.ObstetricsDashboardScreen]
class ObstetricsDashboardRoute extends _i179.PageRouteInfo<void> {
  const ObstetricsDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(ObstetricsDashboardRoute.name, initialChildren: children);

  static const String name = 'ObstetricsDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i119.ObstetricsDashboardScreen();
    },
  );
}

/// generated route for
/// [_i120.ObstetricsEditAntenatalVisitScreen]
class ObstetricsEditAntenatalVisitRoute
    extends _i179.PageRouteInfo<ObstetricsEditAntenatalVisitRouteArgs> {
  ObstetricsEditAntenatalVisitRoute({
    _i180.Key? key,
    required String visitId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditAntenatalVisitRoute.name,
         args: ObstetricsEditAntenatalVisitRouteArgs(
           key: key,
           visitId: visitId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditAntenatalVisitRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditAntenatalVisitRouteArgs>();
      return _i120.ObstetricsEditAntenatalVisitScreen(
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

  final _i180.Key? key;

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
/// [_i121.ObstetricsEditBabyScreen]
class ObstetricsEditBabyRoute
    extends _i179.PageRouteInfo<ObstetricsEditBabyRouteArgs> {
  ObstetricsEditBabyRoute({
    _i180.Key? key,
    required String babyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditBabyRoute.name,
         args: ObstetricsEditBabyRouteArgs(key: key, babyId: babyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditBabyRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditBabyRouteArgs>();
      return _i121.ObstetricsEditBabyScreen(key: args.key, babyId: args.babyId);
    },
  );
}

class ObstetricsEditBabyRouteArgs {
  const ObstetricsEditBabyRouteArgs({this.key, required this.babyId});

  final _i180.Key? key;

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
/// [_i122.ObstetricsEditGynaeProcedureScreen]
class ObstetricsEditGynaeProcedureRoute
    extends _i179.PageRouteInfo<ObstetricsEditGynaeProcedureRouteArgs> {
  ObstetricsEditGynaeProcedureRoute({
    _i180.Key? key,
    required String procedureId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsEditGynaeProcedureRoute.name,
         args: ObstetricsEditGynaeProcedureRouteArgs(
           key: key,
           procedureId: procedureId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsEditGynaeProcedureRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsEditGynaeProcedureRouteArgs>();
      return _i122.ObstetricsEditGynaeProcedureScreen(
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

  final _i180.Key? key;

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
/// [_i123.ObstetricsGynaeProceduresScreen]
class ObstetricsGynaeProceduresRoute
    extends _i179.PageRouteInfo<ObstetricsGynaeProceduresRouteArgs> {
  ObstetricsGynaeProceduresRoute({
    _i180.Key? key,
    String? patientId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsGynaeProceduresRoute.name,
         args: ObstetricsGynaeProceduresRouteArgs(
           key: key,
           patientId: patientId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsGynaeProceduresRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsGynaeProceduresRouteArgs>(
        orElse: () => const ObstetricsGynaeProceduresRouteArgs(),
      );
      return _i123.ObstetricsGynaeProceduresScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class ObstetricsGynaeProceduresRouteArgs {
  const ObstetricsGynaeProceduresRouteArgs({this.key, this.patientId});

  final _i180.Key? key;

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
/// [_i124.ObstetricsLabourDeliveryTab]
class ObstetricsLabourDeliveryTab
    extends _i179.PageRouteInfo<ObstetricsLabourDeliveryTabArgs> {
  ObstetricsLabourDeliveryTab({
    _i180.Key? key,
    String? pregnancyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsLabourDeliveryTab.name,
         args: ObstetricsLabourDeliveryTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsLabourDeliveryTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsLabourDeliveryTabArgs>(
        orElse: () => const ObstetricsLabourDeliveryTabArgs(),
      );
      return _i124.ObstetricsLabourDeliveryTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsLabourDeliveryTabArgs {
  const ObstetricsLabourDeliveryTabArgs({this.key, this.pregnancyId});

  final _i180.Key? key;

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
/// [_i125.ObstetricsLabourDeliveryViewScreen]
class ObstetricsLabourDeliveryViewRoute
    extends _i179.PageRouteInfo<ObstetricsLabourDeliveryViewRouteArgs> {
  ObstetricsLabourDeliveryViewRoute({
    _i180.Key? key,
    required String labourDeliveryId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsLabourDeliveryViewRoute.name,
         args: ObstetricsLabourDeliveryViewRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsLabourDeliveryViewRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsLabourDeliveryViewRouteArgs>();
      return _i125.ObstetricsLabourDeliveryViewScreen(
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

  final _i180.Key? key;

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
/// [_i126.ObstetricsPatientSelectScreen]
class ObstetricsPatientSelectRoute extends _i179.PageRouteInfo<void> {
  const ObstetricsPatientSelectRoute({List<_i179.PageRouteInfo>? children})
    : super(ObstetricsPatientSelectRoute.name, initialChildren: children);

  static const String name = 'ObstetricsPatientSelectRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i126.ObstetricsPatientSelectScreen();
    },
  );
}

/// generated route for
/// [_i127.ObstetricsPostnatalListScreen]
class ObstetricsPostnatalListRoute
    extends _i179.PageRouteInfo<ObstetricsPostnatalListRouteArgs> {
  ObstetricsPostnatalListRoute({
    _i180.Key? key,
    String? labourDeliveryId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsPostnatalListRoute.name,
         args: ObstetricsPostnatalListRouteArgs(
           key: key,
           labourDeliveryId: labourDeliveryId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPostnatalListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPostnatalListRouteArgs>(
        orElse: () => const ObstetricsPostnatalListRouteArgs(),
      );
      return _i127.ObstetricsPostnatalListScreen(
        key: args.key,
        labourDeliveryId: args.labourDeliveryId,
      );
    },
  );
}

class ObstetricsPostnatalListRouteArgs {
  const ObstetricsPostnatalListRouteArgs({this.key, this.labourDeliveryId});

  final _i180.Key? key;

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
/// [_i128.ObstetricsPostnatalTab]
class ObstetricsPostnatalTab
    extends _i179.PageRouteInfo<ObstetricsPostnatalTabArgs> {
  ObstetricsPostnatalTab({
    _i180.Key? key,
    String? pregnancyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsPostnatalTab.name,
         args: ObstetricsPostnatalTabArgs(key: key, pregnancyId: pregnancyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPostnatalTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPostnatalTabArgs>(
        orElse: () => const ObstetricsPostnatalTabArgs(),
      );
      return _i128.ObstetricsPostnatalTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsPostnatalTabArgs {
  const ObstetricsPostnatalTabArgs({this.key, this.pregnancyId});

  final _i180.Key? key;

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
/// [_i129.ObstetricsPregnanciesListScreen]
class ObstetricsPregnanciesListRoute
    extends _i179.PageRouteInfo<ObstetricsPregnanciesListRouteArgs> {
  ObstetricsPregnanciesListRoute({
    _i180.Key? key,
    String? patientId,
    String? encounterId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnanciesListRoute.name,
         args: ObstetricsPregnanciesListRouteArgs(
           key: key,
           patientId: patientId,
           encounterId: encounterId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnanciesListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnanciesListRouteArgs>(
        orElse: () => const ObstetricsPregnanciesListRouteArgs(),
      );
      return _i129.ObstetricsPregnanciesListScreen(
        key: args.key,
        patientId: args.patientId,
        encounterId: args.encounterId,
      );
    },
  );
}

class ObstetricsPregnanciesListRouteArgs {
  const ObstetricsPregnanciesListRouteArgs({
    this.key,
    this.patientId,
    this.encounterId,
  });

  final _i180.Key? key;

  final String? patientId;

  final String? encounterId;

  @override
  String toString() {
    return 'ObstetricsPregnanciesListRouteArgs{key: $key, patientId: $patientId, encounterId: $encounterId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPregnanciesListRouteArgs) return false;
    return key == other.key &&
        patientId == other.patientId &&
        encounterId == other.encounterId;
  }

  @override
  int get hashCode => key.hashCode ^ patientId.hashCode ^ encounterId.hashCode;
}

/// generated route for
/// [_i130.ObstetricsPregnancyOverviewTab]
class ObstetricsPregnancyOverviewTab
    extends _i179.PageRouteInfo<ObstetricsPregnancyOverviewTabArgs> {
  ObstetricsPregnancyOverviewTab({
    _i180.Key? key,
    String? pregnancyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnancyOverviewTab.name,
         args: ObstetricsPregnancyOverviewTabArgs(
           key: key,
           pregnancyId: pregnancyId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnancyOverviewTab';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnancyOverviewTabArgs>(
        orElse: () => const ObstetricsPregnancyOverviewTabArgs(),
      );
      return _i130.ObstetricsPregnancyOverviewTab(
        key: args.key,
        pregnancyId: args.pregnancyId,
      );
    },
  );
}

class ObstetricsPregnancyOverviewTabArgs {
  const ObstetricsPregnancyOverviewTabArgs({this.key, this.pregnancyId});

  final _i180.Key? key;

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
/// [_i131.ObstetricsPregnancyViewScreen]
class ObstetricsPregnancyViewRoute
    extends _i179.PageRouteInfo<ObstetricsPregnancyViewRouteArgs> {
  ObstetricsPregnancyViewRoute({
    _i180.Key? key,
    required String pregnancyId,
    String? encounterId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsPregnancyViewRoute.name,
         args: ObstetricsPregnancyViewRouteArgs(
           key: key,
           pregnancyId: pregnancyId,
           encounterId: encounterId,
         ),
         initialChildren: children,
       );

  static const String name = 'ObstetricsPregnancyViewRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsPregnancyViewRouteArgs>();
      return _i131.ObstetricsPregnancyViewScreen(
        key: args.key,
        pregnancyId: args.pregnancyId,
        encounterId: args.encounterId,
      );
    },
  );
}

class ObstetricsPregnancyViewRouteArgs {
  const ObstetricsPregnancyViewRouteArgs({
    this.key,
    required this.pregnancyId,
    this.encounterId,
  });

  final _i180.Key? key;

  final String pregnancyId;

  final String? encounterId;

  @override
  String toString() {
    return 'ObstetricsPregnancyViewRouteArgs{key: $key, pregnancyId: $pregnancyId, encounterId: $encounterId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ObstetricsPregnancyViewRouteArgs) return false;
    return key == other.key &&
        pregnancyId == other.pregnancyId &&
        encounterId == other.encounterId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ pregnancyId.hashCode ^ encounterId.hashCode;
}

/// generated route for
/// [_i132.ObstetricsRegisterBabyScreen]
class ObstetricsRegisterBabyRoute
    extends _i179.PageRouteInfo<ObstetricsRegisterBabyRouteArgs> {
  ObstetricsRegisterBabyRoute({
    _i180.Key? key,
    required String babyId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ObstetricsRegisterBabyRoute.name,
         args: ObstetricsRegisterBabyRouteArgs(key: key, babyId: babyId),
         initialChildren: children,
       );

  static const String name = 'ObstetricsRegisterBabyRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ObstetricsRegisterBabyRouteArgs>();
      return _i132.ObstetricsRegisterBabyScreen(
        key: args.key,
        babyId: args.babyId,
      );
    },
  );
}

class ObstetricsRegisterBabyRouteArgs {
  const ObstetricsRegisterBabyRouteArgs({this.key, required this.babyId});

  final _i180.Key? key;

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
/// [_i133.PatientBillingScreen]
class PatientBillingRoute extends _i179.PageRouteInfo<PatientBillingRouteArgs> {
  PatientBillingRoute({
    _i180.Key? key,
    required String invoiceId,
    String patientName = '',
    List<_i179.PageRouteInfo>? children,
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

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientBillingRouteArgs>();
      return _i133.PatientBillingScreen(
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

  final _i180.Key? key;

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
/// [_i134.PatientChartScreen]
class PatientChartRoute extends _i179.PageRouteInfo<PatientChartRouteArgs> {
  PatientChartRoute({
    _i180.Key? key,
    required String patientUuid,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         PatientChartRoute.name,
         args: PatientChartRouteArgs(key: key, patientUuid: patientUuid),
         initialChildren: children,
       );

  static const String name = 'PatientChartRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientChartRouteArgs>();
      return _i134.PatientChartScreen(
        key: args.key,
        patientUuid: args.patientUuid,
      );
    },
  );
}

class PatientChartRouteArgs {
  const PatientChartRouteArgs({this.key, required this.patientUuid});

  final _i180.Key? key;

  final String patientUuid;

  @override
  String toString() {
    return 'PatientChartRouteArgs{key: $key, patientUuid: $patientUuid}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PatientChartRouteArgs) return false;
    return key == other.key && patientUuid == other.patientUuid;
  }

  @override
  int get hashCode => key.hashCode ^ patientUuid.hashCode;
}

/// generated route for
/// [_i135.PatientChartSelectScreen]
class PatientChartSelectRoute extends _i179.PageRouteInfo<void> {
  const PatientChartSelectRoute({List<_i179.PageRouteInfo>? children})
    : super(PatientChartSelectRoute.name, initialChildren: children);

  static const String name = 'PatientChartSelectRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i135.PatientChartSelectScreen();
    },
  );
}

/// generated route for
/// [_i136.PatientFormScreen]
class PatientFormRoute extends _i179.PageRouteInfo<PatientFormRouteArgs> {
  PatientFormRoute({
    _i180.Key? key,
    _i185.Patient? patient,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         PatientFormRoute.name,
         args: PatientFormRouteArgs(key: key, patient: patient),
         initialChildren: children,
       );

  static const String name = 'PatientFormRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientFormRouteArgs>(
        orElse: () => const PatientFormRouteArgs(),
      );
      return _i136.PatientFormScreen(key: args.key, patient: args.patient);
    },
  );
}

class PatientFormRouteArgs {
  const PatientFormRouteArgs({this.key, this.patient});

  final _i180.Key? key;

  final _i185.Patient? patient;

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
/// [_i137.PatientListScreen]
class PatientListRoute extends _i179.PageRouteInfo<void> {
  const PatientListRoute({List<_i179.PageRouteInfo>? children})
    : super(PatientListRoute.name, initialChildren: children);

  static const String name = 'PatientListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i137.PatientListScreen();
    },
  );
}

/// generated route for
/// [_i138.PendingBillsScreen]
class PendingBillsRoute extends _i179.PageRouteInfo<void> {
  const PendingBillsRoute({List<_i179.PageRouteInfo>? children})
    : super(PendingBillsRoute.name, initialChildren: children);

  static const String name = 'PendingBillsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i138.PendingBillsScreen();
    },
  );
}

/// generated route for
/// [_i139.PendingTransactionsScreen]
class PendingTransactionsRoute extends _i179.PageRouteInfo<void> {
  const PendingTransactionsRoute({List<_i179.PageRouteInfo>? children})
    : super(PendingTransactionsRoute.name, initialChildren: children);

  static const String name = 'PendingTransactionsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i139.PendingTransactionsScreen();
    },
  );
}

/// generated route for
/// [_i140.PharmacyDashboardScreen]
class PharmacyDashboardRoute extends _i179.PageRouteInfo<void> {
  const PharmacyDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(PharmacyDashboardRoute.name, initialChildren: children);

  static const String name = 'PharmacyDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i140.PharmacyDashboardScreen();
    },
  );
}

/// generated route for
/// [_i141.PharmacyLocationScreen]
class PharmacyLocationRoute extends _i179.PageRouteInfo<void> {
  const PharmacyLocationRoute({List<_i179.PageRouteInfo>? children})
    : super(PharmacyLocationRoute.name, initialChildren: children);

  static const String name = 'PharmacyLocationRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i141.PharmacyLocationScreen();
    },
  );
}

/// generated route for
/// [_i142.PharmacyPOSScreen]
class PharmacyPOSRoute extends _i179.PageRouteInfo<void> {
  const PharmacyPOSRoute({List<_i179.PageRouteInfo>? children})
    : super(PharmacyPOSRoute.name, initialChildren: children);

  static const String name = 'PharmacyPOSRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i142.PharmacyPOSScreen();
    },
  );
}

/// generated route for
/// [_i143.RadiologyCreateRequestScreen]
class RadiologyCreateRequestRoute
    extends _i179.PageRouteInfo<RadiologyCreateRequestRouteArgs> {
  RadiologyCreateRequestRoute({
    _i180.Key? key,
    String? patientId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         RadiologyCreateRequestRoute.name,
         args: RadiologyCreateRequestRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'RadiologyCreateRequestRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyCreateRequestRouteArgs>(
        orElse: () => const RadiologyCreateRequestRouteArgs(),
      );
      return _i143.RadiologyCreateRequestScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class RadiologyCreateRequestRouteArgs {
  const RadiologyCreateRequestRouteArgs({this.key, this.patientId});

  final _i180.Key? key;

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
/// [_i144.RadiologyDashboardScreen]
class RadiologyDashboardRoute extends _i179.PageRouteInfo<void> {
  const RadiologyDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(RadiologyDashboardRoute.name, initialChildren: children);

  static const String name = 'RadiologyDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i144.RadiologyDashboardScreen();
    },
  );
}

/// generated route for
/// [_i145.RadiologyPatientHistoryScreen]
class RadiologyPatientHistoryRoute
    extends _i179.PageRouteInfo<RadiologyPatientHistoryRouteArgs> {
  RadiologyPatientHistoryRoute({
    _i180.Key? key,
    required String patientId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         RadiologyPatientHistoryRoute.name,
         args: RadiologyPatientHistoryRouteArgs(key: key, patientId: patientId),
         initialChildren: children,
       );

  static const String name = 'RadiologyPatientHistoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyPatientHistoryRouteArgs>();
      return _i145.RadiologyPatientHistoryScreen(
        key: args.key,
        patientId: args.patientId,
      );
    },
  );
}

class RadiologyPatientHistoryRouteArgs {
  const RadiologyPatientHistoryRouteArgs({this.key, required this.patientId});

  final _i180.Key? key;

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
/// [_i146.RadiologyRequestDetailScreen]
class RadiologyRequestDetailRoute
    extends _i179.PageRouteInfo<RadiologyRequestDetailRouteArgs> {
  RadiologyRequestDetailRoute({
    _i180.Key? key,
    required String requestId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         RadiologyRequestDetailRoute.name,
         args: RadiologyRequestDetailRouteArgs(key: key, requestId: requestId),
         initialChildren: children,
       );

  static const String name = 'RadiologyRequestDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RadiologyRequestDetailRouteArgs>();
      return _i146.RadiologyRequestDetailScreen(
        key: args.key,
        requestId: args.requestId,
      );
    },
  );
}

class RadiologyRequestDetailRouteArgs {
  const RadiologyRequestDetailRouteArgs({this.key, required this.requestId});

  final _i180.Key? key;

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
/// [_i147.RadiologyWorklistScreen]
class RadiologyWorklistRoute extends _i179.PageRouteInfo<void> {
  const RadiologyWorklistRoute({List<_i179.PageRouteInfo>? children})
    : super(RadiologyWorklistRoute.name, initialChildren: children);

  static const String name = 'RadiologyWorklistRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i147.RadiologyWorklistScreen();
    },
  );
}

/// generated route for
/// [_i148.ReceivablesAnalyticsScreen]
class ReceivablesAnalyticsRoute extends _i179.PageRouteInfo<void> {
  const ReceivablesAnalyticsRoute({List<_i179.PageRouteInfo>? children})
    : super(ReceivablesAnalyticsRoute.name, initialChildren: children);

  static const String name = 'ReceivablesAnalyticsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i148.ReceivablesAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i149.ReceivablesDiscountScreen]
class ReceivablesDiscountRoute extends _i179.PageRouteInfo<void> {
  const ReceivablesDiscountRoute({List<_i179.PageRouteInfo>? children})
    : super(ReceivablesDiscountRoute.name, initialChildren: children);

  static const String name = 'ReceivablesDiscountRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i149.ReceivablesDiscountScreen();
    },
  );
}

/// generated route for
/// [_i149.ReceivablesHmoScreen]
class ReceivablesHmoRoute extends _i179.PageRouteInfo<void> {
  const ReceivablesHmoRoute({List<_i179.PageRouteInfo>? children})
    : super(ReceivablesHmoRoute.name, initialChildren: children);

  static const String name = 'ReceivablesHmoRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i149.ReceivablesHmoScreen();
    },
  );
}

/// generated route for
/// [_i150.RegisterScreen]
class RegisterRoute extends _i179.PageRouteInfo<void> {
  const RegisterRoute({List<_i179.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i150.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i151.RenderServiceScreen]
class RenderServiceRoute extends _i179.PageRouteInfo<void> {
  const RenderServiceRoute({List<_i179.PageRouteInfo>? children})
    : super(RenderServiceRoute.name, initialChildren: children);

  static const String name = 'RenderServiceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i151.RenderServiceScreen();
    },
  );
}

/// generated route for
/// [_i152.ResetPasswordScreen]
class ResetPasswordRoute extends _i179.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i180.Key? key,
    String? email,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, email: email),
         rawQueryParams: {'email': email},
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ResetPasswordRouteArgs>(
        orElse: () =>
            ResetPasswordRouteArgs(email: queryParams.optString('email')),
      );
      return _i152.ResetPasswordScreen(key: args.key, email: args.email);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, this.email});

  final _i180.Key? key;

  final String? email;

  @override
  String toString() {
    return 'ResetPasswordRouteArgs{key: $key, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResetPasswordRouteArgs) return false;
    return key == other.key && email == other.email;
  }

  @override
  int get hashCode => key.hashCode ^ email.hashCode;
}

/// generated route for
/// [_i153.StaffChatScreen]
class StaffChatRoute extends _i179.PageRouteInfo<void> {
  const StaffChatRoute({List<_i179.PageRouteInfo>? children})
    : super(StaffChatRoute.name, initialChildren: children);

  static const String name = 'StaffChatRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i153.StaffChatScreen();
    },
  );
}

/// generated route for
/// [_i154.StaffChatThreadScreen]
class StaffChatThreadRoute
    extends _i179.PageRouteInfo<StaffChatThreadRouteArgs> {
  StaffChatThreadRoute({
    _i180.Key? key,
    required String conversationId,
    String? title,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         StaffChatThreadRoute.name,
         args: StaffChatThreadRouteArgs(
           key: key,
           conversationId: conversationId,
           title: title,
         ),
         initialChildren: children,
       );

  static const String name = 'StaffChatThreadRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StaffChatThreadRouteArgs>();
      return _i154.StaffChatThreadScreen(
        key: args.key,
        conversationId: args.conversationId,
        title: args.title,
      );
    },
  );
}

class StaffChatThreadRouteArgs {
  const StaffChatThreadRouteArgs({
    this.key,
    required this.conversationId,
    this.title,
  });

  final _i180.Key? key;

  final String conversationId;

  final String? title;

  @override
  String toString() {
    return 'StaffChatThreadRouteArgs{key: $key, conversationId: $conversationId, title: $title}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffChatThreadRouteArgs) return false;
    return key == other.key &&
        conversationId == other.conversationId &&
        title == other.title;
  }

  @override
  int get hashCode => key.hashCode ^ conversationId.hashCode ^ title.hashCode;
}

/// generated route for
/// [_i155.StockTransferScreen]
class StockTransferRoute extends _i179.PageRouteInfo<void> {
  const StockTransferRoute({List<_i179.PageRouteInfo>? children})
    : super(StockTransferRoute.name, initialChildren: children);

  static const String name = 'StockTransferRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i155.StockTransferScreen();
    },
  );
}

/// generated route for
/// [_i156.StoreAnalyticsScreen]
class StoreAnalyticsRoute extends _i179.PageRouteInfo<void> {
  const StoreAnalyticsRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreAnalyticsRoute.name, initialChildren: children);

  static const String name = 'StoreAnalyticsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i156.StoreAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i157.StoreCategoriesScreen]
class StoreCategoriesRoute extends _i179.PageRouteInfo<void> {
  const StoreCategoriesRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreCategoriesRoute.name, initialChildren: children);

  static const String name = 'StoreCategoriesRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i157.StoreCategoriesScreen();
    },
  );
}

/// generated route for
/// [_i158.StoreConsumableAnalyticsScreen]
class StoreConsumableAnalyticsRoute extends _i179.PageRouteInfo<void> {
  const StoreConsumableAnalyticsRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreConsumableAnalyticsRoute.name, initialChildren: children);

  static const String name = 'StoreConsumableAnalyticsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i158.StoreConsumableAnalyticsScreen();
    },
  );
}

/// generated route for
/// [_i159.StoreConsumableDetailScreen]
class StoreConsumableDetailRoute
    extends _i179.PageRouteInfo<StoreConsumableDetailRouteArgs> {
  StoreConsumableDetailRoute({
    _i180.Key? key,
    required String consumableId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         StoreConsumableDetailRoute.name,
         args: StoreConsumableDetailRouteArgs(
           key: key,
           consumableId: consumableId,
         ),
         rawPathParams: {'consumableId': consumableId},
         initialChildren: children,
       );

  static const String name = 'StoreConsumableDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StoreConsumableDetailRouteArgs>(
        orElse: () => StoreConsumableDetailRouteArgs(
          consumableId: pathParams.getString('consumableId'),
        ),
      );
      return _i159.StoreConsumableDetailScreen(
        key: args.key,
        consumableId: args.consumableId,
      );
    },
  );
}

class StoreConsumableDetailRouteArgs {
  const StoreConsumableDetailRouteArgs({this.key, required this.consumableId});

  final _i180.Key? key;

  final String consumableId;

  @override
  String toString() {
    return 'StoreConsumableDetailRouteArgs{key: $key, consumableId: $consumableId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StoreConsumableDetailRouteArgs) return false;
    return key == other.key && consumableId == other.consumableId;
  }

  @override
  int get hashCode => key.hashCode ^ consumableId.hashCode;
}

/// generated route for
/// [_i160.StoreConsumablesCatalogScreen]
class StoreConsumablesCatalogRoute extends _i179.PageRouteInfo<void> {
  const StoreConsumablesCatalogRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreConsumablesCatalogRoute.name, initialChildren: children);

  static const String name = 'StoreConsumablesCatalogRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i160.StoreConsumablesCatalogScreen();
    },
  );
}

/// generated route for
/// [_i161.StoreDashboardScreen]
class StoreDashboardRoute extends _i179.PageRouteInfo<void> {
  const StoreDashboardRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreDashboardRoute.name, initialChildren: children);

  static const String name = 'StoreDashboardRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i161.StoreDashboardScreen();
    },
  );
}

/// generated route for
/// [_i162.StoreItemsScreen]
class StoreItemsRoute extends _i179.PageRouteInfo<void> {
  const StoreItemsRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreItemsRoute.name, initialChildren: children);

  static const String name = 'StoreItemsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i162.StoreItemsScreen();
    },
  );
}

/// generated route for
/// [_i163.StoreLocationsScreen]
class StoreLocationsRoute extends _i179.PageRouteInfo<void> {
  const StoreLocationsRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreLocationsRoute.name, initialChildren: children);

  static const String name = 'StoreLocationsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i163.StoreLocationsScreen();
    },
  );
}

/// generated route for
/// [_i164.StoreMovementsScreen]
class StoreMovementsRoute extends _i179.PageRouteInfo<void> {
  const StoreMovementsRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreMovementsRoute.name, initialChildren: children);

  static const String name = 'StoreMovementsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i164.StoreMovementsScreen();
    },
  );
}

/// generated route for
/// [_i165.StoreStockScreen]
class StoreStockRoute extends _i179.PageRouteInfo<void> {
  const StoreStockRoute({List<_i179.PageRouteInfo>? children})
    : super(StoreStockRoute.name, initialChildren: children);

  static const String name = 'StoreStockRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i165.StoreStockScreen();
    },
  );
}

/// generated route for
/// [_i166.SuperAdminHubScreen]
class SuperAdminHubRoute extends _i179.PageRouteInfo<void> {
  const SuperAdminHubRoute({List<_i179.PageRouteInfo>? children})
    : super(SuperAdminHubRoute.name, initialChildren: children);

  static const String name = 'SuperAdminHubRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i166.SuperAdminHubScreen();
    },
  );
}

/// generated route for
/// [_i167.SuperAdminStaffDetailScreen]
class SuperAdminStaffDetailRoute
    extends _i179.PageRouteInfo<SuperAdminStaffDetailRouteArgs> {
  SuperAdminStaffDetailRoute({
    _i180.Key? key,
    required String staffId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         SuperAdminStaffDetailRoute.name,
         args: SuperAdminStaffDetailRouteArgs(key: key, staffId: staffId),
         initialChildren: children,
       );

  static const String name = 'SuperAdminStaffDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SuperAdminStaffDetailRouteArgs>();
      return _i167.SuperAdminStaffDetailScreen(
        key: args.key,
        staffId: args.staffId,
      );
    },
  );
}

class SuperAdminStaffDetailRouteArgs {
  const SuperAdminStaffDetailRouteArgs({this.key, required this.staffId});

  final _i180.Key? key;

  final String staffId;

  @override
  String toString() {
    return 'SuperAdminStaffDetailRouteArgs{key: $key, staffId: $staffId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SuperAdminStaffDetailRouteArgs) return false;
    return key == other.key && staffId == other.staffId;
  }

  @override
  int get hashCode => key.hashCode ^ staffId.hashCode;
}

/// generated route for
/// [_i168.SuperAdminStaffListScreen]
class SuperAdminStaffListRoute extends _i179.PageRouteInfo<void> {
  const SuperAdminStaffListRoute({List<_i179.PageRouteInfo>? children})
    : super(SuperAdminStaffListRoute.name, initialChildren: children);

  static const String name = 'SuperAdminStaffListRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i168.SuperAdminStaffListScreen();
    },
  );
}

/// generated route for
/// [_i169.SupplyHistoryScreen]
class SupplyHistoryRoute extends _i179.PageRouteInfo<void> {
  const SupplyHistoryRoute({List<_i179.PageRouteInfo>? children})
    : super(SupplyHistoryRoute.name, initialChildren: children);

  static const String name = 'SupplyHistoryRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i169.SupplyHistoryScreen();
    },
  );
}

/// generated route for
/// [_i170.SupportTicketDetailScreen]
class SupportTicketDetailRoute
    extends _i179.PageRouteInfo<SupportTicketDetailRouteArgs> {
  SupportTicketDetailRoute({
    _i180.Key? key,
    required String ticketId,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         SupportTicketDetailRoute.name,
         args: SupportTicketDetailRouteArgs(key: key, ticketId: ticketId),
         initialChildren: children,
       );

  static const String name = 'SupportTicketDetailRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SupportTicketDetailRouteArgs>();
      return _i170.SupportTicketDetailScreen(
        key: args.key,
        ticketId: args.ticketId,
      );
    },
  );
}

class SupportTicketDetailRouteArgs {
  const SupportTicketDetailRouteArgs({this.key, required this.ticketId});

  final _i180.Key? key;

  final String ticketId;

  @override
  String toString() {
    return 'SupportTicketDetailRouteArgs{key: $key, ticketId: $ticketId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SupportTicketDetailRouteArgs) return false;
    return key == other.key && ticketId == other.ticketId;
  }

  @override
  int get hashCode => key.hashCode ^ ticketId.hashCode;
}

/// generated route for
/// [_i171.SystemSetupScreen]
class SystemSetupRoute extends _i179.PageRouteInfo<void> {
  const SystemSetupRoute({List<_i179.PageRouteInfo>? children})
    : super(SystemSetupRoute.name, initialChildren: children);

  static const String name = 'SystemSetupRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i171.SystemSetupScreen();
    },
  );
}

/// generated route for
/// [_i172.TodayPatientsScreen]
class TodayPatientsRoute extends _i179.PageRouteInfo<void> {
  const TodayPatientsRoute({List<_i179.PageRouteInfo>? children})
    : super(TodayPatientsRoute.name, initialChildren: children);

  static const String name = 'TodayPatientsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i172.TodayPatientsScreen();
    },
  );
}

/// generated route for
/// [_i173.TransactionsScreen]
class TransactionsRoute extends _i179.PageRouteInfo<void> {
  const TransactionsRoute({List<_i179.PageRouteInfo>? children})
    : super(TransactionsRoute.name, initialChildren: children);

  static const String name = 'TransactionsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i173.TransactionsScreen();
    },
  );
}

/// generated route for
/// [_i174.ViewServiceScreen]
class ViewServiceRoute extends _i179.PageRouteInfo<void> {
  const ViewServiceRoute({List<_i179.PageRouteInfo>? children})
    : super(ViewServiceRoute.name, initialChildren: children);

  static const String name = 'ViewServiceRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i174.ViewServiceScreen();
    },
  );
}

/// generated route for
/// [_i175.WaitingPatientScreen]
class WaitingPatientRoute extends _i179.PageRouteInfo<WaitingPatientRouteArgs> {
  WaitingPatientRoute({
    _i180.Key? key,
    _i186.IPharmacyQueueService? queueService,
    List<_i179.PageRouteInfo>? children,
  }) : super(
         WaitingPatientRoute.name,
         args: WaitingPatientRouteArgs(key: key, queueService: queueService),
         initialChildren: children,
       );

  static const String name = 'WaitingPatientRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WaitingPatientRouteArgs>(
        orElse: () => const WaitingPatientRouteArgs(),
      );
      return _i175.WaitingPatientScreen(
        key: args.key,
        queueService: args.queueService,
      );
    },
  );
}

class WaitingPatientRouteArgs {
  const WaitingPatientRouteArgs({this.key, this.queueService});

  final _i180.Key? key;

  final _i186.IPharmacyQueueService? queueService;

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
/// [_i176.WaitingPatientsScreen]
class WaitingPatientsRoute extends _i179.PageRouteInfo<void> {
  const WaitingPatientsRoute({List<_i179.PageRouteInfo>? children})
    : super(WaitingPatientsRoute.name, initialChildren: children);

  static const String name = 'WaitingPatientsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i176.WaitingPatientsScreen();
    },
  );
}

/// generated route for
/// [_i177.WardManagementScreen]
class WardManagementRoute extends _i179.PageRouteInfo<void> {
  const WardManagementRoute({List<_i179.PageRouteInfo>? children})
    : super(WardManagementRoute.name, initialChildren: children);

  static const String name = 'WardManagementRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i177.WardManagementScreen();
    },
  );
}

/// generated route for
/// [_i178.WardRoundsScreen]
class WardRoundsRoute extends _i179.PageRouteInfo<void> {
  const WardRoundsRoute({List<_i179.PageRouteInfo>? children})
    : super(WardRoundsRoute.name, initialChildren: children);

  static const String name = 'WardRoundsRoute';

  static _i179.PageInfo page = _i179.PageInfo(
    name,
    builder: (data) {
      return const _i178.WardRoundsScreen();
    },
  );
}
