import 'package:jwt_decoder/jwt_decoder.dart';
import '../storage/secure_storage_service.dart';

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

  void dispose() {
    // Clean up any resources
  }
}