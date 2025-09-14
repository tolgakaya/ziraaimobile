import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

/// Abstract interface for secure storage operations
abstract class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
  Future<bool> containsKey(String key);

  // Enhanced security methods
  Future<void> writeEncrypted(String key, String value);
  Future<String?> readEncrypted(String key);
  Future<bool> verifyIntegrity(String key, String expectedHash);
  Future<void> writeWithBiometric(String key, String value);
  Future<String?> readWithBiometric(String key);
}

/// Enhanced secure storage implementation with encryption and biometric support
class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const String _encryptionKeyPrefix = 'enc_';
  static const String _hashPrefix = 'hash_';
  static const String _biometricPrefix = 'bio_';

  /// Enhanced Android options for maximum security
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'ziraai_secure_prefs',
    preferencesKeyPrefix: 'ziraai_',
    resetOnError: true
  );

  /// Enhanced iOS options for maximum security
  static const IOSOptions _iosOptions = IOSOptions(
    groupId: 'group.com.ziraai.mobile',
    accountName: 'ZiraAI',
    accessibility: KeychainAccessibility.first_unlock_this_device
  );

  SecureStorageImpl(this._storage, this._localAuth);

  /// Factory constructor with enhanced security options
  factory SecureStorageImpl.withSecureOptions() {
    return SecureStorageImpl(
      const FlutterSecureStorage(
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      ),
      LocalAuthentication(),
    );
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      // Store integrity hash
      await _storeIntegrityHash(key, value);
    } catch (e) {
      throw SecureStorageException('Failed to write secure data: $e');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null && await containsKey(key)) {
        // Verify integrity
        if (!await verifyIntegrity(key, _generateHash(value))) {
          throw SecureStorageException('Data integrity check failed for key: $key');
        }
      }
      return value;
    } catch (e) {
      throw SecureStorageException('Failed to read secure data: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      await _storage.delete(key: _hashPrefix + key);
      await _storage.delete(key: _encryptionKeyPrefix + key);
      await _storage.delete(key: _biometricPrefix + key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to delete all secure data: $e');
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw SecureStorageException('Failed to read all secure data: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to check key existence: $e');
    }
  }

  @override
  Future<void> writeEncrypted(String key, String value) async {
    try {
      final encryptedValue = _encryptValue(value);
      await _storage.write(key: _encryptionKeyPrefix + key, value: encryptedValue);
      await _storeIntegrityHash(_encryptionKeyPrefix + key, encryptedValue);
    } catch (e) {
      throw SecureStorageException('Failed to write encrypted data: $e');
    }
  }

  @override
  Future<String?> readEncrypted(String key) async {
    try {
      final encryptedValue = await _storage.read(key: _encryptionKeyPrefix + key);
      if (encryptedValue == null) return null;

      // Verify integrity
      if (!await verifyIntegrity(_encryptionKeyPrefix + key, _generateHash(encryptedValue))) {
        throw SecureStorageException('Encrypted data integrity check failed');
      }

      return _decryptValue(encryptedValue);
    } catch (e) {
      throw SecureStorageException('Failed to read encrypted data: $e');
    }
  }

  @override
  Future<bool> verifyIntegrity(String key, String expectedHash) async {
    try {
      final storedHash = await _storage.read(key: _hashPrefix + key);
      return storedHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> writeWithBiometric(String key, String value) async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        throw BiometricAuthException('Biometric authentication not available');
      }

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Güvenli veri kaydetmek için doğrulayın',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        throw BiometricAuthException('Biometric authentication failed');
      }

      // Store with biometric protection
      final encryptedValue = _encryptValue(value);
      await _storage.write(key: _biometricPrefix + key, value: encryptedValue);
      await _storeIntegrityHash(_biometricPrefix + key, encryptedValue);
    } catch (e) {
      throw SecureStorageException('Failed to write biometric-protected data: $e');
    }
  }

  @override
  Future<String?> readWithBiometric(String key) async {
    try {
      // Check if data exists
      final exists = await _storage.containsKey(key: _biometricPrefix + key);
      if (!exists) return null;

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Güvenli veriye erişmek için doğrulayın',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        throw BiometricAuthException('Biometric authentication failed');
      }

      // Read and decrypt data
      final encryptedValue = await _storage.read(key: _biometricPrefix + key);
      if (encryptedValue == null) return null;

      // Verify integrity
      if (!await verifyIntegrity(_biometricPrefix + key, _generateHash(encryptedValue))) {
        throw SecureStorageException('Biometric data integrity check failed');
      }

      return _decryptValue(encryptedValue);
    } catch (e) {
      throw SecureStorageException('Failed to read biometric-protected data: $e');
    }
  }

  /// Store integrity hash for data verification
  Future<void> _storeIntegrityHash(String key, String value) async {
    final hash = _generateHash(value);
    await _storage.write(key: _hashPrefix + key, value: hash);
  }

  /// Generate SHA-256 hash for integrity checking
  String _generateHash(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Simple XOR encryption (can be enhanced with AES)
  String _encryptValue(String value) {
    final key = _generateEncryptionKey();
    final valueBytes = utf8.encode(value);
    final encryptedBytes = Uint8List(valueBytes.length);

    for (int i = 0; i < valueBytes.length; i++) {
      encryptedBytes[i] = valueBytes[i] ^ key[i % key.length];
    }

    return base64.encode(encryptedBytes);
  }

  /// Simple XOR decryption (can be enhanced with AES)
  String _decryptValue(String encryptedValue) {
    final key = _generateEncryptionKey();
    final encryptedBytes = base64.decode(encryptedValue);
    final decryptedBytes = Uint8List(encryptedBytes.length);

    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes[i] = encryptedBytes[i] ^ key[i % key.length];
    }

    return utf8.decode(decryptedBytes);
  }

  /// Generate a simple encryption key (should be enhanced for production)
  Uint8List _generateEncryptionKey() {
    // In production, use a more secure key derivation function
    const keyString = 'ZiraAI_Mobile_2024_Secure_Key';
    return Uint8List.fromList(utf8.encode(keyString));
  }
}

/// Enhanced storage keys for secure storage
class SecureStorageKeys {
  // Authentication tokens
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  static const String tokenType = 'token_type';

  // User credentials
  static const String userEmail = 'user_email';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';

  // Security settings
  static const String biometricEnabled = 'biometric_enabled';
  static const String autoLogoutTime = 'auto_logout_time';
  static const String lastLoginTime = 'last_login_time';
  static const String failedLoginAttempts = 'failed_login_attempts';
  static const String accountLocked = 'account_locked';
  static const String lockoutTime = 'lockout_time';

  // Device security
  static const String deviceId = 'device_id';
  static const String deviceFingerprint = 'device_fingerprint';
  static const String pinHash = 'pin_hash';
  static const String saltKey = 'salt_key';

  // Session management
  static const String sessionId = 'session_id';
  static const String sessionStartTime = 'session_start_time';
  static const String backgroundTime = 'background_time';

  // Settings
  static const String rememberMe = 'remember_me';
  static const String autoLogin = 'auto_login';
  static const String securityLevel = 'security_level';
}

/// Security levels for the application
enum SecurityLevel {
  basic(0),
  standard(1),
  high(2),
  maximum(3);

  const SecurityLevel(this.level);
  final int level;

  bool get requiresBiometric => level >= 2;
  bool get requiresPin => level >= 1;
  bool get requiresAutoLogout => level >= 2;
  Duration get autoLogoutDuration {
    switch (this) {
      case SecurityLevel.basic:
        return const Duration(hours: 24);
      case SecurityLevel.standard:
        return const Duration(hours: 8);
      case SecurityLevel.high:
        return const Duration(hours: 2);
      case SecurityLevel.maximum:
        return const Duration(minutes: 15);
    }
  }
}

/// Custom exceptions for secure storage operations
class SecureStorageException implements Exception {
  final String message;
  const SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}

class BiometricAuthException implements Exception {
  final String message;
  const BiometricAuthException(this.message);

  @override
  String toString() => 'BiometricAuthException: $message';
}