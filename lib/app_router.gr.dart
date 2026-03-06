// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i75;
import 'package:collection/collection.dart' as _i79;
import 'package:flutter/material.dart' as _i76;
import 'package:helty/src/billings/dashboard.dart' as _i8;
import 'package:helty/src/billings/pending.bills.dart' as _i60;
import 'package:helty/src/cmd/consulting_rooms_screen.dart' as _i10;
import 'package:helty/src/cmd/dashboard.dart' as _i9;
import 'package:helty/src/doctor/completed/doctor_completed_encounters_screen.dart'
    as _i13;
import 'package:helty/src/doctor/dashboard/doctor_dashboard_screen.dart'
    as _i14;
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart'
    as _i25;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_admission_tab.dart'
    as _i15;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_diagnosis_tab.dart'
    as _i16;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_examination_tab.dart'
    as _i17;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_follow_up_tab.dart'
    as _i18;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_history_tab.dart'
    as _i19;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_imaging_tab.dart'
    as _i20;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_investigations_tab.dart'
    as _i21;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_notes_tab.dart'
    as _i22;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_prescription_tab.dart'
    as _i23;
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_procedures_tab.dart'
    as _i24;
import 'package:helty/src/doctor/outpatient/doctor_outpatient_list_screen.dart'
    as _i26;
import 'package:helty/src/doctor/pending/doctor_pending_imaging_screen.dart'
    as _i27;
import 'package:helty/src/doctor/pending/doctor_pending_labs_screen.dart'
    as _i28;
import 'package:helty/src/doctor/pending/doctor_pending_prescriptions_screen.dart'
    as _i29;
import 'package:helty/src/doctor/profile/doctor_profile_screen.dart' as _i30;
import 'package:helty/src/doctor/templates/doctor_templates_screen.dart'
    as _i31;
import 'package:helty/src/doctor/walk_in/doctor_walk_in_queue_screen.dart'
    as _i32;
import 'package:helty/src/enlist_services/enlist.paitient.dart' as _i33;
import 'package:helty/src/frontdesk/dashboard.dart' as _i36;
import 'package:helty/src/hospital_service/service_screen.dart' as _i70;
import 'package:helty/src/nurses/dashboard.dart' as _i57;
import 'package:helty/src/nurses/inpatients/inpatient_patient_view_screen.dart'
    as _i48;
import 'package:helty/src/nurses/inpatients/inpatients_list_screen.dart'
    as _i51;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_alerts_tab.dart'
    as _i38;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_care_plan_tab.dart'
    as _i39;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_handover_tab.dart'
    as _i40;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_io_tab.dart' as _i41;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_iv_tab.dart' as _i42;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_lab_results_tab.dart'
    as _i43;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_medications_tab.dart'
    as _i44;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_monitoring_tab.dart'
    as _i45;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_notes_tab.dart'
    as _i46;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_overview_tab.dart'
    as _i47;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_procedures_tab.dart'
    as _i49;
import 'package:helty/src/nurses/inpatients/tabs/inpatient_vitals_tab.dart'
    as _i50;
import 'package:helty/src/nurses/waiting_patients.dart' as _i74;
import 'package:helty/src/paitients/patient_form_screen.dart' as _i58;
import 'package:helty/src/paitients/patient_list_screen.dart' as _i59;
import 'package:helty/src/paitients/patient_model.dart' as _i80;
import 'package:helty/src/paitients/view_waiting_patient.dart' as _i55;
import 'package:helty/src/pharmacy/models/pharmacy_model.dart' as _i77;
import 'package:helty/src/pharmacy/services/pharmacy_service.dart' as _i78;
import 'package:helty/src/pharmacy/ui/add.batches.dart' as _i1;
import 'package:helty/src/pharmacy/ui/add_drug_screen.dart' as _i4;
import 'package:helty/src/pharmacy/ui/add_supplier_screen.dart' as _i6;
import 'package:helty/src/pharmacy/ui/create_requisition.dart' as _i11;
import 'package:helty/src/pharmacy/ui/dispensory.screen.dart' as _i63;
import 'package:helty/src/pharmacy/ui/location.screen.dart' as _i62;
import 'package:helty/src/pharmacy/ui/medicine_inventory.dart' as _i53;
import 'package:helty/src/pharmacy/ui/stock_transfer.dart' as _i68;
import 'package:helty/src/pharmacy/ui/suppliy.history.screen.dart' as _i69;
import 'package:helty/src/pharmacy/ui/waiting.patient.dart' as _i64;
import 'package:helty/src/transaction/transactions.screen.dart' as _i72;
import 'package:helty/src/ui/appointments/appointment_list_screen.dart' as _i7;
import 'package:helty/src/ui/appointments/create_appointment.dart' as _i54;
import 'package:helty/src/ui/auth/forgot_password_screen.dart' as _i35;
import 'package:helty/src/ui/auth/login_screen.dart' as _i52;
import 'package:helty/src/ui/auth/register_screen.dart' as _i65;
import 'package:helty/src/ui/auth/reset_password_screen.dart' as _i67;
import 'package:helty/src/ui/dashboard/dashboard_screen.dart' as _i12;
import 'package:helty/src/ui/home/home_screen.dart' as _i37;
import 'package:helty/src/ui/patients/today_patients.dart' as _i71;
import 'package:helty/src/ui/patinets_services/add_category_screen.dart' as _i2;
import 'package:helty/src/ui/patinets_services/add_department_screen.dart'
    as _i3;
import 'package:helty/src/ui/patinets_services/add_service_screen.dart' as _i5;
import 'package:helty/src/ui/patinets_services/enlist_service_screen.dart'
    as _i34;
import 'package:helty/src/ui/patinets_services/render_services.dart' as _i66;
import 'package:helty/src/ui/patinets_services/view_services.dart' as _i73;
import 'package:helty/src/ui/transactions/pending_transactions.dart' as _i61;
import 'package:helty/src/widgets/not_avaliable.dart' as _i56;

/// generated route for
/// [_i1.AddBatchScreen]
class AddBatchRoute extends _i75.PageRouteInfo<void> {
  const AddBatchRoute({List<_i75.PageRouteInfo>? children})
    : super(AddBatchRoute.name, initialChildren: children);

  static const String name = 'AddBatchRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddBatchScreen();
    },
  );
}

/// generated route for
/// [_i2.AddCategoryScreen]
class AddCategoryRoute extends _i75.PageRouteInfo<void> {
  const AddCategoryRoute({List<_i75.PageRouteInfo>? children})
    : super(AddCategoryRoute.name, initialChildren: children);

  static const String name = 'AddCategoryRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i2.AddCategoryScreen();
    },
  );
}

/// generated route for
/// [_i3.AddDepartmentScreen]
class AddDepartmentRoute extends _i75.PageRouteInfo<void> {
  const AddDepartmentRoute({List<_i75.PageRouteInfo>? children})
    : super(AddDepartmentRoute.name, initialChildren: children);

  static const String name = 'AddDepartmentRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddDepartmentScreen();
    },
  );
}

/// generated route for
/// [_i4.AddDrugScreen]
class AddDrugRoute extends _i75.PageRouteInfo<AddDrugRouteArgs> {
  AddDrugRoute({
    _i76.Key? key,
    _i77.Drug? existingDrug,
    _i78.PharmacyApiService? service,
    _i76.VoidCallback? onSaved,
    List<_i75.PageRouteInfo>? children,
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

  static _i75.PageInfo page = _i75.PageInfo(
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

  final _i76.Key? key;

  final _i77.Drug? existingDrug;

  final _i78.PharmacyApiService? service;

  final _i76.VoidCallback? onSaved;

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
class AddServiceRoute extends _i75.PageRouteInfo<void> {
  const AddServiceRoute({List<_i75.PageRouteInfo>? children})
    : super(AddServiceRoute.name, initialChildren: children);

  static const String name = 'AddServiceRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i5.AddServiceScreen();
    },
  );
}

/// generated route for
/// [_i6.AddSupplierScreen]
class AddSupplierRoute extends _i75.PageRouteInfo<void> {
  const AddSupplierRoute({List<_i75.PageRouteInfo>? children})
    : super(AddSupplierRoute.name, initialChildren: children);

  static const String name = 'AddSupplierRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i6.AddSupplierScreen();
    },
  );
}

/// generated route for
/// [_i7.AppointmentListScreen]
class AppointmentListRoute extends _i75.PageRouteInfo<void> {
  const AppointmentListRoute({List<_i75.PageRouteInfo>? children})
    : super(AppointmentListRoute.name, initialChildren: children);

  static const String name = 'AppointmentListRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i7.AppointmentListScreen();
    },
  );
}

/// generated route for
/// [_i8.BillingDashboardScreen]
class BillingDashboardRoute extends _i75.PageRouteInfo<void> {
  const BillingDashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(BillingDashboardRoute.name, initialChildren: children);

  static const String name = 'BillingDashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i8.BillingDashboardScreen();
    },
  );
}

/// generated route for
/// [_i9.CMDDashboardScreen]
class CMDDashboardRoute extends _i75.PageRouteInfo<void> {
  const CMDDashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(CMDDashboardRoute.name, initialChildren: children);

  static const String name = 'CMDDashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i9.CMDDashboardScreen();
    },
  );
}

/// generated route for
/// [_i10.ConsultingRoomsScreen]
class ConsultingRoomsRoute extends _i75.PageRouteInfo<void> {
  const ConsultingRoomsRoute({List<_i75.PageRouteInfo>? children})
    : super(ConsultingRoomsRoute.name, initialChildren: children);

  static const String name = 'ConsultingRoomsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i10.ConsultingRoomsScreen();
    },
  );
}

/// generated route for
/// [_i11.CreateRequisitionScreen]
class CreateRequisitionRoute extends _i75.PageRouteInfo<void> {
  const CreateRequisitionRoute({List<_i75.PageRouteInfo>? children})
    : super(CreateRequisitionRoute.name, initialChildren: children);

  static const String name = 'CreateRequisitionRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i11.CreateRequisitionScreen();
    },
  );
}

/// generated route for
/// [_i12.DashboardScreen]
class DashboardRoute extends _i75.PageRouteInfo<void> {
  const DashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i12.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i13.DoctorCompletedEncountersScreen]
class DoctorCompletedEncountersRoute extends _i75.PageRouteInfo<void> {
  const DoctorCompletedEncountersRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorCompletedEncountersRoute.name, initialChildren: children);

  static const String name = 'DoctorCompletedEncountersRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i13.DoctorCompletedEncountersScreen();
    },
  );
}

/// generated route for
/// [_i14.DoctorDashboardScreen]
class DoctorDashboardRoute extends _i75.PageRouteInfo<void> {
  const DoctorDashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorDashboardRoute.name, initialChildren: children);

  static const String name = 'DoctorDashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i14.DoctorDashboardScreen();
    },
  );
}

/// generated route for
/// [_i15.DoctorEncounterAdmissionTab]
class DoctorEncounterAdmissionTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterAdmissionTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterAdmissionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterAdmissionTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i15.DoctorEncounterAdmissionTab();
    },
  );
}

/// generated route for
/// [_i16.DoctorEncounterDiagnosisTab]
class DoctorEncounterDiagnosisTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterDiagnosisTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterDiagnosisTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterDiagnosisTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i16.DoctorEncounterDiagnosisTab();
    },
  );
}

/// generated route for
/// [_i17.DoctorEncounterExaminationTab]
class DoctorEncounterExaminationTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterExaminationTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterExaminationTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterExaminationTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i17.DoctorEncounterExaminationTab();
    },
  );
}

/// generated route for
/// [_i18.DoctorEncounterFollowUpTab]
class DoctorEncounterFollowUpTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterFollowUpTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterFollowUpTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterFollowUpTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i18.DoctorEncounterFollowUpTab();
    },
  );
}

/// generated route for
/// [_i19.DoctorEncounterHistoryTab]
class DoctorEncounterHistoryTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterHistoryTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterHistoryTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterHistoryTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i19.DoctorEncounterHistoryTab();
    },
  );
}

/// generated route for
/// [_i20.DoctorEncounterImagingTab]
class DoctorEncounterImagingTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterImagingTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterImagingTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterImagingTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i20.DoctorEncounterImagingTab();
    },
  );
}

/// generated route for
/// [_i21.DoctorEncounterInvestigationsTab]
class DoctorEncounterInvestigationsTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterInvestigationsTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterInvestigationsTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterInvestigationsTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i21.DoctorEncounterInvestigationsTab();
    },
  );
}

/// generated route for
/// [_i22.DoctorEncounterNotesTab]
class DoctorEncounterNotesTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterNotesTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterNotesTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterNotesTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i22.DoctorEncounterNotesTab();
    },
  );
}

/// generated route for
/// [_i23.DoctorEncounterPrescriptionTab]
class DoctorEncounterPrescriptionTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterPrescriptionTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterPrescriptionTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterPrescriptionTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i23.DoctorEncounterPrescriptionTab();
    },
  );
}

/// generated route for
/// [_i24.DoctorEncounterProceduresTab]
class DoctorEncounterProceduresTab extends _i75.PageRouteInfo<void> {
  const DoctorEncounterProceduresTab({List<_i75.PageRouteInfo>? children})
    : super(DoctorEncounterProceduresTab.name, initialChildren: children);

  static const String name = 'DoctorEncounterProceduresTab';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i24.DoctorEncounterProceduresTab();
    },
  );
}

/// generated route for
/// [_i25.DoctorEncounterViewScreen]
class DoctorEncounterViewRoute
    extends _i75.PageRouteInfo<DoctorEncounterViewRouteArgs> {
  DoctorEncounterViewRoute({
    _i76.Key? key,
    required String encounterId,
    required String patientId,
    String? patientVitalsJson,
    List<_i75.PageRouteInfo>? children,
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

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DoctorEncounterViewRouteArgs>();
      return _i25.DoctorEncounterViewScreen(
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

  final _i76.Key? key;

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
/// [_i26.DoctorOutpatientListScreen]
class DoctorOutpatientListRoute extends _i75.PageRouteInfo<void> {
  const DoctorOutpatientListRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorOutpatientListRoute.name, initialChildren: children);

  static const String name = 'DoctorOutpatientListRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i26.DoctorOutpatientListScreen();
    },
  );
}

/// generated route for
/// [_i27.DoctorPendingImagingScreen]
class DoctorPendingImagingRoute extends _i75.PageRouteInfo<void> {
  const DoctorPendingImagingRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorPendingImagingRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingImagingRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i27.DoctorPendingImagingScreen();
    },
  );
}

/// generated route for
/// [_i28.DoctorPendingLabsScreen]
class DoctorPendingLabsRoute extends _i75.PageRouteInfo<void> {
  const DoctorPendingLabsRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorPendingLabsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingLabsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i28.DoctorPendingLabsScreen();
    },
  );
}

/// generated route for
/// [_i29.DoctorPendingPrescriptionsScreen]
class DoctorPendingPrescriptionsRoute extends _i75.PageRouteInfo<void> {
  const DoctorPendingPrescriptionsRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorPendingPrescriptionsRoute.name, initialChildren: children);

  static const String name = 'DoctorPendingPrescriptionsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i29.DoctorPendingPrescriptionsScreen();
    },
  );
}

/// generated route for
/// [_i30.DoctorProfileScreen]
class DoctorProfileRoute extends _i75.PageRouteInfo<void> {
  const DoctorProfileRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorProfileRoute.name, initialChildren: children);

  static const String name = 'DoctorProfileRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i30.DoctorProfileScreen();
    },
  );
}

/// generated route for
/// [_i31.DoctorTemplatesScreen]
class DoctorTemplatesRoute extends _i75.PageRouteInfo<void> {
  const DoctorTemplatesRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorTemplatesRoute.name, initialChildren: children);

  static const String name = 'DoctorTemplatesRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i31.DoctorTemplatesScreen();
    },
  );
}

/// generated route for
/// [_i32.DoctorWalkInQueueScreen]
class DoctorWalkInQueueRoute extends _i75.PageRouteInfo<void> {
  const DoctorWalkInQueueRoute({List<_i75.PageRouteInfo>? children})
    : super(DoctorWalkInQueueRoute.name, initialChildren: children);

  static const String name = 'DoctorWalkInQueueRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i32.DoctorWalkInQueueScreen();
    },
  );
}

/// generated route for
/// [_i33.EnlistPaitientScreen]
class EnlistPaitientRoute extends _i75.PageRouteInfo<void> {
  const EnlistPaitientRoute({List<_i75.PageRouteInfo>? children})
    : super(EnlistPaitientRoute.name, initialChildren: children);

  static const String name = 'EnlistPaitientRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i33.EnlistPaitientScreen();
    },
  );
}

/// generated route for
/// [_i34.EnlistServiceScreen]
class EnlistServiceRoute extends _i75.PageRouteInfo<void> {
  const EnlistServiceRoute({List<_i75.PageRouteInfo>? children})
    : super(EnlistServiceRoute.name, initialChildren: children);

  static const String name = 'EnlistServiceRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i34.EnlistServiceScreen();
    },
  );
}

/// generated route for
/// [_i35.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i75.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i75.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i35.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i36.FrontDeskDashboardScreen]
class FrontDeskDashboardRoute extends _i75.PageRouteInfo<void> {
  const FrontDeskDashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(FrontDeskDashboardRoute.name, initialChildren: children);

  static const String name = 'FrontDeskDashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i36.FrontDeskDashboardScreen();
    },
  );
}

/// generated route for
/// [_i37.HomeScreen]
class HomeRoute extends _i75.PageRouteInfo<void> {
  const HomeRoute({List<_i75.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i37.HomeScreen();
    },
  );
}

/// generated route for
/// [_i38.InpatientAlertsScreen]
class InpatientAlertsRoute extends _i75.PageRouteInfo<void> {
  const InpatientAlertsRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientAlertsRoute.name, initialChildren: children);

  static const String name = 'InpatientAlertsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i38.InpatientAlertsScreen();
    },
  );
}

/// generated route for
/// [_i39.InpatientCarePlanScreen]
class InpatientCarePlanRoute extends _i75.PageRouteInfo<void> {
  const InpatientCarePlanRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientCarePlanRoute.name, initialChildren: children);

  static const String name = 'InpatientCarePlanRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i39.InpatientCarePlanScreen();
    },
  );
}

/// generated route for
/// [_i40.InpatientHandoverScreen]
class InpatientHandoverRoute extends _i75.PageRouteInfo<void> {
  const InpatientHandoverRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientHandoverRoute.name, initialChildren: children);

  static const String name = 'InpatientHandoverRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i40.InpatientHandoverScreen();
    },
  );
}

/// generated route for
/// [_i41.InpatientIOScreen]
class InpatientIORoute extends _i75.PageRouteInfo<void> {
  const InpatientIORoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientIORoute.name, initialChildren: children);

  static const String name = 'InpatientIORoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i41.InpatientIOScreen();
    },
  );
}

/// generated route for
/// [_i42.InpatientIVScreen]
class InpatientIVRoute extends _i75.PageRouteInfo<void> {
  const InpatientIVRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientIVRoute.name, initialChildren: children);

  static const String name = 'InpatientIVRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i42.InpatientIVScreen();
    },
  );
}

/// generated route for
/// [_i43.InpatientLabResultsScreen]
class InpatientLabResultsRoute extends _i75.PageRouteInfo<void> {
  const InpatientLabResultsRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientLabResultsRoute.name, initialChildren: children);

  static const String name = 'InpatientLabResultsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i43.InpatientLabResultsScreen();
    },
  );
}

/// generated route for
/// [_i44.InpatientMedicationsScreen]
class InpatientMedicationsRoute extends _i75.PageRouteInfo<void> {
  const InpatientMedicationsRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientMedicationsRoute.name, initialChildren: children);

  static const String name = 'InpatientMedicationsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i44.InpatientMedicationsScreen();
    },
  );
}

/// generated route for
/// [_i45.InpatientMonitoringScreen]
class InpatientMonitoringRoute extends _i75.PageRouteInfo<void> {
  const InpatientMonitoringRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientMonitoringRoute.name, initialChildren: children);

  static const String name = 'InpatientMonitoringRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i45.InpatientMonitoringScreen();
    },
  );
}

/// generated route for
/// [_i46.InpatientNotesScreen]
class InpatientNotesRoute extends _i75.PageRouteInfo<void> {
  const InpatientNotesRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientNotesRoute.name, initialChildren: children);

  static const String name = 'InpatientNotesRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i46.InpatientNotesScreen();
    },
  );
}

/// generated route for
/// [_i47.InpatientOverviewScreen]
class InpatientOverviewRoute extends _i75.PageRouteInfo<void> {
  const InpatientOverviewRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientOverviewRoute.name, initialChildren: children);

  static const String name = 'InpatientOverviewRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i47.InpatientOverviewScreen();
    },
  );
}

/// generated route for
/// [_i48.InpatientPatientViewScreen]
class InpatientPatientViewRoute
    extends _i75.PageRouteInfo<InpatientPatientViewRouteArgs> {
  InpatientPatientViewRoute({
    _i76.Key? key,
    required String patientId,
    String? admissionId,
    String? ward,
    String? bedNumber,
    String? attendingDoctor,
    String? diagnosis,
    DateTime? admissionDate,
    List<String>? allergies,
    String? codeStatus,
    List<String>? riskFlags,
    List<_i75.PageRouteInfo>? children,
  }) : super(
         InpatientPatientViewRoute.name,
         args: InpatientPatientViewRouteArgs(
           key: key,
           patientId: patientId,
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

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<InpatientPatientViewRouteArgs>();
      return _i48.InpatientPatientViewScreen(
        key: args.key,
        patientId: args.patientId,
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
    required this.patientId,
    this.admissionId,
    this.ward,
    this.bedNumber,
    this.attendingDoctor,
    this.diagnosis,
    this.admissionDate,
    this.allergies,
    this.codeStatus,
    this.riskFlags,
  });

  final _i76.Key? key;

  final String patientId;

  final String? admissionId;

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
    return 'InpatientPatientViewRouteArgs{key: $key, patientId: $patientId, admissionId: $admissionId, ward: $ward, bedNumber: $bedNumber, attendingDoctor: $attendingDoctor, diagnosis: $diagnosis, admissionDate: $admissionDate, allergies: $allergies, codeStatus: $codeStatus, riskFlags: $riskFlags}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InpatientPatientViewRouteArgs) return false;
    return key == other.key &&
        patientId == other.patientId &&
        admissionId == other.admissionId &&
        ward == other.ward &&
        bedNumber == other.bedNumber &&
        attendingDoctor == other.attendingDoctor &&
        diagnosis == other.diagnosis &&
        admissionDate == other.admissionDate &&
        const _i79.ListEquality<String>().equals(allergies, other.allergies) &&
        codeStatus == other.codeStatus &&
        const _i79.ListEquality<String>().equals(riskFlags, other.riskFlags);
  }

  @override
  int get hashCode =>
      key.hashCode ^
      patientId.hashCode ^
      admissionId.hashCode ^
      ward.hashCode ^
      bedNumber.hashCode ^
      attendingDoctor.hashCode ^
      diagnosis.hashCode ^
      admissionDate.hashCode ^
      const _i79.ListEquality<String>().hash(allergies) ^
      codeStatus.hashCode ^
      const _i79.ListEquality<String>().hash(riskFlags);
}

/// generated route for
/// [_i49.InpatientProceduresScreen]
class InpatientProceduresRoute extends _i75.PageRouteInfo<void> {
  const InpatientProceduresRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientProceduresRoute.name, initialChildren: children);

  static const String name = 'InpatientProceduresRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i49.InpatientProceduresScreen();
    },
  );
}

/// generated route for
/// [_i50.InpatientVitalsScreen]
class InpatientVitalsRoute extends _i75.PageRouteInfo<void> {
  const InpatientVitalsRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientVitalsRoute.name, initialChildren: children);

  static const String name = 'InpatientVitalsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i50.InpatientVitalsScreen();
    },
  );
}

/// generated route for
/// [_i51.InpatientsListScreen]
class InpatientsListRoute extends _i75.PageRouteInfo<void> {
  const InpatientsListRoute({List<_i75.PageRouteInfo>? children})
    : super(InpatientsListRoute.name, initialChildren: children);

  static const String name = 'InpatientsListRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i51.InpatientsListScreen();
    },
  );
}

/// generated route for
/// [_i52.LoginScreen]
class LoginRoute extends _i75.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i76.Key? key,
    String? redirectTo,
    List<_i75.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, redirectTo: redirectTo),
         rawQueryParams: {'redirectTo': redirectTo},
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(redirectTo: queryParams.optString('redirectTo')),
      );
      return _i52.LoginScreen(key: args.key, redirectTo: args.redirectTo);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.redirectTo});

  final _i76.Key? key;

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
/// [_i53.MedicineInventoryScreen]
class MedicineInventoryRoute extends _i75.PageRouteInfo<void> {
  const MedicineInventoryRoute({List<_i75.PageRouteInfo>? children})
    : super(MedicineInventoryRoute.name, initialChildren: children);

  static const String name = 'MedicineInventoryRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i53.MedicineInventoryScreen();
    },
  );
}

/// generated route for
/// [_i54.NewAppointmentScreen]
class NewAppointmentRoute extends _i75.PageRouteInfo<void> {
  const NewAppointmentRoute({List<_i75.PageRouteInfo>? children})
    : super(NewAppointmentRoute.name, initialChildren: children);

  static const String name = 'NewAppointmentRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i54.NewAppointmentScreen();
    },
  );
}

/// generated route for
/// [_i55.NewPatientScreen]
class NewPatientRoute extends _i75.PageRouteInfo<void> {
  const NewPatientRoute({List<_i75.PageRouteInfo>? children})
    : super(NewPatientRoute.name, initialChildren: children);

  static const String name = 'NewPatientRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i55.NewPatientScreen();
    },
  );
}

/// generated route for
/// [_i56.NotAvailableScreen]
class NotAvailableRoute extends _i75.PageRouteInfo<void> {
  const NotAvailableRoute({List<_i75.PageRouteInfo>? children})
    : super(NotAvailableRoute.name, initialChildren: children);

  static const String name = 'NotAvailableRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i56.NotAvailableScreen();
    },
  );
}

/// generated route for
/// [_i57.NursesDashboardScreen]
class NursesDashboardRoute extends _i75.PageRouteInfo<void> {
  const NursesDashboardRoute({List<_i75.PageRouteInfo>? children})
    : super(NursesDashboardRoute.name, initialChildren: children);

  static const String name = 'NursesDashboardRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i57.NursesDashboardScreen();
    },
  );
}

/// generated route for
/// [_i58.PatientFormScreen]
class PatientFormRoute extends _i75.PageRouteInfo<PatientFormRouteArgs> {
  PatientFormRoute({
    _i76.Key? key,
    _i80.Patient? patient,
    List<_i75.PageRouteInfo>? children,
  }) : super(
         PatientFormRoute.name,
         args: PatientFormRouteArgs(key: key, patient: patient),
         initialChildren: children,
       );

  static const String name = 'PatientFormRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientFormRouteArgs>(
        orElse: () => const PatientFormRouteArgs(),
      );
      return _i58.PatientFormScreen(key: args.key, patient: args.patient);
    },
  );
}

class PatientFormRouteArgs {
  const PatientFormRouteArgs({this.key, this.patient});

  final _i76.Key? key;

  final _i80.Patient? patient;

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
/// [_i59.PatientListScreen]
class PatientListRoute extends _i75.PageRouteInfo<void> {
  const PatientListRoute({List<_i75.PageRouteInfo>? children})
    : super(PatientListRoute.name, initialChildren: children);

  static const String name = 'PatientListRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i59.PatientListScreen();
    },
  );
}

/// generated route for
/// [_i60.PendingBillsScreen]
class PendingBillsRoute extends _i75.PageRouteInfo<void> {
  const PendingBillsRoute({List<_i75.PageRouteInfo>? children})
    : super(PendingBillsRoute.name, initialChildren: children);

  static const String name = 'PendingBillsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i60.PendingBillsScreen();
    },
  );
}

/// generated route for
/// [_i61.PendingTransactionsScreen]
class PendingTransactionsRoute extends _i75.PageRouteInfo<void> {
  const PendingTransactionsRoute({List<_i75.PageRouteInfo>? children})
    : super(PendingTransactionsRoute.name, initialChildren: children);

  static const String name = 'PendingTransactionsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i61.PendingTransactionsScreen();
    },
  );
}

/// generated route for
/// [_i62.PharmacyLocationScreen]
class PharmacyLocationRoute extends _i75.PageRouteInfo<void> {
  const PharmacyLocationRoute({List<_i75.PageRouteInfo>? children})
    : super(PharmacyLocationRoute.name, initialChildren: children);

  static const String name = 'PharmacyLocationRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i62.PharmacyLocationScreen();
    },
  );
}

/// generated route for
/// [_i63.PharmacyPOSScreen]
class PharmacyPOSRoute extends _i75.PageRouteInfo<void> {
  const PharmacyPOSRoute({List<_i75.PageRouteInfo>? children})
    : super(PharmacyPOSRoute.name, initialChildren: children);

  static const String name = 'PharmacyPOSRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i63.PharmacyPOSScreen();
    },
  );
}

/// generated route for
/// [_i64.PharmacyWaitingPatientScreen]
class PharmacyWaitingPatientRoute extends _i75.PageRouteInfo<void> {
  const PharmacyWaitingPatientRoute({List<_i75.PageRouteInfo>? children})
    : super(PharmacyWaitingPatientRoute.name, initialChildren: children);

  static const String name = 'PharmacyWaitingPatientRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i64.PharmacyWaitingPatientScreen();
    },
  );
}

/// generated route for
/// [_i65.RegisterScreen]
class RegisterRoute extends _i75.PageRouteInfo<void> {
  const RegisterRoute({List<_i75.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i65.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i66.RenderServiceScreen]
class RenderServiceRoute extends _i75.PageRouteInfo<void> {
  const RenderServiceRoute({List<_i75.PageRouteInfo>? children})
    : super(RenderServiceRoute.name, initialChildren: children);

  static const String name = 'RenderServiceRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i66.RenderServiceScreen();
    },
  );
}

/// generated route for
/// [_i67.ResetPasswordScreen]
class ResetPasswordRoute extends _i75.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i76.Key? key,
    String? token,
    List<_i75.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, token: token),
         rawQueryParams: {'token': token},
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ResetPasswordRouteArgs>(
        orElse: () =>
            ResetPasswordRouteArgs(token: queryParams.optString('token')),
      );
      return _i67.ResetPasswordScreen(key: args.key, token: args.token);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, this.token});

  final _i76.Key? key;

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
/// [_i68.StockTransferScreen]
class StockTransferRoute extends _i75.PageRouteInfo<void> {
  const StockTransferRoute({List<_i75.PageRouteInfo>? children})
    : super(StockTransferRoute.name, initialChildren: children);

  static const String name = 'StockTransferRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i68.StockTransferScreen();
    },
  );
}

/// generated route for
/// [_i69.SupplyHistoryScreen]
class SupplyHistoryRoute extends _i75.PageRouteInfo<void> {
  const SupplyHistoryRoute({List<_i75.PageRouteInfo>? children})
    : super(SupplyHistoryRoute.name, initialChildren: children);

  static const String name = 'SupplyHistoryRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i69.SupplyHistoryScreen();
    },
  );
}

/// generated route for
/// [_i70.SystemSetupScreen]
class SystemSetupRoute extends _i75.PageRouteInfo<void> {
  const SystemSetupRoute({List<_i75.PageRouteInfo>? children})
    : super(SystemSetupRoute.name, initialChildren: children);

  static const String name = 'SystemSetupRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i70.SystemSetupScreen();
    },
  );
}

/// generated route for
/// [_i71.TodayPatientsScreen]
class TodayPatientsRoute extends _i75.PageRouteInfo<void> {
  const TodayPatientsRoute({List<_i75.PageRouteInfo>? children})
    : super(TodayPatientsRoute.name, initialChildren: children);

  static const String name = 'TodayPatientsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i71.TodayPatientsScreen();
    },
  );
}

/// generated route for
/// [_i72.TransactionsScreen]
class TransactionsRoute extends _i75.PageRouteInfo<void> {
  const TransactionsRoute({List<_i75.PageRouteInfo>? children})
    : super(TransactionsRoute.name, initialChildren: children);

  static const String name = 'TransactionsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i72.TransactionsScreen();
    },
  );
}

/// generated route for
/// [_i73.ViewServiceScreen]
class ViewServiceRoute extends _i75.PageRouteInfo<void> {
  const ViewServiceRoute({List<_i75.PageRouteInfo>? children})
    : super(ViewServiceRoute.name, initialChildren: children);

  static const String name = 'ViewServiceRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i73.ViewServiceScreen();
    },
  );
}

/// generated route for
/// [_i74.WaitingPatientsScreen]
class WaitingPatientsRoute extends _i75.PageRouteInfo<void> {
  const WaitingPatientsRoute({List<_i75.PageRouteInfo>? children})
    : super(WaitingPatientsRoute.name, initialChildren: children);

  static const String name = 'WaitingPatientsRoute';

  static _i75.PageInfo page = _i75.PageInfo(
    name,
    builder: (data) {
      return const _i74.WaitingPatientsScreen();
    },
  );
}
