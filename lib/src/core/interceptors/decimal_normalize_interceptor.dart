import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../utils/api_decimal.dart';

/// Converts Prisma/decimal.js `{s, e, d}` values to plain doubles in API responses.
class DecimalNormalizeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.responseType == ResponseType.bytes ||
        response.data is Uint8List) {
      handler.next(response);
      return;
    }
    response.data = normalizeApiDecimals(response.data);
    handler.next(response);
  }
}
