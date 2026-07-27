import 'package:auto_route/auto_route.dart';

import '../../app_router.gr.dart';
import 'product_definition.dart';
import 'product_environment.dart';

/// Maps staff account types and landing routes to [AppModule] capabilities.
class ProductModuleAccess {
  ProductModuleAccess._();

  static bool isModuleEnabled(AppModule module) =>
      ProductEnvironment.isModuleEnabled(module);

  /// Module required for a department [accountType] (canonical or alias).
  static AppModule? moduleForAccountType(String accountType) {
    final at = accountType.toLowerCase().trim();
    switch (at) {
      case 'front_desk':
      case 'frontdesk':
        return AppModule.registration;
      case 'medical_records':
        return AppModule.medicalRecords;
      case 'billing':
      case 'bills':
        return AppModule.billing;
      case 'hmo':
        return AppModule.hmo;
      case 'pharmacy':
      case 'pharmacy_store':
      case 'pharmacy_dispensary':
      case 'pharmacy_head':
        return AppModule.pharmacy;
      case 'purchases':
      case 'purchases_store':
      case 'purchases_head':
        return AppModule.purchases;
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
        return AppModule.nursing;
      case 'physician':
      case 'consultant':
      case 'inpatient_doctor':
        return AppModule.physician;
      case 'laboratory':
      case 'lab':
        return AppModule.laboratory;
      case 'radiology':
        return AppModule.radiology;
      case 'dialysis':
        return AppModule.dialysis;
      case 'theatre':
        return AppModule.theatre;
      case 'store':
        return AppModule.store;
      case 'accounting':
      case 'accounts':
        return AppModule.accounting;
      case 'ict':
        return AppModule.ict;
      case 'cmac':
      case 'cmd':
      case 'super_admin':
      case 'admin':
        return AppModule.administration;
      default:
        return null;
    }
  }

  static bool isAccountTypeAllowedForProduct(String accountType) {
    final module = moduleForAccountType(accountType);
    if (module == null) {
      // Unknown aliases: allow only on hospital so we do not open hospital-only
      // flows on smaller products by accident.
      return ProductEnvironment.currentProduct == AppProduct.hospital;
    }
    return isModuleEnabled(module);
  }

  /// First enabled-module dashboard when the role's natural landing is blocked.
  static PageRouteInfo fallbackInitialRoute() {
    final modules = ProductEnvironment.enabledModules;
    if (modules.contains(AppModule.registration)) {
      return const FrontDeskDashboardRoute();
    }
    if (modules.contains(AppModule.billing)) {
      return const BillingDashboardRoute();
    }
    if (modules.contains(AppModule.pharmacy)) {
      return const PharmacyDashboardRoute();
    }
    if (modules.contains(AppModule.laboratory)) {
      return const LabDashboardRoute();
    }
    if (modules.contains(AppModule.radiology)) {
      return const RadiologyDashboardRoute();
    }
    return const FrontDeskDashboardRoute();
  }
}
