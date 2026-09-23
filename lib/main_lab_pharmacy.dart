import 'src/app/bootstrap.dart';
import 'src/app/product_definition.dart';

/// Lab, pharmacy, and HMO product entry point.
///
/// Example:
/// ```bash
/// flutter run -d windows -t lib/main_lab_pharmacy.dart ^
///   --dart-define=API_BASE_URL=https://api.customer.example
/// ```
Future<void> main() => bootstrapHeltyApp(product: AppProduct.labPharmacy);
