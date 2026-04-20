import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ModuleRequestFlowType { defaultBilling, radiology, laboratory, hmo }

class ModuleRequestFlowConfig {
  const ModuleRequestFlowConfig({
    required this.type,
    this.forcedCategoryNames = const [],
    this.hideServicePrices = false,
    this.sendToBillOnly = false,
  });

  final ModuleRequestFlowType type;
  final List<String> forcedCategoryNames;
  final bool hideServicePrices;
  final bool sendToBillOnly;

  bool get isModuleFlow =>
      type != ModuleRequestFlowType.defaultBilling &&
      type != ModuleRequestFlowType.hmo;

  static const defaultBilling = ModuleRequestFlowConfig(
    type: ModuleRequestFlowType.defaultBilling,
  );
}

class PaidInvoiceServiceLine {
  const PaidInvoiceServiceLine({
    required this.invoiceItemId,
    this.serviceId,
    required this.serviceName,
    required this.categoryName,
  });

  final String invoiceItemId;
  /// Catalog service UUID when the API sends it; optional for slim list payloads.
  final String? serviceId;
  final String serviceName;
  final String categoryName;
}

class PaidModuleRequestContext {
  const PaidModuleRequestContext({
    required this.moduleType,
    required this.patientId,
    required this.invoiceId,
    required this.invoiceDisplayId,
    required this.serviceLines,
    this.invoiceStaffId,
  });

  final ModuleRequestFlowType moduleType;
  final String patientId;
  final String invoiceId;
  final String invoiceDisplayId;
  final List<PaidInvoiceServiceLine> serviceLines;
  /// Staff on the invoice (requesting doctor); optional for external patients.
  final String? invoiceStaffId;
}

final moduleRequestFlowProvider = StateProvider<ModuleRequestFlowConfig>(
  (ref) => ModuleRequestFlowConfig.defaultBilling,
);

final paidModuleRequestContextProvider = StateProvider<PaidModuleRequestContext?>(
  (ref) => null,
);
