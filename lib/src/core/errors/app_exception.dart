/// Sealed base class for all application exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// No internet / connection refused.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

/// Request timed out.
final class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'Request timed out. Please try again.',
  ]);
}

/// Any 4xx / 5xx HTTP response.
final class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

/// 401 – token missing or expired.
final class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Session expired. Please log in again.',
  ]) : super(statusCode: 401);
}

/// 403 – authenticated but lacks permission.
final class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'You do not have permission to perform this action.',
  ]) : super(statusCode: 403);
}

/// 404 – resource not found.
final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'The requested resource was not found.',
  ]) : super(statusCode: 404);
}

/// 422 / 400 – validation errors from the server.
final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.errors,
    super.statusCode = 422,
  });

  /// Map of field → list of error strings (e.g. from NestJS class-validator).
  final Map<String, List<String>>? errors;
}

/// Unexpected / unparseable response.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'An unexpected error occurred.']);
}
