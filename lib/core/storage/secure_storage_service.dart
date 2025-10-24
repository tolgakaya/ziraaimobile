import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@injectable
class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  // Authentication specific methods
  Future<String?> getToken() async {
    return await read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await delete(key: 'auth_token');
  }

  // Refresh token specific methods
  Future<String?> getRefreshToken() async {
    return await read(key: 'refresh_token');
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await delete(key: 'refresh_token');
  }
}