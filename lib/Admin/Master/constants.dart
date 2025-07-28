// File: lib/constants/api_constants.dart

import 'package:doctordesktop/constants/Url.dart';

class ApiConstants {
  // Base URL - Replace with your actual API base URL
  static const String baseUrl =
      '${BASE_URL}/master'; // Replace this with your actual base URL

  // API Endpoints
  static const String patients = '/patients';
  static const String nextAvailableNumbers = '/next-available-numbers';
  static const String doctors = '/doctors';
  static const String appointments = '/appointments';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination defaults
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  static const int minPageSize = 5;

  // API Response codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int noContentCode = 204;
  static const int badRequestCode = 400;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int conflictCode = 409;
  static const int unprocessableEntityCode = 422;
  static const int tooManyRequestsCode = 429;
  static const int serverErrorCode = 500;
  static const int serviceUnavailableCode = 503;
  static const int timeoutCode = 408;

  // Error messages
  static const String networkErrorMessage =
      'Network connection error. Please check your internet connection.';
  static const String serverErrorMessage =
      'Server error occurred. Please try again later.';
  static const String unknownErrorMessage =
      'An unexpected error occurred. Please try again.';
  static const String timeoutErrorMessage =
      'Request timeout. Please try again.';
  static const String unauthorizedErrorMessage =
      'You are not authorized to perform this action.';
  static const String forbiddenErrorMessage =
      'Access denied. Please contact your administrator.';
  static const String notFoundErrorMessage =
      'The requested resource was not found.';
  static const String conflictErrorMessage =
      'The data conflicts with existing records.';
  static const String validationErrorMessage =
      'Please check your input and try again.';
  static const String tooManyRequestsErrorMessage =
      'Too many requests. Please wait and try again.';
  static const String serviceUnavailableErrorMessage =
      'Service is temporarily unavailable.';

  // Success messages
  static const String patientUpdatedMessage =
      'Patient information updated successfully';
  static const String admissionUpdatedMessage =
      'Admission record updated successfully';
  static const String patientCreatedMessage = 'Patient created successfully';
  static const String admissionCreatedMessage =
      'Admission record created successfully';
  static const String dataLoadedMessage = 'Data loaded successfully';
  static const String operationCompletedMessage =
      'Operation completed successfully';

  // Cache keys
  static const String patientsCacheKey = 'patients_cache';
  static const String nextNumbersCacheKey = 'next_numbers_cache';
  static const String doctorsCacheKey = 'doctors_cache';
  static const String userProfileCacheKey = 'user_profile_cache';

  // Cache duration
  static const Duration cacheValidDuration = Duration(minutes: 5);
  static const Duration nextNumbersCacheDuration = Duration(minutes: 2);
  static const Duration userProfileCacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 1);
  static const Duration longCacheDuration = Duration(hours: 24);

  // Request retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration exponentialBackoffBase = Duration(seconds: 1);

  // File upload configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx'];

  // Validation constants
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int minAddressLength = 5;
  static const int maxAddressLength = 500;
  static const int minAgeValue = 0;
  static const int maxAgeValue = 150;

  // Search configuration
  static const int minSearchLength = 2;
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);
  static const int maxSearchResults = 100;

  // UI Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration tooltipDelay = Duration(milliseconds: 500);

  // App configuration
  static const String appName = 'Hospital Management System';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@hospital.com';
  static const String privacyPolicyUrl = 'https://hospital.com/privacy';
  static const String termsOfServiceUrl = 'https://hospital.com/terms';

  // Date/Time formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String isoDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  // Gender options
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];

  // Patient status options
  static const List<String> patientStatusOptions = [
    'Active',
    'Discharged',
    'Transferred'
  ];

  // Admission status options
  static const List<String> admissionStatusOptions = [
    'Pending',
    'Admitted',
    'Discharged'
  ];

  // Patient type options
  static const List<String> patientTypeOptions = [
    'Internal',
    'External',
    'Emergency'
  ];

  // Sort order options
  static const List<String> sortOrderOptions = ['asc', 'desc'];

  // Blood group options
  static const List<String> bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  // API Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';
  static const String deviceIdHeader = 'X-Device-ID';
  static const String appVersionHeader = 'X-App-Version';

  // Content types
  static const String jsonContentType = 'application/json';
  static const String formDataContentType = 'multipart/form-data';
  static const String urlEncodedContentType =
      'application/x-www-form-urlencoded';

  // Security
  static const String tokenPrefix = 'Bearer ';
  static const Duration tokenExpiryBuffer = Duration(minutes: 5);
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 100;

  // Feature flags (for conditional features)
  static const bool enableCaching = true;
  static const bool enableLogging = true;
  static const bool enableOfflineMode = false;
  static const bool enableBiometricAuth = true;
  static const bool enablePushNotifications = true;

  // Environment configuration
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isDebugMode =
      bool.fromEnvironment('DEBUG', defaultValue: true);
  static const bool enableApiLogging =
      bool.fromEnvironment('API_LOGGING', defaultValue: true);

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  // Database/Storage constants
  static const String databaseName = 'hospital_management.db';
  static const int databaseVersion = 1;
  static const String preferencesKey = 'hospital_prefs';

  // Regex patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[\d\s\-\(\)]+$';
  static const String namePattern = r'^[a-zA-Z\s\.]+$';
  static const String numericPattern = r'^\d+$';
  static const String alphanumericPattern = r'^[a-zA-Z0-9]+$';

  /// Get error message based on status code
  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case unauthorizedCode:
        return unauthorizedErrorMessage;
      case forbiddenCode:
        return forbiddenErrorMessage;
      case notFoundCode:
        return notFoundErrorMessage;
      case conflictCode:
        return conflictErrorMessage;
      case unprocessableEntityCode:
        return validationErrorMessage;
      case tooManyRequestsCode:
        return tooManyRequestsErrorMessage;
      case serverErrorCode:
        return serverErrorMessage;
      case serviceUnavailableCode:
        return serviceUnavailableErrorMessage;
      case timeoutCode:
        return timeoutErrorMessage;
      case 0:
        return networkErrorMessage;
      default:
        return unknownErrorMessage;
    }
  }

  /// Check if status code indicates success
  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Check if status code indicates client error
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }

  /// Check if status code indicates server error
  static bool isServerError(int statusCode) {
    return statusCode >= 500;
  }

  /// Get retry delay with exponential backoff
  static Duration getRetryDelay(int attemptNumber) {
    return Duration(
      milliseconds:
          exponentialBackoffBase.inMilliseconds * (1 << attemptNumber),
    );
  }

  /// Build API endpoint URL
  static String buildEndpoint(String endpoint,
      [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams).toString();
    }
    return uri.toString();
  }

  /// Get default headers
  static Map<String, String> getDefaultHeaders() {
    return {
      contentTypeHeader: jsonContentType,
      acceptHeader: jsonContentType,
      userAgentHeader: '$appName/$appVersion',
      appVersionHeader: appVersion,
    };
  }
}
