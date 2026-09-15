class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic data;

  const ApiException({required this.message, this.statusCode, this.code, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Code: $code)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network connection failed. Please check your internet.'});
}

class AuthException extends ApiException {
  const AuthException({super.message = 'Authentication required. Please sign in again.'}) : super(statusCode: 401);
}
