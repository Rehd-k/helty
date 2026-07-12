import 'package:dio/dio.dart';

import 'app_exception.dart';

const networkErrorTitle = "Can't reach the server";

const networkErrorMessage =
    'Helty could not connect to the hospital server. '
    'This is usually a network or connectivity issue.';

const networkErrorTips = <String>[
  'Check your internet or hospital network connection',
  'Tap Retry to try again',
  'Fully close and reopen Helty if the problem continues',
  'Contact your IT support team if it still fails',
];

/// Returns the [AppException] embedded in [error], if any.
AppException? appExceptionFrom(Object error) {
  if (error is AppException) return error;
  if (error is DioException && error.error is AppException) {
    return error.error as AppException;
  }
  return null;
}

bool isNetworkRelatedError(Object error) {
  final appEx = appExceptionFrom(error);
  if (appEx is NetworkException || appEx is TimeoutException) return true;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.badCertificate:
        return true;
      default:
        return false;
    }
  }

  return _looksTechnical(error.toString());
}

/// Converts any caught error into safe, user-facing text (no URLs or stack traces).
String userFacingErrorMessage(Object error, {String? fallback}) {
  final appEx = appExceptionFrom(error);
  if (appEx != null) {
    if (appEx is NetworkException || appEx is TimeoutException) {
      return appEx.message;
    }
    return appEx.message;
  }

  if (error is DioException) {
    if (_isDioNetworkType(error)) {
      return networkErrorMessage;
    }
    final msg = error.message;
    if (msg != null && msg.isNotEmpty && !_looksTechnical(msg)) {
      return msg;
    }
    return fallback ?? networkErrorMessage;
  }

  var text = error.toString();
  if (text.startsWith('Exception: ')) {
    text = text.substring('Exception: '.length);
  }

  if (_looksTechnical(text)) {
    return fallback ?? networkErrorMessage;
  }

  return text.isNotEmpty ? text : (fallback ?? networkErrorMessage);
}

bool _isDioNetworkType(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.badCertificate:
      return true;
    default:
      return false;
  }
}

bool _looksTechnical(String text) {
  final lower = text.toLowerCase();
  if (lower.contains('http://') || lower.contains('https://')) return true;
  if (lower.contains('none of the configured servers')) return true;
  if (RegExp(r'\b\d{1,3}(\.\d{1,3}){3}\b').hasMatch(text)) return true;
  if (lower.contains('connection refused') ||
      lower.contains('connection errored') ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable')) {
    return true;
  }
  return false;
}
