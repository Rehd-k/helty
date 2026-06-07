import 'package:dio/dio.dart';

import '../models/accounts_models.dart';
import 'accounts_base_service.dart';
import 'accounts_endpoints.dart';

class AccountsDashboardService extends AccountsBaseService {
  AccountsDashboardService({super.dio});

  Future<AccountsDashboardBundle> fetchDashboard({
    required String period,
    DateTime? asOf,
    bool isHead = true,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.dashboard,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
          if (!isHead) 'view': 'staff',
        },
      );
      return AccountsDashboardBundle.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Accounts dashboard');
    }
  }
}
