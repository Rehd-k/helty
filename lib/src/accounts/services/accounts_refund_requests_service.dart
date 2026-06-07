import 'package:dio/dio.dart';

import '../models/accounts_models.dart';
import 'accounts_base_service.dart';
import 'accounts_endpoints.dart';

class AccountsRefundRequestsService extends AccountsBaseService {
  AccountsRefundRequestsService({super.dio});

  Future<List<AccountsPendingRefundRequest>> fetchPending() async {
    try {
      final response =
          await dio.get<dynamic>(AccountsEndpoints.refundRequestsPending);
      return asList(response.data, key: 'requests')
          .whereType<Map>()
          .map(
            (e) => AccountsPendingRefundRequest.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Pending refund requests');
    }
  }

  Future<AccountsRefundApproveResult> approve(
    String id, {
    String? note,
  }) async {
    try {
      final response = await dio.post<dynamic>(
        AccountsEndpoints.approveRefundRequest(id),
        data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      );
      return AccountsRefundApproveResult.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Approve refund request');
    }
  }

  Future<void> reject(String id, {required String reason}) async {
    try {
      await dio.post<void>(
        AccountsEndpoints.rejectRefundRequest(id),
        data: {'reason': reason.trim()},
      );
    } on DioException catch (e) {
      throwApi(e, 'Reject refund request');
    }
  }
}
