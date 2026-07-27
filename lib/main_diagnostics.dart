import 'src/app/bootstrap.dart';
import 'src/app/product_definition.dart';

/// Diagnostics product entry point.
///
/// Example:
/// ```bash
/// flutter run -d windows -t lib/main_diagnostics.dart ^
///   --dart-define=API_BASE_URL=https://api.diagnostics-customer.example
/// ```
Future<void> main() => bootstrapHeltyApp(product: AppProduct.diagnostics);
