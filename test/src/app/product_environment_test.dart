import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/app/product_definition.dart';
import 'package:helty/src/app/product_environment.dart';
import 'package:helty/src/app/product_module_access.dart';
import 'package:helty/src/models/staff_model.dart';

void main() {
  tearDown(() {
    ProductEnvironment.debugResetBind();
  });

  group('parseAppProduct', () {
    test('defaults unknown and empty to hospital', () {
      expect(parseAppProduct(''), AppProduct.hospital);
      expect(parseAppProduct('hospital'), AppProduct.hospital);
      expect(parseAppProduct('unknown'), AppProduct.hospital);
    });

    test('parses pharmacy and diagnostics', () {
      expect(parseAppProduct('pharmacy'), AppProduct.pharmacy);
      expect(parseAppProduct('Pharmacy'), AppProduct.pharmacy);
      expect(parseAppProduct('diagnostics'), AppProduct.diagnostics);
      expect(parseAppProduct('diagnostic'), AppProduct.diagnostics);
    });
  });

  group('product definitions', () {
    test('hospital enables all modules by default environment', () {
      expect(ProductEnvironment.currentProduct, AppProduct.hospital);
      expect(ProductEnvironment.displayName, 'Helty');
      expect(
        ProductEnvironment.enabledModules,
        containsAll([
          AppModule.registration,
          AppModule.billing,
          AppModule.pharmacy,
          AppModule.laboratory,
          AppModule.radiology,
          AppModule.nursing,
          AppModule.physician,
          AppModule.administration,
        ]),
      );
    });

    test('pharmacy enables registration, billing, pharmacy only', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(ProductEnvironment.displayName, 'Helty Pharmacy');
      expect(
        ProductEnvironment.enabledModules,
        {
          AppModule.registration,
          AppModule.billing,
          AppModule.pharmacy,
        },
      );
      expect(ProductEnvironment.isModuleEnabled(AppModule.laboratory), isFalse);
      expect(ProductEnvironment.isModuleEnabled(AppModule.physician), isFalse);
    });

    test('diagnostics enables registration, billing, lab, radiology', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      expect(ProductEnvironment.displayName, 'Helty Diagnostics');
      expect(
        ProductEnvironment.enabledModules,
        {
          AppModule.registration,
          AppModule.billing,
          AppModule.laboratory,
          AppModule.radiology,
        },
      );
      expect(ProductEnvironment.isModuleEnabled(AppModule.pharmacy), isFalse);
    });
  });

  group('apiCandidateBaseUrls', () {
    test('falls back to hospital/dev candidates when unset', () {
      expect(
        ProductEnvironment.apiCandidateBaseUrls(apiBaseUrlOverride: ''),
        kApiCandidateBaseUrls,
      );
    });

    test('explicit URL wins and strips trailing slash', () {
      expect(
        ProductEnvironment.apiCandidateBaseUrls(
          apiBaseUrlOverride: 'https://api.customer.example/',
        ),
        ['https://api.customer.example'],
      );
    });

    test('semicolon-separated list returns multiple normalized candidates', () {
      expect(
        ProductEnvironment.apiCandidateBaseUrls(
          apiBaseUrlOverride:
              'http://localhost:3000/; http://192.168.2.121:3000;http://api.imsh.ng/',
        ),
        [
          'http://localhost:3000',
          'http://192.168.2.121:3000',
          'http://api.imsh.ng',
        ],
      );
    });

    test('single URL still returns a one-element list', () {
      expect(
        ProductEnvironment.apiCandidateBaseUrls(
          apiBaseUrlOverride: 'http://localhost:3000',
        ),
        ['http://localhost:3000'],
      );
    });
  });

  group('validateReleaseConfig', () {
    test('hospital release does not require API_BASE_URL', () {
      expect(
        () => ProductEnvironment.validateReleaseConfig(
          isRelease: true,
          productOverride: AppProduct.hospital,
          apiBaseUrlOverride: '',
        ),
        returnsNormally,
      );
    });

    test('pharmacy release requires API_BASE_URL', () {
      expect(
        () => ProductEnvironment.validateReleaseConfig(
          isRelease: true,
          productOverride: AppProduct.pharmacy,
          apiBaseUrlOverride: '',
        ),
        throwsStateError,
      );
    });

    test('pharmacy release accepts API_BASE_URL', () {
      expect(
        () => ProductEnvironment.validateReleaseConfig(
          isRelease: true,
          productOverride: AppProduct.pharmacy,
          apiBaseUrlOverride: 'https://api.pharmacy.example',
        ),
        returnsNormally,
      );
    });

    test('debug pharmacy without API_BASE_URL is allowed', () {
      expect(
        () => ProductEnvironment.validateReleaseConfig(
          isRelease: false,
          productOverride: AppProduct.pharmacy,
          apiBaseUrlOverride: '',
        ),
        returnsNormally,
      );
    });
  });

  group('ProductModuleAccess', () {
    test('maps account types to modules', () {
      expect(
        ProductModuleAccess.moduleForAccountType('front_desk'),
        AppModule.registration,
      );
      expect(
        ProductModuleAccess.moduleForAccountType('pharmacy'),
        AppModule.pharmacy,
      );
      expect(
        ProductModuleAccess.moduleForAccountType('laboratory'),
        AppModule.laboratory,
      );
      expect(
        ProductModuleAccess.moduleForAccountType('physician'),
        AppModule.physician,
      );
    });

    test('pharmacy product refuses hospital-only account types', () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('pharmacy'),
        isTrue,
      );
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('billing'),
        isTrue,
      );
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('physician'),
        isFalse,
      );
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('laboratory'),
        isFalse,
      );
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('cmd'),
        isFalse,
      );
    });

    test('diagnostics product refuses pharmacy', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('laboratory'),
        isTrue,
      );
      expect(
        ProductModuleAccess.isAccountTypeAllowedForProduct('pharmacy'),
        isFalse,
      );
    });

    test('allowedDepartmentTypes follows product modules and keeps super_admin',
        () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      final types = ProductModuleAccess.allowedDepartmentTypes();
      expect(types, contains(AccountType.front_desk));
      expect(types, contains(AccountType.billing));
      expect(types, contains(AccountType.laboratory));
      expect(types, contains(AccountType.radiology));
      expect(types, contains(AccountType.super_admin));
      expect(types, isNot(contains(AccountType.pharmacy)));
      expect(types, isNot(contains(AccountType.physician)));
      expect(types, isNot(contains(AccountType.nurse)));
    });

    test('allowedDepartmentTypes for pharmacy is registration+billing+pharmacy',
        () {
      ProductEnvironment.bind(AppProduct.pharmacy);
      final types = ProductModuleAccess.allowedDepartmentTypes();
      expect(
        types.map((t) => t.name).toSet(),
        {
          'front_desk',
          'billing',
          'pharmacy',
          'super_admin',
        },
      );
    });

    test('allowedHubDepartments filters to product modules', () {
      ProductEnvironment.bind(AppProduct.diagnostics);
      final hubs = ProductModuleAccess.allowedHubDepartments();
      expect(
        hubs.map((h) => h.previewAccountType).toSet(),
        {'billing', 'laboratory', 'radiology', 'front_desk'},
      );
    });
  });
}
