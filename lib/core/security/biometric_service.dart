import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../storage/secure_storage_service.dart';

/// Comprehensive biometric authentication service
class BiometricService {
  final LocalAuthentication _localAuth;
  final SecureStorageService _secureStorage;

  BiometricService({
    required LocalAuthentication localAuth,
    required SecureStorageService secureStorage,
  })  : _localAuth = localAuth,
        _secureStorage = secureStorage;

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if specific biometric type is available
  Future<bool> isBiometricTypeAvailable(BiometricType type) async {
    final availableBiometrics = await getAvailableBiometrics();
    return availableBiometrics.contains(type);
  }

  /// Check if biometric authentication is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: 'biometric_enabled');
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    if (!await isBiometricAvailable()) {
      throw BiometricException('Biometric authentication not available');
    }

    // Test biometric authentication before enabling
    final authenticated = await authenticate(
      reason: 'Biyometrik kimlik doğrulamayı etkinleştirmek için doğrulayın',
    );

    if (authenticated) {
      await _secureStorage.write(key: 'biometric_enabled', value: 'true');
    } else {
      throw BiometricException('Biometric authentication test failed');
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.write(key: 'biometric_enabled', value: 'false');
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = true,
    bool sensitiveTransaction = true,
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        throw BiometricException('Biometric authentication not available');
      }

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );

      return result;
    } on PlatformException catch (e) {
      _handleBiometricError(e);
      return false;
    } catch (e) {
      throw BiometricException('Authentication failed: $e');
    }
  }

  /// Authenticate for login
  Future<bool> authenticateForLogin() async {
    return authenticate(
      reason: 'ZiraAI\'ya giriş yapmak için biyometrik kimlik doğrulaması kullanın',
      biometricOnly: true,
      stickyAuth: true,
      sensitiveTransaction: true,
    );
  }

  /// Authenticate for sensitive transaction
  Future<bool> authenticateForTransaction() async {
    return authenticate(
      reason: 'Bu işlemi onaylamak için biyometrik kimlik doğrulaması gerekli',
      biometricOnly: true,
      stickyAuth: true,
      sensitiveTransaction: true,
    );
  }

  /// Authenticate for settings access
  Future<bool> authenticateForSettings() async {
    return authenticate(
      reason: 'Güvenlik ayarlarına erişmek için doğrulayın',
      biometricOnly: false,
      stickyAuth: false,
      sensitiveTransaction: false,
    );
  }

  /// Get biometric capability information
  Future<BiometricCapability> getBiometricCapability() async {
    final isAvailable = await isBiometricAvailable();
    final availableBiometrics = await getAvailableBiometrics();
    final isEnabled = await isBiometricEnabled();

    return BiometricCapability(
      isAvailable: isAvailable,
      isEnabled: isEnabled,
      availableBiometrics: availableBiometrics,
      hasFingerprint: availableBiometrics.contains(BiometricType.fingerprint),
      hasFaceRecognition: availableBiometrics.contains(BiometricType.face),
      hasIris: availableBiometrics.contains(BiometricType.iris),
      hasStrongBiometrics: availableBiometrics.contains(BiometricType.strong),
      hasWeakBiometrics: availableBiometrics.contains(BiometricType.weak),
    );
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Yüz Tanıma';
      case BiometricType.fingerprint:
        return 'Parmak İzi';
      case BiometricType.iris:
        return 'İris Tanıma';
      case BiometricType.strong:
        return 'Güçlü Biyometrik';
      case BiometricType.weak:
        return 'Zayıf Biyometrik';
    }
  }

  /// Get security level based on available biometrics
  Future<BiometricSecurityLevel> getSecurityLevel() {
    final capability = getBiometricCapability();

    return capability.then((cap) {
      if (!cap.isAvailable) return BiometricSecurityLevel.none;

      if (cap.hasStrongBiometrics || cap.hasFaceRecognition || cap.hasFingerprint) {
        return BiometricSecurityLevel.high;
      } else if (cap.hasWeakBiometrics) {
        return BiometricSecurityLevel.medium;
      } else {
        return BiometricSecurityLevel.low;
      }
    });
  }

  /// Handle biometric authentication errors
  void _handleBiometricError(PlatformException error) {
    switch (error.code) {
      case 'NotAvailable':
        throw BiometricException('Biyometrik kimlik doğrulama bu cihazda mevcut değil');
      case 'NotEnrolled':
        throw BiometricException('Biyometrik veri kayıtlı değil. Lütfen cihaz ayarlarından kayıt yapın');
      case 'LockedOut':
        throw BiometricException('Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin');
      case 'PermanentlyLockedOut':
        throw BiometricException('Biyometrik kimlik doğrulama kalıcı olarak kilitlendi');
      case 'BiometricOnlyNotSupported':
        throw BiometricException('Bu cihaz sadece biyometrik kimlik doğrulamayı desteklemiyor');
      case 'UserCancel':
        throw BiometricException('Kullanıcı kimlik doğrulamayı iptal etti');
      case 'UserFallback':
        throw BiometricException('Kullanıcı alternatif kimlik doğrulama yöntemini seçti');
      case 'SystemCancel':
        throw BiometricException('Sistem tarafından iptal edildi');
      case 'InvalidContext':
        throw BiometricException('Geçersiz kimlik doğrulama bağlamı');
      case 'NotSupported':
        throw BiometricException('Bu işlem desteklenmiyor');
      default:
        throw BiometricException('Biyometrik kimlik doğrulama hatası: ${error.message}');
    }
  }

  /// Store biometric template hash for additional security
  Future<void> storeBiometricTemplate(String templateHash) async {
    await _secureStorage.write(key: 'biometric_template_hash', value: templateHash);
  }

  /// Verify biometric template hash
  Future<bool> verifyBiometricTemplate(String templateHash) async {
    try {
      final storedHash = await _secureStorage.read(key: 'biometric_template_hash');
      return storedHash == templateHash;
    } catch (e) {
      return false;
    }
  }

  /// Reset biometric settings
  Future<void> resetBiometricSettings() async {
    await _secureStorage.delete(key: 'biometric_enabled');
    await _secureStorage.delete(key: 'biometric_template_hash');
  }
}

/// Biometric capability information
class BiometricCapability {
  final bool isAvailable;
  final bool isEnabled;
  final List<BiometricType> availableBiometrics;
  final bool hasFingerprint;
  final bool hasFaceRecognition;
  final bool hasIris;
  final bool hasStrongBiometrics;
  final bool hasWeakBiometrics;

  const BiometricCapability({
    required this.isAvailable,
    required this.isEnabled,
    required this.availableBiometrics,
    required this.hasFingerprint,
    required this.hasFaceRecognition,
    required this.hasIris,
    required this.hasStrongBiometrics,
    required this.hasWeakBiometrics,
  });

  /// Check if device has any strong biometric authentication
  bool get hasAnyStrongBiometric =>
      hasFingerprint || hasFaceRecognition || hasIris || hasStrongBiometrics;

  /// Get primary biometric type
  BiometricType? get primaryBiometricType {
    if (hasFingerprint) return BiometricType.fingerprint;
    if (hasFaceRecognition) return BiometricType.face;
    if (hasIris) return BiometricType.iris;
    if (hasStrongBiometrics) return BiometricType.strong;
    if (hasWeakBiometrics) return BiometricType.weak;
    return null;
  }

  /// Get user-friendly description of available biometrics
  String get description {
    final types = <String>[];
    if (hasFingerprint) types.add('Parmak İzi');
    if (hasFaceRecognition) types.add('Yüz Tanıma');
    if (hasIris) types.add('İris Tanıma');

    if (types.isEmpty) {
      return 'Biyometrik kimlik doğrulama mevcut değil';
    } else if (types.length == 1) {
      return '${types.first} mevcut';
    } else {
      return '${types.sublist(0, types.length - 1).join(', ')} ve ${types.last} mevcut';
    }
  }
}

/// Biometric security levels
enum BiometricSecurityLevel {
  none('Yok'),
  low('Düşük'),
  medium('Orta'),
  high('Yüksek');

  const BiometricSecurityLevel(this.description);
  final String description;
}

/// Custom exception for biometric authentication errors
class BiometricException implements Exception {
  final String message;
  const BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}