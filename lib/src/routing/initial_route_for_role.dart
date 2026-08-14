import 'package:auto_route/auto_route.dart';

import '../../app_router.gr.dart';
import '../app/product_definition.dart';
import '../app/product_module_access.dart';
import '../models/staff_model.dart';

/// First child route under [HomeRoute] after login, matching department role.
PageRouteInfo initialRouteForRole(String role, String accountType) {
  final at = accountType.toLowerCase();
  final r = role.toUpperCase();

  if (at == 'super_admin' || at == 'admin') {
    if (!ProductModuleAccess.isModuleEnabled(AppModule.administration)) {
      return const SuperAdminStaffListRoute();
    }
  }

  final blocked = _landingBlockedByProduct(at, r);
  if (blocked) {
    return ProductModuleAccess.fallbackInitialRoute();
  }

  switch (at) {
    case 'front_desk':
    case 'frontdesk':
    case 'medical_records':
      return const FrontDeskDashboardRoute();
    case 'billing':
    case 'bills':
      return staffCanAccessPrivilegedBillingStrings(role, accountType)
          ? const BillingDashboardRoute()
          : const PendingBillsRoute();
    case 'hmo':
      return EnlistPaitientRoute(serviceName: 'OPD');
    case 'nurse':
    case 'head_nurse':
    case 'matron':
    case 'ward_charge_nurse':
    case 'icu_charge_nurse':
    case 'emergency_charge_nurse':
    case 'opd_charge_nurse':
    case 'ong_charge_nurse':
    case 'inpatient_nurse':
    case 'outpatient_nurse':
      return const NursesDashboardRoute();
    case 'pharmacy_head':
      return const PharmacyHeadDashboardRoute();
    case 'pharmacy':
    case 'pharmacy_store':
      if (r == 'PHARMACY_DISPENSARY' || at == 'pharmacy_dispensary') {
        return EnlistPaitientRoute(serviceName: 'Pharmacy');
      }
      if (r == 'PHARMACY_HEAD') {
        return const PharmacyHeadDashboardRoute();
      }
      return const MedicineInventoryRoute();
    case 'pharmacy_dispensary':
      return EnlistPaitientRoute(serviceName: 'Pharmacy');
    case 'purchases':
    case 'purchases_store':
    case 'purchases_head':
      return const PurchasesDashboardRoute();
    case 'physician':
    case 'consultant':
    case 'inpatient_doctor':
      return const DoctorOutpatientListRoute();
    case 'laboratory':
    case 'lab':
      return const LabDashboardRoute();
    case 'radiology':
      return const RadiologyDashboardRoute();
    case 'dialysis':
      return const DialysisDashboardRoute();
    case 'theatre':
      return const TheatreDashboardRoute();
    case 'store':
      return const StoreDashboardRoute();
    case 'accounting':
    case 'accounts':
      return const AccountsDashboardRoute();
    case 'ict':
      return const DashboardRoute();
    case 'cmac':
      return const CmacOverviewRoute();
    case 'cmd':
      return const CmacOverviewRoute();
    case 'super_admin':
      return const CMDDashboardRoute();
    case 'admin':
      return const CMDDashboardRoute();
    default:
      if (r == 'DIALYSIS_HEAD' ||
          r == 'DIALYSIS_NURSE' ||
          r == 'DIALYSIS_TECH' ||
          r == 'DIALYSIS_TECHNICIAN' ||
          r == 'DIALYSIS_RECEPTIONIST') {
        return const DialysisDashboardRoute();
      }
      if (r == 'THEATRE' ||
          r == 'THEATRE_HEAD' ||
          r == 'THEATRE_NURSE' ||
          r == 'THEATRE_SCRUB' ||
          r == 'THEATRE_ANAESTHETIST' ||
          r == 'THEATRE_RECEPTIONIST') {
        return const TheatreDashboardRoute();
      }
      return const FrontDeskDashboardRoute();
  }
}

bool _landingBlockedByProduct(String accountType, String roleUpper) {
  var module = ProductModuleAccess.moduleForAccountType(accountType);
  if (module == null) {
    if (roleUpper == 'DIALYSIS_HEAD' ||
        roleUpper == 'DIALYSIS_NURSE' ||
        roleUpper == 'DIALYSIS_TECH' ||
        roleUpper == 'DIALYSIS_TECHNICIAN' ||
        roleUpper == 'DIALYSIS_RECEPTIONIST') {
      module = AppModule.dialysis;
    } else if (roleUpper == 'THEATRE' ||
        roleUpper == 'THEATRE_HEAD' ||
        roleUpper == 'THEATRE_NURSE' ||
        roleUpper == 'THEATRE_SCRUB' ||
        roleUpper == 'THEATRE_ANAESTHETIST' ||
        roleUpper == 'THEATRE_RECEPTIONIST') {
      module = AppModule.theatre;
    }
  }

  if (module == null) {
    // Unknown account types keep hospital default landing; elsewhere fall back.
    return !ProductModuleAccess.isAccountTypeAllowedForProduct(accountType);
  }
  return !ProductModuleAccess.isModuleEnabled(module);
}
