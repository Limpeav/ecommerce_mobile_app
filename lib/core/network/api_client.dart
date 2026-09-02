import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';

class ApiClient {
  final http.Client _client;

  /// Optional callback invoked when a request receives a 401 Unauthorized status.
  /// Should return a fresh authentication token or null if refresh failed.
  Future<String?> Function()? onRefreshToken;

  /// Optional callback invoked when a token refresh fails or session is definitively expired.
  void Function()? onSessionExpired;

  ApiClient({
    http.Client? client,
    this.onRefreshToken,
    this.onSessionExpired,
  }) : _client = client ?? http.Client();

  Map<String, String> _defaultHeaders(Map<String, String>? customHeaders) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?customHeaders,
    };
  }

  Future<dynamic> _executeWithAuthIntercept({
    required Future<http.Response> Function(Map<String, String> headers) request,
    Map<String, String>? headers,
  }) async {
    final initialHeaders = _defaultHeaders(headers);
    final response = await request(initialHeaders);

    if (response.statusCode == 401) {
      if (onRefreshToken != null) {
        try {
          final newToken = await onRefreshToken!();
          if (newToken != null && newToken.isNotEmpty) {
            final retriedHeaders = Map<String, String>.from(initialHeaders);
            retriedHeaders['Authorization'] = 'Bearer $newToken';
            final retryResponse = await request(retriedHeaders);
            if (retryResponse.statusCode != 401) {
              return _handleResponse(retryResponse);
            }
          }
        } catch (_) {}
      }
      onSessionExpired?.call();
    }

    return _handleResponse(response);
  }

  Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(url);
      return await _executeWithAuthIntercept(
        headers: headers,
        request: (hdrs) => _client.get(uri, headers: hdrs).timeout(timeout),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(url);
      return await _executeWithAuthIntercept(
        headers: headers,
        request: (hdrs) => _client
            .post(
              uri,
              headers: hdrs,
              body: body != null ? json.encode(body) : null,
            )
            .timeout(timeout),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(url);
      return await _executeWithAuthIntercept(
        headers: headers,
        request: (hdrs) => _client
            .put(
              uri,
              headers: hdrs,
              body: body != null ? json.encode(body) : null,
            )
            .timeout(timeout),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  Future<dynamic> delete(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final uri = Uri.parse(url);
      return await _executeWithAuthIntercept(
        headers: headers,
        request: (hdrs) => _client.delete(uri, headers: hdrs).timeout(timeout),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        final decoded = utf8.decode(response.bodyBytes);
        return json.decode(decoded);
      } catch (_) {
        return json.decode(response.body);
      }
    } else {
      throw ServerException(
        message: 'Failed request with status ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}

