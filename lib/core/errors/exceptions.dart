class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    this.message = 'Server communication error',
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => 'NetworkException: $message';
}
