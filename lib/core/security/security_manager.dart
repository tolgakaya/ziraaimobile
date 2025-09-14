import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../storage/secure_storage_service.dart';
import 'token_manager.dart';
import 'biometric_service.dart';
import 'input_validator.dart';
import 'security_level.dart';
import 'secure_storage_keys.dart';

/// Central security manager for the ZiraAI application
class SecurityManager {
  final SecureStorageService _secureStorage;
  final TokenManager _tokenManager;
  final BiometricService _biometricService;

  Timer? _sessionTimer;
  Timer? _securityCheckTimer;
  DateTime? _lastActivity;
  int _failedLoginAttempts = 0;
  bool _isAccountLocked = false;
  SecurityLevel _currentSecurityLevel = SecurityLevel.standard;

  SecurityManager({
    required SecureStorageService secureStorage,
    required TokenManager tokenManager,
    required BiometricService biometricService,
  })  : _secureStorage = secureStorage,
        _tokenManager = tokenManager,
        _biometricService = biometricService;

  /// Initialize security manager
  Future<void> initialize() async {
    await _loadSecuritySettings();
    await _initializeDeviceFingerprint();
    await _checkAccountLockStatus();
    _startSecurityMonitoring();
    await _tokenManager.initialize();
  }

  /// Authenticate user with comprehensive security checks
  Future<AuthenticationResult> authenticateUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // Check if account is locked
    if (await _isAccountCurrentlyLocked()) {
      return AuthenticationResult.failure(
        'Hesap geçici olarak kilitlendi. Lütfen daha sonra deneyin.',
        AuthenticationFailureReason.accountLocked,
      );
    }

    // Validate input
    final emailValidation = InputValidator.validateEmail(email);
    final passwordValidation = InputValidator.validatePassword(password);

    if (!emailValidation.isValid) {
      return AuthenticationResult.failure(
        emailValidation.error!,
        AuthenticationFailureReason.invalidInput,
      );
    }

    if (!passwordValidation.isValid) {
      return AuthenticationResult.failure(
        passwordValidation.error!,
        AuthenticationFailureReason.invalidInput,
      );
    }

    try {
      // Perform device security checks
      await _performDeviceSecurityChecks();

      // Increment login attempt
      await _recordLoginAttempt();

      // Here you would typically make an API call to authenticate
      // For now, we'll simulate the authentication process
      final authSuccess = await _simulateAuthenticationCall(
        emailValidation.validValue,
        password,
      );

      if (authSuccess) {
        // Reset failed attempts on success
        await _resetFailedLoginAttempts();

        // Store session information
        await _createSecureSession(emailValidation.validValue, rememberMe);

        // Start session monitoring
        _startSessionMonitoring();

        return AuthenticationResult.success('Giriş başarılı');
      } else {
        await _handleFailedLogin();
        return AuthenticationResult.failure(
          'Geçersiz e-posta veya şifre',
          AuthenticationFailureReason.invalidCredentials,
        );
      }
    } catch (e) {
      await _handleFailedLogin();
      return AuthenticationResult.failure(
        'Giriş işlemi sırasında hata oluştu: $e',
        AuthenticationFailureReason.systemError,
      );
    }
  }

  /// Authenticate with biometrics
  Future<AuthenticationResult> authenticateWithBiometric() async {
    try {
      if (!await _biometricService.isBiometricEnabled()) {
        return AuthenticationResult.failure(
          'Biyometrik kimlik doğrulama etkinleştirilmemiş',
          AuthenticationFailureReason.biometricNotEnabled,
        );
      }

      final authenticated = await _biometricService.authenticateForLogin();

      if (authenticated) {
        // Load stored user info
        final userEmail = await _secureStorage.read(key: SecureStorageKeys.userEmail);
        if (userEmail != null) {
          await _createSecureSession(userEmail, true);
          _startSessionMonitoring();
          return AuthenticationResult.success('Biyometrik giriş başarılı');
        } else {
          return AuthenticationResult.failure(
            'Kullanıcı bilgileri bulunamadı',
            AuthenticationFailureReason.systemError,
          );
        }
      } else {
        return AuthenticationResult.failure(
          'Biyometrik kimlik doğrulama başarısız',
          AuthenticationFailureReason.biometricFailed,
        );
      }
    } catch (e) {
      return AuthenticationResult.failure(
        'Biyometrik kimlik doğrulama hatası: $e',
        AuthenticationFailureReason.systemError,
      );
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isUserAuthenticated() async {
    final accessToken = await _tokenManager.getValidAccessToken();
    return accessToken != null;
  }

  /// Logout user securely
  Future<void> logout() async {
    try {
      // Clear all tokens
      await _tokenManager.clearTokens();

      // Clear session data
      await _clearSecureSession();

      // Stop monitoring
      _stopSessionMonitoring();
      _stopSecurityMonitoring();

      // Log security event
      await _logSecurityEvent('User logout', SecurityEventLevel.info);
    } catch (e) {
      await _logSecurityEvent('Logout error: $e', SecurityEventLevel.error);
    }
  }

  /// Set security level
  Future<void> setSecurityLevel(SecurityLevel level) async {
    _currentSecurityLevel = level;
    await _secureStorage.write(
      key: SecureStorageKeys.securityLevel,
      value: level.toString(),
    );

    // Apply security level settings
    await _applySecurityLevelSettings(level);

    await _logSecurityEvent(
      'Security level changed to ${level.name}',
      SecurityEventLevel.info,
    );
  }

  /// Get current security level
  Future<SecurityLevel> getSecurityLevel() async {
    return _currentSecurityLevel;
  }

  /// Record user activity for session management
  void recordUserActivity() {
    _lastActivity = DateTime.now();

    // Reset session timer
    _resetSessionTimer();
  }

  /// Check device security posture
  Future<DeviceSecurityStatus> checkDeviceSecurityStatus() async {
    final issues = <SecurityIssue>[];

    // Check if device is rooted/jailbroken
    if (await _isDeviceRooted()) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.deviceCompromised,
        severity: SecuritySeverity.high,
        description: 'Cihaz root/jailbreak edilmiş olabilir',
      ));
    }

    // Check biometric availability
    if (!await _biometricService.isBiometricAvailable()) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.biometricUnavailable,
        severity: SecuritySeverity.medium,
        description: 'Biyometrik kimlik doğrulama mevcut değil',
      ));
    }

    // Check if screen lock is enabled
    if (!await _isScreenLockEnabled()) {
      issues.add(SecurityIssue(
        type: SecurityIssueType.screenLockDisabled,
        severity: SecuritySeverity.medium,
        description: 'Ekran kilidi etkinleştirilmemiş',
      ));
    }

    // Calculate overall security score
    final securityScore = _calculateSecurityScore(issues);

    return DeviceSecurityStatus(
      securityScore: securityScore,
      issues: issues,
      isSecure: securityScore >= 80 && issues.where((i) => i.severity == SecuritySeverity.high).isEmpty,
    );
  }

  /// Generate secure session ID
  Future<String> _generateSecureSessionId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomBytes = List.generate(32, (_) => random.nextInt(256));
    final deviceId = await _getDeviceId();

    final data = '$timestamp-$deviceId-${randomBytes.join('')}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Create secure session
  Future<void> _createSecureSession(String userEmail, bool rememberMe) async {
    final sessionId = await _generateSecureSessionId();
    final sessionStartTime = DateTime.now();

    await _secureStorage.write(key: SecureStorageKeys.sessionId, value: sessionId);
    await _secureStorage.write(
      key: SecureStorageKeys.sessionStartTime,
      value: sessionStartTime.millisecondsSinceEpoch.toString(),
    );
    await _secureStorage.write(key: SecureStorageKeys.userEmail, value: userEmail);
    await _secureStorage.write(
      key: SecureStorageKeys.rememberMe,
      value: rememberMe.toString(),
    );
    await _secureStorage.write(
      key: SecureStorageKeys.lastLoginTime,
      value: sessionStartTime.millisecondsSinceEpoch.toString(),
    );

    _lastActivity = sessionStartTime;
  }

  /// Clear secure session
  Future<void> _clearSecureSession() async {
    await _secureStorage.delete(key: SecureStorageKeys.sessionId);
    await _secureStorage.delete(key: SecureStorageKeys.sessionStartTime);
    await _secureStorage.delete(key: SecureStorageKeys.userEmail);
    await _secureStorage.delete(key: SecureStorageKeys.rememberMe);
    await _secureStorage.delete(key: SecureStorageKeys.backgroundTime);
  }

  /// Start session monitoring
  void _startSessionMonitoring() {
    _resetSessionTimer();
  }

  /// Reset session timer based on security level
  void _resetSessionTimer() {
    _sessionTimer?.cancel();

    final timeout = _currentSecurityLevel.autoLogoutDuration;
    _sessionTimer = Timer(timeout, () async {
      await _logSecurityEvent('Session timeout', SecurityEventLevel.warning);
      await logout();
    });
  }

  /// Stop session monitoring
  void _stopSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Start security monitoring
  void _startSecurityMonitoring() {
    _securityCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performPeriodicSecurityChecks(),
    );
  }

  /// Stop security monitoring
  void _stopSecurityMonitoring() {
    _securityCheckTimer?.cancel();
    _securityCheckTimer = null;
  }

  /// Perform periodic security checks
  Future<void> _performPeriodicSecurityChecks() async {
    try {
      // Check if tokens are still valid
      final accessToken = await _tokenManager.getAccessToken();
      if (accessToken != null && _tokenManager.isTokenExpired(accessToken)) {
        await _logSecurityEvent('Token expired during session', SecurityEventLevel.warning);
        await logout();
        return;
      }

      // Check device security status
      final securityStatus = await checkDeviceSecurityStatus();
      if (!securityStatus.isSecure) {
        await _logSecurityEvent(
          'Device security compromised: ${securityStatus.issues.length} issues found',
          SecurityEventLevel.error,
        );
      }

      // Check for suspicious activity patterns
      await _detectSuspiciousActivity();

    } catch (e) {
      await _logSecurityEvent('Security check error: $e', SecurityEventLevel.error);
    }
  }

  /// Detect suspicious activity patterns
  Future<void> _detectSuspiciousActivity() async {
    // Implement suspicious activity detection logic
    // This could include rapid API calls, unusual access patterns, etc.
  }

  /// Perform device security checks
  Future<void> _performDeviceSecurityChecks() async {
    // Check for root/jailbreak
    if (await _isDeviceRooted()) {
      await _logSecurityEvent('Device appears to be rooted/jailbroken', SecurityEventLevel.high);
    }

    // Check device fingerprint
    final currentFingerprint = await _generateDeviceFingerprint();
    final storedFingerprint = await _secureStorage.read(key: SecureStorageKeys.deviceFingerprint);

    if (storedFingerprint != null && storedFingerprint != currentFingerprint) {
      await _logSecurityEvent('Device fingerprint mismatch', SecurityEventLevel.high);
    }
  }

  /// Load security settings
  Future<void> _loadSecuritySettings() async {
    final levelString = await _secureStorage.read(key: SecureStorageKeys.securityLevel);
    if (levelString != null) {
      final levelInt = int.tryParse(levelString) ?? 1;
      _currentSecurityLevel = SecurityLevel.values.firstWhere(
        (level) => level.level == levelInt,
        orElse: () => SecurityLevel.standard,
      );
    }

    final failedAttemptsString = await _secureStorage.read(key: SecureStorageKeys.failedLoginAttempts);
    if (failedAttemptsString != null) {
      _failedLoginAttempts = int.tryParse(failedAttemptsString) ?? 0;
    }
  }

  /// Apply security level settings
  Future<void> _applySecurityLevelSettings(SecurityLevel level) async {
    // Apply timeout settings
    _resetSessionTimer();

    // Enable/disable biometric authentication
    if (level.requiresBiometric && await _biometricService.isBiometricAvailable()) {
      await _biometricService.enableBiometric();
    }

    // Apply other security settings based on level
    await _logSecurityEvent(
      'Applied security level settings: ${level.name}',
      SecurityEventLevel.info,
    );
  }

  /// Record login attempt
  Future<void> _recordLoginAttempt() async {
    // Log login attempt with timestamp and device info
    await _logSecurityEvent('Login attempt', SecurityEventLevel.info);
  }

  /// Handle failed login
  Future<void> _handleFailedLogin() async {
    _failedLoginAttempts++;
    await _secureStorage.write(
      key: SecureStorageKeys.failedLoginAttempts,
      value: _failedLoginAttempts.toString(),
    );

    await _logSecurityEvent(
      'Failed login attempt ($_failedLoginAttempts total)',
      SecurityEventLevel.warning,
    );

    // Lock account if too many failed attempts
    if (_failedLoginAttempts >= 5) {
      await _lockAccount();
    }
  }

  /// Reset failed login attempts
  Future<void> _resetFailedLoginAttempts() async {
    _failedLoginAttempts = 0;
    await _secureStorage.delete(key: SecureStorageKeys.failedLoginAttempts);
    await _secureStorage.delete(key: SecureStorageKeys.accountLocked);
    await _secureStorage.delete(key: SecureStorageKeys.lockoutTime);
    _isAccountLocked = false;
  }

  /// Lock account temporarily
  Future<void> _lockAccount() async {
    _isAccountLocked = true;
    final lockoutTime = DateTime.now().add(const Duration(minutes: 15));

    await _secureStorage.write(key: SecureStorageKeys.accountLocked, value: 'true');
    await _secureStorage.write(
      key: SecureStorageKeys.lockoutTime,
      value: lockoutTime.millisecondsSinceEpoch.toString(),
    );

    await _logSecurityEvent('Account locked due to failed attempts', SecurityEventLevel.high);
  }

  /// Check if account is currently locked
  Future<bool> _isAccountCurrentlyLocked() async {
    if (!_isAccountLocked) return false;

    final lockoutTimeString = await _secureStorage.read(key: SecureStorageKeys.lockoutTime);
    if (lockoutTimeString == null) return false;

    final lockoutTime = DateTime.fromMillisecondsSinceEpoch(int.parse(lockoutTimeString));
    if (DateTime.now().isAfter(lockoutTime)) {
      // Lockout period has expired
      await _resetFailedLoginAttempts();
      return false;
    }

    return true;
  }

  /// Check account lock status on initialization
  Future<void> _checkAccountLockStatus() async {
    final isLocked = await _secureStorage.read(key: SecureStorageKeys.accountLocked);
    _isAccountLocked = isLocked == 'true';

    if (_isAccountLocked) {
      await _isAccountCurrentlyLocked(); // This will reset if expired
    }
  }

  /// Initialize device fingerprint
  Future<void> _initializeDeviceFingerprint() async {
    final fingerprint = await _generateDeviceFingerprint();
    await _secureStorage.write(key: SecureStorageKeys.deviceFingerprint, value: fingerprint);
  }

  /// Generate device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    final deviceId = await _getDeviceId();
    final deviceModel = await _getDeviceModel();
    final osVersion = await _getOSVersion();

    final data = '$deviceId-$deviceModel-$osVersion';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Simulate authentication API call
  Future<bool> _simulateAuthenticationCall(String email, String password) async {
    // In a real implementation, this would make an API call
    // For demo purposes, we'll simulate success
    await Future.delayed(const Duration(milliseconds: 500));
    return email.isNotEmpty && password.isNotEmpty;
  }

  /// Log security event
  Future<void> _logSecurityEvent(String event, SecurityEventLevel level) async {
    final timestamp = DateTime.now();
    final logEntry = {
      'timestamp': timestamp.toIso8601String(),
      'event': event,
      'level': level.name,
      'device_id': await _getDeviceId(),
    };

    print('Security Log: ${jsonEncode(logEntry)}');

    // In a real implementation, you might want to store these logs
    // or send them to a security monitoring service
  }

  /// Platform-specific methods (would need proper implementation)
  Future<String> _getDeviceId() async => 'device_id_placeholder';
  Future<String> _getDeviceModel() async => 'device_model_placeholder';
  Future<String> _getOSVersion() async => 'os_version_placeholder';
  Future<bool> _isDeviceRooted() async => false;
  Future<bool> _isScreenLockEnabled() async => true;

  /// Calculate security score
  int _calculateSecurityScore(List<SecurityIssue> issues) {
    int baseScore = 100;

    for (final issue in issues) {
      switch (issue.severity) {
        case SecuritySeverity.high:
          baseScore -= 30;
          break;
        case SecuritySeverity.medium:
          baseScore -= 15;
          break;
        case SecuritySeverity.low:
          baseScore -= 5;
          break;
      }
    }

    return baseScore.clamp(0, 100);
  }

  /// Dispose resources
  void dispose() {
    _stopSessionMonitoring();
    _stopSecurityMonitoring();
    _tokenManager.dispose();
  }
}

/// Authentication result
class AuthenticationResult {
  final bool isSuccess;
  final String message;
  final AuthenticationFailureReason? failureReason;

  const AuthenticationResult.success(this.message)
      : isSuccess = true,
        failureReason = null;

  const AuthenticationResult.failure(this.message, this.failureReason)
      : isSuccess = false;
}

/// Authentication failure reasons
enum AuthenticationFailureReason {
  invalidCredentials,
  invalidInput,
  accountLocked,
  biometricNotEnabled,
  biometricFailed,
  systemError,
}

/// Device security status
class DeviceSecurityStatus {
  final int securityScore;
  final List<SecurityIssue> issues;
  final bool isSecure;

  const DeviceSecurityStatus({
    required this.securityScore,
    required this.issues,
    required this.isSecure,
  });
}

/// Security issue
class SecurityIssue {
  final SecurityIssueType type;
  final SecuritySeverity severity;
  final String description;

  const SecurityIssue({
    required this.type,
    required this.severity,
    required this.description,
  });
}

/// Security issue types
enum SecurityIssueType {
  deviceCompromised,
  biometricUnavailable,
  screenLockDisabled,
  networkInsecure,
  appTampering,
}

/// Security severity levels
enum SecuritySeverity {
  low,
  medium,
  high,
}

/// Security event levels
enum SecurityEventLevel {
  info,
  warning,
  error,
  high,
}