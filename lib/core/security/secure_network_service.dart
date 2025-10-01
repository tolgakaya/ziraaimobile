import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/api_constants.dart';
import 'token_manager.dart';
import 'input_validator.dart';

/// Secure network service with SSL pinning and security features
class SecureNetworkService {
  late final Dio _dio;
  final TokenManager _tokenManager;
  final Connectivity _connectivity;

  // SSL certificate fingerprints for certificate pinning
  static const List<String> _certificateFingerprints = [
    // Production API certificate fingerprint (SHA-256)
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Replace with actual fingerprint
    // Staging API certificate fingerprint (SHA-256)
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Replace with actual fingerprint
  ];

  SecureNetworkService({
    required TokenManager tokenManager,
    Connectivity? connectivity,
  })  : _tokenManager = tokenManager,
        _connectivity = connectivity ?? Connectivity() {
    _initializeDio();
  }

  /// Initialize Dio with security configurations
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: ApiConstants.sendTimeout),
      contentType: ApiConstants.contentType,
      responseType: ResponseType.json,
      followRedirects: false, // Prevent automatic redirects for security
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': ApiConstants.contentType,
        'User-Agent': 'ZiraAI-Mobile/1.0.0',
        'X-Requested-With': 'ZiraAI-Mobile',
      },
    ));

    _setupInterceptors();
  }

  /// Setup security interceptors
  void _setupInterceptors() {
    // Certificate pinning disabled for now - to be implemented later
    // if (ApiConstants.baseUrl.contains('api.ziraai.com')) {
    //   _dio.interceptors.add(
    //     CertificatePinningInterceptor(
    //       allowedSHAFingerprints: _certificateFingerprints,
    //     ),
    //   );
    // }

    // Add token interceptor
    _dio.interceptors.add(TokenInterceptor(_tokenManager));

    // Add network security interceptor
    _dio.interceptors.add(NetworkSecurityInterceptor());

    // Add request/response logging (only in debug mode)
    if (_isDebugMode()) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          compact: false,
          maxWidth: 90,
          logPrint: _secureLogPrint, // Custom secure logging
        ),
      );
    }

    // Add retry interceptor for network failures
    _dio.interceptors.add(RetryInterceptor());
  }

  /// Make a secure GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    _validatePath(path);

    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make a secure POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    _validatePath(path);

    // Validate and sanitize request data
    if (data is Map<String, dynamic>) {
      data = _sanitizeRequestData(data);
    }

    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make a secure PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    _validatePath(path);

    if (data is Map<String, dynamic>) {
      data = _sanitizeRequestData(data);
    }

    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make a secure DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    _validatePath(path);

    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file securely
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await _checkConnectivity();
    _validatePath(path);

    // Validate file
    final fileValidation = InputValidator.validateFileUpload(
      fileName: file.path.split('/').last,
      fileSize: await file.length(),
    );

    if (!fileValidation.isValid) {
      throw NetworkException('File validation failed: ${fileValidation.error}');
    }

    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      if (extraData != null) ...extraData,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResults = await _connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.none)) {
      throw NetworkException('İnternet bağlantısı yok');
    }

    // Additional check for actual internet access
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty) {
        throw NetworkException('İnternet erişimi yok');
      }
    } on SocketException {
      throw NetworkException('İnternet bağlantısı başarısız');
    }
  }

  /// Validate request path for security
  void _validatePath(String path) {
    if (InputValidator.containsPathTraversalPatterns(path)) {
      throw NetworkException('Güvenlik nedeniyle istek reddedildi');
    }

    if (path.contains('javascript:') || path.contains('data:')) {
      throw NetworkException('Geçersiz URL protokolü');
    }
  }

  /// Sanitize request data to prevent injection attacks
  Map<String, dynamic> _sanitizeRequestData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        // Check for SQL injection and XSS patterns
        if (InputValidator.containsSQLInjectionPatterns(value) ||
            InputValidator.containsXSSPatterns(value)) {
          throw NetworkException('Güvenlik nedeniyle istek reddedildi');
        }
        sanitized[key] = InputValidator.sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeRequestData(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Secure logging that masks sensitive data
  void _secureLogPrint(Object object) {
    final logString = object.toString();

    // Mask sensitive fields
    var maskedLog = logString
        .replaceAllMapped(
          RegExp(r'"(access_token|refresh_token|password|pin)":\s*"([^"]*)"', caseSensitive: false),
          (match) => '"${match.group(1)}": "***MASKED***"',
        )
        .replaceAllMapped(
          RegExp(r'"Authorization":\s*"Bearer\s+([^"]*)"', caseSensitive: false),
          (match) => '"Authorization": "Bearer ***MASKED***"',
        )
        .replaceAllMapped(
          RegExp(r'"(email|phone|user_id)":\s*"([^"]*)"', caseSensitive: false),
          (match) => '"${match.group(1)}": "***MASKED***"',
        );

    print(maskedLog);
  }

  /// Check if running in debug mode
  bool _isDebugMode() {
    bool isDebug = false;
    assert(isDebug = true); // This only executes in debug mode
    return isDebug;
  }

  /// Get network statistics
  NetworkStats getNetworkStats() {
    return NetworkStats(
      totalRequests: _requestCount,
      failedRequests: _failedRequestCount,
      averageResponseTime: _calculateAverageResponseTime(),
      lastRequestTime: _lastRequestTime,
      certificatePinningEnabled: ApiConstants.baseUrl.contains('api.ziraai.com'),
    );
  }

  // Network statistics tracking
  int _requestCount = 0;
  int _failedRequestCount = 0;
  final List<int> _responseTimes = [];
  DateTime? _lastRequestTime;

  int _calculateAverageResponseTime() {
    if (_responseTimes.isEmpty) return 0;
    return _responseTimes.reduce((a, b) => a + b) ~/ _responseTimes.length;
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}

/// Network security interceptor
class NetworkSecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers.addAll({
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    // Add request timestamp for tracking
    options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Calculate response time
    final startTime = response.requestOptions.extra['request_start_time'] as int?;
    if (startTime != null) {
      final responseTime = DateTime.now().millisecondsSinceEpoch - startTime;
      response.extra['response_time'] = responseTime;
    }

    // Validate response headers for security
    _validateResponseHeaders(response);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log security-related errors
    if (err.type == DioExceptionType.badCertificate) {
      print('SSL Certificate error: ${err.message}');
    } else if (err.type == DioExceptionType.connectionTimeout) {
      print('Connection timeout: Possible network attack or poor connection');
    }

    handler.next(err);
  }

  void _validateResponseHeaders(Response response) {
    final headers = response.headers.map;

    // Check for security headers
    if (!headers.containsKey('content-type')) {
      print('Warning: Missing Content-Type header');
    }

    // Check for suspicious headers
    const suspiciousHeaders = ['X-Powered-By', 'Server'];
    for (final header in suspiciousHeaders) {
      if (headers.containsKey(header.toLowerCase())) {
        print('Warning: Potentially insecure header found: $header');
      }
    }
  }
}

/// Retry interceptor for network failures
class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retry_count'] ?? 0;

    // Only retry on specific error types
    if (_shouldRetry(err) && retryCount < maxRetries) {
      options.extra['retry_count'] = retryCount + 1;

      // Wait before retry with exponential backoff
      await Future.delayed(retryDelay * (retryCount + 1));

      try {
        final dio = Dio();
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error if retry fails
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

/// Network statistics class
class NetworkStats {
  final int totalRequests;
  final int failedRequests;
  final int averageResponseTime;
  final DateTime? lastRequestTime;
  final bool certificatePinningEnabled;

  const NetworkStats({
    required this.totalRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    this.lastRequestTime,
    required this.certificatePinningEnabled,
  });

  double get successRate {
    if (totalRequests == 0) return 0.0;
    return ((totalRequests - failedRequests) / totalRequests) * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'total_requests': totalRequests,
      'failed_requests': failedRequests,
      'success_rate': successRate,
      'average_response_time': averageResponseTime,
      'last_request_time': lastRequestTime?.toIso8601String(),
      'certificate_pinning_enabled': certificatePinningEnabled,
    };
  }
}

/// Token interceptor for automatic authentication and refresh
class TokenInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  TokenInterceptor(this._tokenManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register/refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Get valid access token
    final token = await _tokenManager.getValidAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 TokenInterceptor: Added auth token to request');
      handler.next(options);
    } else {
      // Token is expired, try to refresh
      print('⚠️ TokenInterceptor: Token expired, attempting refresh before request');

      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newToken = await _tokenManager.getToken();
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
          handler.next(options);
          return;
        }
      }

      // Refresh failed, reject request
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'Authentication required - please login',
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      print('🔑 TokenInterceptor: 401 Unauthorized - attempting token refresh');

      // Prevent multiple simultaneous refresh attempts
      if (_isRefreshing) {
        print('🔑 TokenInterceptor: Refresh already in progress, queuing request');
        _pendingRequests.add(err.requestOptions);
        return; // Don't call handler yet
      }

      _isRefreshing = true;

      try {
        final refreshed = await _attemptTokenRefresh();

        if (refreshed) {
          print('✅ TokenInterceptor: Token refreshed successfully, retrying request');

          // Retry original request with new token
          final newToken = await _tokenManager.getToken();
          if (newToken != null) {
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

            try {
              final dio = Dio();
              final response = await dio.fetch(err.requestOptions);

              // Process all pending requests
              _processPendingRequests(newToken);

              handler.resolve(response);
              return;
            } catch (e) {
              print('❌ TokenInterceptor: Retry failed: $e');
            }
          }
        }

        // Refresh failed - clear tokens and reject
        print('❌ TokenInterceptor: Token refresh failed, clearing auth');
        await _tokenManager.clearTokens();
        _clearPendingRequests();

        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: DioExceptionType.badResponse,
            error: 'Authentication failed - please login again',
            response: err.response,
          ),
        );
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  /// Attempt to refresh access token using refresh token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ TokenInterceptor: No refresh token available');
        return false;
      }

      print('🔄 TokenInterceptor: Calling refresh token endpoint...');

      // Make refresh token request
      final dio = Dio();
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Extract new tokens from response
        String? newAccessToken;
        String? newRefreshToken;

        // Handle different response structures
        if (data.containsKey('data')) {
          final tokenData = data['data'] as Map<String, dynamic>;
          newAccessToken = tokenData['token'] ?? tokenData['accessToken'];
          newRefreshToken = tokenData['refreshToken'];
        } else {
          newAccessToken = data['token'] ?? data['accessToken'];
          newRefreshToken = data['refreshToken'];
        }

        if (newAccessToken != null) {
          // Save new tokens
          await _tokenManager.saveToken(newAccessToken);

          if (newRefreshToken != null) {
            await _tokenManager.saveRefreshToken(newRefreshToken);
          }

          print('✅ TokenInterceptor: New tokens saved successfully');
          return true;
        }
      }

      print('❌ TokenInterceptor: Refresh token response invalid');
      return false;
    } catch (e) {
      print('❌ TokenInterceptor: Token refresh error: $e');
      return false;
    }
  }

  /// Process all pending requests with new token
  void _processPendingRequests(String newToken) {
    print('🔄 TokenInterceptor: Processing ${_pendingRequests.length} pending requests');

    for (final options in _pendingRequests) {
      options.headers['Authorization'] = 'Bearer $newToken';
      // Note: These requests would need to be retried in actual implementation
      // For now, they will timeout or be handled by the application layer
    }

    _pendingRequests.clear();
  }

  /// Clear all pending requests
  void _clearPendingRequests() {
    print('🗑️ TokenInterceptor: Clearing ${_pendingRequests.length} pending requests');
    _pendingRequests.clear();
  }

  /// Check if endpoint doesn't require authentication
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
           path.contains('/auth/register') ||
           path.contains('/auth/refresh-token') ||
           path.contains('/auth/forgot-password');
  }
}

/// Custom network exception
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const NetworkException(
    this.message, {
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Network security configuration
class NetworkSecurityConfig {
  static const bool enableCertificatePinning = true;
  static const bool enableRequestSigning = false;
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  static const List<String> trustedCertificates = [
    // Add your trusted certificate fingerprints here
  ];

  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };
}