# ZiraAI Mobile Security Implementation

## Overview

This document outlines the comprehensive security implementation for the ZiraAI mobile application, focusing on authentication, data protection, and secure communication practices.

## Security Architecture

### Core Components

1. **SecurityManager** - Central security controller
2. **TokenManager** - JWT token lifecycle management
3. **BiometricService** - Biometric authentication integration
4. **SecureStorage** - Enhanced encrypted storage
5. **SecureNetworkService** - SSL pinning and secure API communication
6. **InputValidator** - Input validation and sanitization

## Features Implemented

### 1. Enhanced Secure Storage

#### Key Features:
- **Multi-layer encryption**: XOR encryption with integrity verification
- **Biometric protection**: Data protected by device biometrics
- **Integrity checking**: SHA-256 hash verification for data tampering detection
- **Platform-specific security**: Enhanced Android and iOS keychain options

#### Usage:
```dart
final secureStorage = SecureStorageImpl.withSecureOptions();

// Basic secure storage
await secureStorage.write('key', 'value');
final value = await secureStorage.read('key');

// Encrypted storage
await secureStorage.writeEncrypted('secret_key', 'secret_value');
final secret = await secureStorage.readEncrypted('secret_key');

// Biometric-protected storage
await secureStorage.writeWithBiometric('biometric_key', 'protected_value');
final protected = await secureStorage.readWithBiometric('biometric_key');
```

### 2. JWT Token Management

#### Key Features:
- **Automatic refresh**: Tokens refreshed 5 minutes before expiry
- **Validation**: JWT structure and expiry validation
- **Secure storage**: Tokens stored with encryption and integrity checks
- **User context**: Automatic extraction of user information from tokens

#### Usage:
```dart
final tokenManager = TokenManager(
  secureStorage: secureStorage,
  apiClient: apiClient,
  dio: dio,
);

// Save tokens after login
await tokenManager.saveTokens(
  accessToken: accessToken,
  refreshToken: refreshToken,
);

// Get valid token (auto-refresh if needed)
final validToken = await tokenManager.getValidAccessToken();

// Check user permissions
final hasAdminRole = await tokenManager.hasRole('admin');
```

### 3. Biometric Authentication

#### Key Features:
- **Multi-biometric support**: Fingerprint, face recognition, iris scanning
- **Capability detection**: Automatic detection of available biometric methods
- **Security levels**: Different security requirements based on transaction type
- **Fallback handling**: Graceful degradation when biometrics unavailable

#### Usage:
```dart
final biometricService = BiometricService(
  localAuth: LocalAuthentication(),
  secureStorage: secureStorage,
);

// Check capability
final capability = await biometricService.getBiometricCapability();

// Authenticate for login
final loginSuccess = await biometricService.authenticateForLogin();

// Authenticate for sensitive transaction
final transactionSuccess = await biometricService.authenticateForTransaction();
```

### 4. Input Validation & Sanitization

#### Key Features:
- **Comprehensive validation**: Email, phone, password, agricultural codes
- **Security pattern detection**: XSS, SQL injection, path traversal
- **Turkish localization**: Specific validation for Turkish phone numbers and text
- **Sanitization**: Automatic cleaning of dangerous input patterns

#### Usage:
```dart
// Email validation
final emailResult = InputValidator.validateEmail(email);
if (emailResult.isValid) {
  final cleanEmail = emailResult.validValue;
}

// Password validation with security rules
final passwordResult = InputValidator.validatePassword(password);

// Turkish phone number validation
final phoneResult = InputValidator.validateTurkishPhone(phone);

// General text sanitization
final textResult = InputValidator.validateAndSanitizeText(
  userInput,
  minLength: 2,
  maxLength: 100,
  fieldName: 'Kullanıcı Adı',
);
```

### 5. Secure Network Communication

#### Key Features:
- **SSL certificate pinning**: Protection against man-in-the-middle attacks
- **Request sanitization**: Automatic cleaning of request data
- **Retry mechanism**: Intelligent retry with exponential backoff
- **Security headers**: Automatic injection of security headers
- **Secure logging**: Sensitive data masking in logs

#### Usage:
```dart
final networkService = SecureNetworkService(
  tokenManager: tokenManager,
);

// Secure API calls
final response = await networkService.post('/api/login', data: {
  'email': email,
  'password': password,
});

// File upload with validation
final uploadResponse = await networkService.uploadFile(
  '/api/upload',
  file,
  fieldName: 'image',
);
```

### 6. Central Security Management

#### Key Features:
- **Unified security control**: Single point of security management
- **Session monitoring**: Automatic logout based on inactivity
- **Device security checks**: Root/jailbreak detection and security scoring
- **Security levels**: Configurable security levels (Basic, Standard, High, Maximum)
- **Threat detection**: Monitoring for suspicious activity patterns

#### Usage:
```dart
final securityManager = SecurityManager(
  secureStorage: secureStorage,
  tokenManager: tokenManager,
  biometricService: biometricService,
);

// Initialize security
await securityManager.initialize();

// Authenticate user
final authResult = await securityManager.authenticateUser(
  email: email,
  password: password,
  rememberMe: true,
);

// Biometric authentication
final biometricResult = await securityManager.authenticateWithBiometric();

// Set security level
await securityManager.setSecurityLevel(SecurityLevel.high);

// Check device security
final deviceStatus = await securityManager.checkDeviceSecurityStatus();
```

## Security Levels

### Basic (Level 0)
- 24-hour session timeout
- Basic input validation
- Standard secure storage

### Standard (Level 1)
- 8-hour session timeout
- PIN requirement
- Enhanced validation
- Basic biometric support

### High (Level 2)
- 2-hour session timeout
- Biometric authentication required
- Advanced threat detection
- Enhanced encryption

### Maximum (Level 3)
- 15-minute session timeout
- Multi-factor authentication
- Real-time security monitoring
- Maximum encryption and validation

## Security Best Practices Implemented

### 1. Data Protection
- All sensitive data encrypted at rest
- Integrity verification for stored data
- Secure deletion of sensitive information
- Key rotation and secure key storage

### 2. Authentication Security
- Multi-factor authentication support
- Biometric authentication integration
- Account lockout after failed attempts
- Session management with automatic timeout

### 3. Network Security
- SSL certificate pinning
- Request/response validation
- Protection against common attacks (XSS, SQL injection)
- Secure API communication with encrypted headers

### 4. Mobile-Specific Security
- Root/jailbreak detection
- Device fingerprinting
- Screen recording protection
- Background app security

### 5. Compliance & Standards
- OWASP Mobile Security Guidelines
- Turkish data protection regulations
- Industry-standard encryption algorithms
- Secure coding practices

## Integration Guide

### 1. Initial Setup

Add security initialization to your main app:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup service locator
  await setupServiceLocator();

  // Initialize security services
  await initializeSecurity();

  runApp(MyApp());
}
```

### 2. App Lifecycle Management

Handle security events in app lifecycle:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityManager = sl<SecurityManager>();

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background
        securityManager.recordUserActivity();
        break;
      case AppLifecycleState.resumed:
        // App came to foreground
        securityManager.recordUserActivity();
        break;
      case AppLifecycleState.detached:
        // App is being destroyed
        disposeSecurity();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeSecurity();
    super.dispose();
  }
}
```

### 3. Authentication Flow

Implement secure authentication in your login screen:

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final securityManager = sl<SecurityManager>();

  Future<void> _login(String email, String password) async {
    final result = await securityManager.authenticateUser(
      email: email,
      password: password,
      rememberMe: _rememberMe,
    );

    if (result.isSuccess) {
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _biometricLogin() async {
    final result = await securityManager.authenticateWithBiometric();

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}
```

## Security Monitoring

The security system provides comprehensive monitoring and logging:

### Security Events
- User authentication attempts
- Token refresh operations
- Biometric authentication usage
- Device security status changes
- Suspicious activity detection

### Device Security Scoring
- Device compromise detection (root/jailbreak)
- Screen lock status
- Biometric availability
- Network security assessment

### Session Management
- Automatic session timeout based on security level
- User activity tracking
- Background/foreground state monitoring
- Secure session invalidation

## Troubleshooting

### Common Issues

1. **Biometric Authentication Fails**
   - Check device biometric enrollment
   - Verify app permissions
   - Ensure biometric hardware availability

2. **Token Refresh Errors**
   - Check network connectivity
   - Verify API endpoint availability
   - Check token expiry and validity

3. **Secure Storage Errors**
   - Check device keychain availability
   - Verify app permissions
   - Check storage quota limits

4. **Certificate Pinning Issues**
   - Verify certificate fingerprints
   - Check network proxy settings
   - Update certificates if expired

## Performance Considerations

### Optimization Tips
- Use lazy loading for security services
- Cache biometric capability checks
- Implement efficient token validation
- Minimize cryptographic operations
- Use background processing for security checks

### Memory Management
- Properly dispose security resources
- Clear sensitive data from memory
- Use secure string handling
- Implement proper object lifecycle management

## Security Updates

### Regular Maintenance
- Update certificate fingerprints annually
- Review and update security policies
- Monitor for new security vulnerabilities
- Update dependencies regularly

### Security Patches
- Apply security patches promptly
- Test security changes thoroughly
- Document security modifications
- Maintain security audit logs

## Support

For security-related issues or questions:
- Review security logs for error details
- Check device compatibility requirements
- Verify implementation against security guidelines
- Contact security team for critical issues

## License

This security implementation is part of the ZiraAI mobile application and follows enterprise security standards and Turkish compliance requirements.