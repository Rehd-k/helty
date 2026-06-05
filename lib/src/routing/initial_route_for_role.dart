import 'package:auto_route/auto_route.dart';

import '../../app_router.gr.dart';
import '../models/staff_model.dart';

/// First child route under [HomeRoute] after login, matching department role.
PageRouteInfo initialRouteForRole(String role, String accountType) {
  final at = accountType.toLowerCase();
  final r = role.toUpperCase();

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
    case 'inpatient_nurse':
    case 'outpatient_nurse':
      return const NursesDashboardRoute();
    case 'pharmacy':
    case 'pharmacy_store':
    case 'pharmacy_head':
      if (r == 'PHARMACY_DISPENSARY' || at == 'pharmacy_dispensary') {
        return EnlistPaitientRoute(serviceName: 'Pharmacy');
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
    case 'store':
      return const StoreDashboardRoute();
    case 'accounting':
    case 'accounts':
    case 'ict':
      return const DashboardRoute();
    case 'cmac':
      return const CmacOverviewRoute();
    case 'cmd':
    case 'super_admin':
      return const CMDDashboardRoute();
    case 'admin':
      return const CMDDashboardRoute();
    default:
      return const FrontDeskDashboardRoute();
  }
}
