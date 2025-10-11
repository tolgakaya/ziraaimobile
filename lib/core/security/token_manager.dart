import 'package:jwt_decoder/jwt_decoder.dart';
import '../storage/secure_storage_service.dart';
import '../config/api_config.dart';

class TokenManager {
  final SecureStorageService _secureStorage;

  TokenManager(this._secureStorage);

  Future<void> initialize() async {
    // Initialize any required resources
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<String?> getAccessToken() async {
    return await getToken();
  }

  Future<String?> getValidAccessToken() async {
    final token = await getAccessToken();
    if (token != null && !isTokenExpired(token)) {
      return token;
    }
    return null;
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty && !isTokenExpired(token);
  }

  /// Check if JWT token is expired
  /// Returns true if token is expired or will expire in next 60 seconds (buffer time)
  bool isTokenExpired(String token) {
    try {
      // Decode JWT and check expiration
      if (JwtDecoder.isExpired(token)) {
        print('🔑 TokenManager: Token is expired');
        return true;
      }

      // Get token expiration time
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();

      // Add 60 second buffer - refresh if token expires in next minute
      final bufferTime = const Duration(seconds: 60);
      final expirationWithBuffer = expirationDate.subtract(bufferTime);

      final isExpiringSoon = now.isAfter(expirationWithBuffer);

      if (isExpiringSoon) {
        print('🔑 TokenManager: Token expiring soon (within 60s)');
      }

      return isExpiringSoon;
    } catch (e) {
      print('⚠️ TokenManager: Error checking token expiration: $e');
      // If we can't decode token, consider it expired for safety
      return true;
    }
  }

  /// Get token expiration date
  DateTime? getTokenExpirationDate(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      print('⚠️ TokenManager: Error getting token expiration date: $e');
      return null;
    }
  }

  /// Get time remaining until token expiration
  Duration? getTokenTimeRemaining(String token) {
    try {
      final expirationDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();

      if (expirationDate.isAfter(now)) {
        return expirationDate.difference(now);
      }
      return Duration.zero;
    } catch (e) {
      print('⚠️ TokenManager: Error getting token time remaining: $e');
      return null;
    }
  }

  /// Check if token belongs to current environment
  /// Returns false if token is for different environment (e.g., production token in staging)
  bool isTokenForCurrentEnvironment(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final issuer = decodedToken['iss'] as String?;

      if (issuer == null) {
        print('⚠️ TokenManager: Token has no issuer claim');
        return false;
      }

      // Map environment to expected issuer
      String expectedIssuer;
      switch (ApiConfig.environment) {
        case Environment.production:
          expectedIssuer = 'ZiraAI_Prod';
          break;
        case Environment.staging:
          expectedIssuer = 'ZiraAI_Staging';
          break;
        case Environment.development:
          expectedIssuer = 'ZiraAI_Dev';
          break;
        case Environment.local:
          expectedIssuer = 'ZiraAI_Local';
          break;
      }

      final isValid = issuer == expectedIssuer;

      if (!isValid) {
        print('⚠️ TokenManager: Token environment mismatch!');
        print('   Token issuer: $issuer');
        print('   Expected issuer: $expectedIssuer');
        print('   Current environment: ${ApiConfig.environment}');
      }

      return isValid;
    } catch (e) {
      print('⚠️ TokenManager: Error checking token environment: $e');
      return false;
    }
  }

  /// Get user roles from JWT token
  /// Returns list of roles from token claims
  Future<List<String>> getUserRoles() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        print('⚠️ TokenManager: No token available for role extraction');
        return [];
      }

      final decodedToken = JwtDecoder.decode(token);

      // Try different possible role claim names
      final roleClaim = decodedToken['role'] ??
                       decodedToken['roles'] ??
                       decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

      if (roleClaim == null) {
        print('⚠️ TokenManager: No role claim found in token');
        return [];
      }

      // Handle both single role (string) and multiple roles (list)
      if (roleClaim is String) {
        print('✅ TokenManager: Found role: $roleClaim');
        return [roleClaim];
      } else if (roleClaim is List) {
        final roles = roleClaim.cast<String>();
        print('✅ TokenManager: Found roles: $roles');
        return roles;
      }

      print('⚠️ TokenManager: Role claim has unexpected type: ${roleClaim.runtimeType}');
      return [];
    } catch (e) {
      print('⚠️ TokenManager: Error extracting user roles: $e');
      return [];
    }
  }

  /// Check if user has a specific role
  Future<bool> hasRole(String role) async {
    final roles = await getUserRoles();
    return roles.contains(role);
  }

  void dispose() {
    // Clean up any resources
  }
}