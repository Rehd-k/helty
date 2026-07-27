import 'src/app/bootstrap.dart';
import 'src/app/product_definition.dart';

/// Pharmacy product entry point.
///
/// Example:
/// ```bash
/// flutter run -d windows -t lib/main_pharmacy.dart ^
///   --dart-define=API_BASE_URL=https://api.pharmacy-customer.example
/// ```
Future<void> main() => bootstrapHeltyApp(product: AppProduct.pharmacy);
