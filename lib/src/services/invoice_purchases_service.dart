import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../purchases/models/purchases_usage_history_model.dart';
import 'api_service.dart';

/// `POST /invoice-purchases/:invoiceId/items/:itemId/return` and related helpers.
class InvoicePurchasesApiService {
  InvoicePurchasesApiService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  static const String _prefix = '/invoice-purchases';

  Never _handleError(DioException e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.message)?.toString()
        : e.message;
    throw UnknownException(
      message?.toString().isNotEmpty == true
          ? message!
          : 'Invoice purchases request failed.',
    );
  }

  /// Partial or full return of a purchase invoice line (unpaid lines only).
  Future<ReturnPurchaseInvoiceItemResult> returnInvoiceItem({
    required String invoiceId,
    required String itemId,
    required ReturnPurchaseInvoiceItemDto dto,
  }) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '$_prefix/$invoiceId/items/$itemId/return',
        data: dto.toJson(),
      );
      final data = resp.data;
      if (data == null) {
        return const ReturnPurchaseInvoiceItemResult(
          returnId: '',
          fullLineRemoved: false,
        );
      }
      return ReturnPurchaseInvoiceItemResult.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
