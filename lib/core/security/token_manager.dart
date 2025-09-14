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

  bool isTokenExpired(String token) {
    // Simple check - in real app would decode JWT and check exp claim
    // For now, return false to allow testing
    return false;
  }

  void dispose() {
    // Clean up any resources
  }
}