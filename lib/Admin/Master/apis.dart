// File: lib/services/patient_api_service.dart

import 'dart:convert';
import 'package:doctordesktop/Admin/Master/constants.dart';
import 'package:http/http.dart' as http;

class PatientApiService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // Headers for API requests
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Add authorization header if needed
        if (TokenManager.getToken() != null)
          'Authorization': 'Bearer ${TokenManager.getToken()}',
      };

  /// Get patients list with pagination and search
  /// GET {{baseUrl}}/patients?page=1&limit=10&search=&sortOrder=asc
  static Future<Map<String, dynamic>> getPatients({
    int page = 1,
    int limit = 10,
    String search = '',
    String sortOrder = 'asc',
  }) async {
    try {
      await NetworkUtil.ensureConnected();

      final uri = Uri.parse('$_baseUrl/patients').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'sortOrder': sortOrder,
      });

      ApiInterceptor.logRequest('GET', uri, null);

      final response = await http.get(uri, headers: _headers).timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () =>
                throw ApiException(ApiConstants.timeoutErrorMessage, 408),
          );

      ApiInterceptor.logResponse(response.statusCode, response.body);
      print("hhrloo ${response.body}");
      if (response.statusCode == ApiConstants.successCode) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          throw ApiException(
              'API returned success: false', response.statusCode);
        }
      } else {
        final Map<String, dynamic>? errorData =
            json.decode(response.body) as Map<String, dynamic>?;
        throw ApiException(
          errorData?['message'] ??
              'Failed to load patients. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Update patient basic information
  /// PATCH {{baseUrl}}/patients/{patientId}/basic
  static Future<Map<String, dynamic>> updatePatientBasicInfo(
    String patientId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await NetworkUtil.ensureConnected();

      final uri = Uri.parse('$_baseUrl/patients/$patientId/basic');
      final body = ApiInterceptor.addTimestamp(updateData);

      ApiInterceptor.logRequest('PATCH', uri, body);

      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(
            ApiConstants.sendTimeout,
            onTimeout: () =>
                throw ApiException(ApiConstants.timeoutErrorMessage, 408),
          );

      ApiInterceptor.logResponse(response.statusCode, response.body);

      if (response.statusCode == ApiConstants.successCode) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          throw ApiException(
            data['message'] ?? 'Failed to update patient information',
            response.statusCode,
          );
        }
      } else {
        final Map<String, dynamic>? errorData =
            json.decode(response.body) as Map<String, dynamic>?;
        throw ApiException(
          errorData?['message'] ??
              'Failed to update patient. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Update admission record numbers (OPD/IPD)
  /// PATCH {{baseUrl}}/patients/{patientId}/admission/{admissionId}/numbers
  static Future<Map<String, dynamic>> updateAdmissionNumbers(
    String patientId,
    String admissionId,
    Map<String, dynamic> numberUpdates,
  ) async {
    try {
      await NetworkUtil.ensureConnected();

      final uri = Uri.parse(
          '$_baseUrl/patients/$patientId/admission/$admissionId/numbers');
      final body = ApiInterceptor.addTimestamp(numberUpdates);

      ApiInterceptor.logRequest('PATCH', uri, body);

      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(
            ApiConstants.sendTimeout,
            onTimeout: () =>
                throw ApiException(ApiConstants.timeoutErrorMessage, 408),
          );

      ApiInterceptor.logResponse(response.statusCode, response.body);

      if (response.statusCode == ApiConstants.successCode) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          throw ApiException(
            data['message'] is Map
                ? data['message']['conflictDetails']
                    ? ['patientName'] ?? 'Failed to update admission numbers'
                    : data['message'] ?? 'Failed to update admission numbers'
                : 'Failed to update admission numbers',
            response.statusCode,
          );
        }
      } else {
        final Map<String, dynamic>? errorData =
            json.decode(response.body) as Map<String, dynamic>?;

        // Handle specific error messages like "OPD number already in use"
        String errorMessage =
            errorData?['message'] ?? 'Failed to update admission numbers';

        throw ApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Update full admission record
  /// PATCH {{baseUrl}}/patients/{patientId}/admission/{admissionId}
  static Future<Map<String, dynamic>> updateAdmissionRecord(
    String patientId,
    String admissionId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      await NetworkUtil.ensureConnected();

      final uri =
          Uri.parse('$_baseUrl/patients/$patientId/admission/$admissionId');
      final body = ApiInterceptor.addTimestamp(updateData);

      ApiInterceptor.logRequest('PUT', uri, body);

      final response = await http
          .put(
            uri,
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(
            ApiConstants.sendTimeout,
            onTimeout: () =>
                throw ApiException(ApiConstants.timeoutErrorMessage, 408),
          );

      ApiInterceptor.logResponse(response.statusCode, response.body);

      if (response.statusCode == ApiConstants.successCode) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          throw ApiException(
            data['message'] ?? 'Failed to update admission record',
            response.statusCode,
          );
        }
      } else {
        final Map<String, dynamic>? errorData =
            json.decode(response.body) as Map<String, dynamic>?;
        throw ApiException(
          errorData?['message'] ??
              'Failed to update admission. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Get next available OPD and IPD numbers
  /// GET {{baseUrl}}/next-available-numbers
  static Future<Map<String, dynamic>> getNextAvailableNumbers() async {
    try {
      await NetworkUtil.ensureConnected();

      final uri = Uri.parse('$_baseUrl/next-available-numbers');

      ApiInterceptor.logRequest('GET', uri, null);

      final response = await http.get(uri, headers: _headers).timeout(
            ApiConstants.receiveTimeout,
            onTimeout: () =>
                throw ApiException(ApiConstants.timeoutErrorMessage, 408),
          );

      ApiInterceptor.logResponse(response.statusCode, response.body);

      if (response.statusCode == ApiConstants.successCode) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        } else {
          throw ApiException(
              'Failed to get next available numbers', response.statusCode);
        }
      } else {
        final Map<String, dynamic>? errorData =
            json.decode(response.body) as Map<String, dynamic>?;
        throw ApiException(
          errorData?['message'] ??
              'Failed to get next available numbers. Status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Search patients with debouncing support
  static Future<Map<String, dynamic>> searchPatients(
    String query, {
    int page = 1,
    int limit = 10,
    String sortOrder = 'asc',
  }) async {
    return getPatients(
      page: page,
      limit: limit,
      search: query,
      sortOrder: sortOrder,
    );
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;

  /// Check if the error is due to network connectivity
  bool get isNetworkError => statusCode == 0;

  /// Check if the error is a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Check if the error is a server error (5xx)
  bool get isServerError => statusCode >= 500;

  /// Check if the error is unauthorized
  bool get isUnauthorized => statusCode == 401;

  /// Check if the error is forbidden
  bool get isForbidden => statusCode == 403;

  /// Check if the error is not found
  bool get isNotFound => statusCode == 404;

  /// Check if the error is a conflict (like duplicate OPD number)
  bool get isConflict => statusCode == 409;
}

/// API Response wrapper for type safety
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    try {
      if (json['success'] == true) {
        return ApiResponse.success(
          fromJsonT(json['data']),
          message: json['message'],
        );
      } else {
        return ApiResponse.error(
          json['message'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
}

/// Request interceptor for common operations
class ApiInterceptor {
  static Map<String, String> addAuthHeader(Map<String, String> headers) {
    // Add authentication token if available
    final token = TokenManager.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> addTimestamp(Map<String, dynamic> body) {
    body['timestamp'] = DateTime.now().toIso8601String();
    return body;
  }

  static void logRequest(String method, Uri uri, Map<String, dynamic>? body) {
    print('🔵 API Request: $method ${uri.toString()}');
    if (body != null) {
      print('📤 Request Body: ${json.encode(body)}');
    }
  }

  static void logResponse(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      print('🟢 API Response: $statusCode');
    } else {
      print('🔴 API Error: $statusCode - $body');
    }
  }
}

/// Token manager for authentication
class TokenManager {
  static String? _token;

  static String? getToken() => _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static bool get isAuthenticated => _token != null;
}

/// Network utility for checking connectivity
class NetworkUtil {
  static Future<bool> isConnected() async {
    try {
      final response =
          await http.head(Uri.parse('https://www.google.com')).timeout(
                const Duration(seconds: 5),
              );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> ensureConnected() async {
    if (!await isConnected()) {
      throw ApiException('No internet connection available', 0);
    }
  }
}

/// Cache manager for API responses
class ApiCacheManager {
  static final Map<String, CacheEntry> _cache = {};

  static void put(String key, dynamic data, Duration duration) {
    _cache[key] = CacheEntry(data, DateTime.now().add(duration));
  }

  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry != null && entry.expiryTime.isAfter(DateTime.now())) {
      return entry.data as T?;
    }
    _cache.remove(key);
    return null;
  }

  static void clear() {
    _cache.clear();
  }

  static void remove(String key) {
    _cache.remove(key);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  CacheEntry(this.data, this.expiryTime);
}
