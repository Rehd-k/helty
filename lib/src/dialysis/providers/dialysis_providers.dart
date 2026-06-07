import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dialysis_api_service.dart';

final dialysisApiServiceProvider = Provider<DialysisApiService>((ref) {
  return DialysisApiService();
});
