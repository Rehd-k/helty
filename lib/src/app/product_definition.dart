/// Compile-time / entry-point product line for Helty builds.
enum AppProduct {
  hospital,
  pharmacy,
  diagnostics,
}

/// Capability modules that products may enable.
///
/// Hospital enables every module. Smaller products enable a subset.
enum AppModule {
  registration,
  billing,
  pharmacy,
  laboratory,
  radiology,
  nursing,
  physician,
  purchases,
  dialysis,
  theatre,
  store,
  accounting,
  hmo,
  medicalRecords,
  ict,
  administration,
}

class ProductDefinition {
  const ProductDefinition({
    required this.product,
    required this.displayName,
    required this.enabledModules,
  });

  final AppProduct product;
  final String displayName;
  final Set<AppModule> enabledModules;

  bool isModuleEnabled(AppModule module) => enabledModules.contains(module);
}

const kAllAppModules = {
  AppModule.registration,
  AppModule.billing,
  AppModule.pharmacy,
  AppModule.laboratory,
  AppModule.radiology,
  AppModule.nursing,
  AppModule.physician,
  AppModule.purchases,
  AppModule.dialysis,
  AppModule.theatre,
  AppModule.store,
  AppModule.accounting,
  AppModule.hmo,
  AppModule.medicalRecords,
  AppModule.ict,
  AppModule.administration,
};

const kHospitalProduct = ProductDefinition(
  product: AppProduct.hospital,
  displayName: 'Helty',
  enabledModules: kAllAppModules,
);

const kPharmacyProduct = ProductDefinition(
  product: AppProduct.pharmacy,
  displayName: 'Helty Pharmacy',
  enabledModules: {
    AppModule.registration,
    AppModule.billing,
    AppModule.pharmacy,
  },
);

const kDiagnosticsProduct = ProductDefinition(
  product: AppProduct.diagnostics,
  displayName: 'Helty Diagnostics',
  enabledModules: {
    AppModule.registration,
    AppModule.billing,
    AppModule.laboratory,
    AppModule.radiology,
  },
);

ProductDefinition productDefinitionFor(AppProduct product) {
  return switch (product) {
    AppProduct.hospital => kHospitalProduct,
    AppProduct.pharmacy => kPharmacyProduct,
    AppProduct.diagnostics => kDiagnosticsProduct,
  };
}

AppProduct parseAppProduct(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'pharmacy':
      return AppProduct.pharmacy;
    case 'diagnostics':
    case 'diagnostic':
      return AppProduct.diagnostics;
    case 'hospital':
    case '':
      return AppProduct.hospital;
    default:
      return AppProduct.hospital;
  }
}
