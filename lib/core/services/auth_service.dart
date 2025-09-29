import '../storage/secure_storage_service.dart';

abstract class AuthService {
  Future<String?> getToken();
  Future<bool> isAuthenticated();
}

class AuthServiceImpl implements AuthService {
  final SecureStorageService _secureStorage;

  AuthServiceImpl(this._secureStorage);

  @override
  Future<String?> getToken() async {
    try {
      return await _secureStorage.getToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}