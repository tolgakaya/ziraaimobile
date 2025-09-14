import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Comprehensive input validation and sanitization service
class InputValidator {
  // Regular expressions for validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$', // International phone format
  );

  static final RegExp _turkishPhoneRegex = RegExp(
    r'^(\+90|0)?[5][0-9]{9}$', // Turkish mobile format
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static final RegExp _alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
  static final RegExp _numericRegex = RegExp(r'^\d+$');
  static final RegExp _alphaRegex = RegExp(r'^[a-zA-Z]+$');

  // XSS patterns to detect and sanitize
  static final List<RegExp> _xssPatterns = [
    RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'vbscript:', caseSensitive: false),
    RegExp(r'onload\s*=', caseSensitive: false),
    RegExp(r'onerror\s*=', caseSensitive: false),
    RegExp(r'onclick\s*=', caseSensitive: false),
    RegExp(r'onmouseover\s*=', caseSensitive: false),
  ];

  // SQL injection patterns
  static final List<RegExp> _sqlInjectionPatterns = [
    RegExp(r'(\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b|\bUNION\b)', caseSensitive: false),
    RegExp(r'(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+', caseSensitive: false),
    RegExp(r"'.*'", caseSensitive: false),
    RegExp(r'--', caseSensitive: false),
    RegExp(r'/\*.*\*/', caseSensitive: false),
  ];

  // Path traversal patterns
  static final List<RegExp> _pathTraversalPatterns = [
    RegExp(r'\.\./', caseSensitive: false),
    RegExp(r'\.\.\\', caseSensitive: false),
    RegExp(r'%2e%2e%2f', caseSensitive: false),
    RegExp(r'%2e%2e\/', caseSensitive: false),
    RegExp(r'%2e%2e%5c', caseSensitive: false),
  ];

  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('E-posta adresi gerekli');
    }

    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.length > 254) {
      return ValidationResult.invalid('E-posta adresi çok uzun');
    }

    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return ValidationResult.invalid('Geçersiz e-posta formatı');
    }

    // Check for suspicious patterns
    if (containsXSSPatterns(trimmedEmail)) {
      return ValidationResult.invalid('E-posta adresinde geçersiz karakterler');
    }

    return ValidationResult.valid(trimmedEmail);
  }

  /// Validate password
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.invalid('Şifre gerekli');
    }

    if (password.length < 8) {
      return ValidationResult.invalid('Şifre en az 8 karakter olmalı');
    }

    if (password.length > 128) {
      return ValidationResult.invalid('Şifre çok uzun (max 128 karakter)');
    }

    if (!_passwordRegex.hasMatch(password)) {
      return ValidationResult.invalid(
        'Şifre en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter içermeli',
      );
    }

    // Check for common weak passwords
    if (_isCommonPassword(password)) {
      return ValidationResult.invalid('Bu şifre çok yaygın, daha güçlü bir şifre seçin');
    }

    return ValidationResult.valid(password);
  }

  /// Validate phone number (Turkish mobile)
  static ValidationResult validateTurkishPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.invalid('Telefon numarası gerekli');
    }

    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_turkishPhoneRegex.hasMatch(cleanPhone)) {
      return ValidationResult.invalid('Geçersiz Türk telefon numarası formatı');
    }

    // Normalize to +90 format
    String normalized = cleanPhone;
    if (normalized.startsWith('0')) {
      normalized = '+90${normalized.substring(1)}';
    } else if (!normalized.startsWith('+90')) {
      normalized = '+90$normalized';
    }

    return ValidationResult.valid(normalized);
  }

  /// Validate international phone number
  static ValidationResult validateInternationalPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.invalid('Telefon numarası gerekli');
    }

    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return ValidationResult.invalid('Geçersiz telefon numarası formatı');
    }

    return ValidationResult.valid(cleanPhone);
  }

  /// Validate user name
  static ValidationResult validateUserName(String? userName) {
    if (userName == null || userName.trim().isEmpty) {
      return ValidationResult.invalid('Kullanıcı adı gerekli');
    }

    final trimmedName = userName.trim();

    if (trimmedName.length < 2) {
      return ValidationResult.invalid('Kullanıcı adı en az 2 karakter olmalı');
    }

    if (trimmedName.length > 50) {
      return ValidationResult.invalid('Kullanıcı adı çok uzun (max 50 karakter)');
    }

    // Allow letters, numbers, spaces, apostrophes, and hyphens
    if (!RegExp(r"^[a-zA-ZçğıöşüÇĞIİÖŞÜ\s\-']+$").hasMatch(trimmedName)) {
      return ValidationResult.invalid('Kullanıcı adı sadece harf ve geçerli karakterler içerebilir');
    }

    // Check for XSS patterns
    if (containsXSSPatterns(trimmedName)) {
      return ValidationResult.invalid('Kullanıcı adında geçersiz karakterler');
    }

    return ValidationResult.valid(trimmedName);
  }

  /// Validate agricultural code (sponsor codes, etc.)
  static ValidationResult validateAgriculturalCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return ValidationResult.invalid('Kod gerekli');
    }

    final trimmedCode = code.trim().toUpperCase();

    if (trimmedCode.length < 4) {
      return ValidationResult.invalid('Kod en az 4 karakter olmalı');
    }

    if (trimmedCode.length > 20) {
      return ValidationResult.invalid('Kod çok uzun (max 20 karakter)');
    }

    // Allow alphanumeric characters and hyphens
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(trimmedCode)) {
      return ValidationResult.invalid('Kod sadece büyük harf, rakam ve tire içerebilir');
    }

    return ValidationResult.valid(trimmedCode);
  }

  /// Sanitize input to prevent XSS attacks
  static String sanitizeInput(String? input) {
    if (input == null) return '';

    String sanitized = input.trim();

    // Remove or encode dangerous characters
    sanitized = sanitized
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');

    // Remove script tags and javascript
    for (final pattern in _xssPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }

    return sanitized;
  }

  /// Check for XSS patterns
  static bool containsXSSPatterns(String input) {
    return _xssPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Check for SQL injection patterns
  static bool containsSQLInjectionPatterns(String input) {
    return _sqlInjectionPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Check for path traversal patterns
  static bool containsPathTraversalPatterns(String input) {
    return _pathTraversalPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Validate and sanitize general text input
  static ValidationResult validateAndSanitizeText(
    String? input, {
    int minLength = 0,
    int maxLength = 1000,
    bool allowEmpty = false,
    String fieldName = 'Alan',
  }) {
    if (input == null || input.trim().isEmpty) {
      if (allowEmpty) {
        return ValidationResult.valid('');
      }
      return ValidationResult.invalid('$fieldName gerekli');
    }

    final trimmed = input.trim();

    if (trimmed.length < minLength) {
      return ValidationResult.invalid('$fieldName en az $minLength karakter olmalı');
    }

    if (trimmed.length > maxLength) {
      return ValidationResult.invalid('$fieldName çok uzun (max $maxLength karakter)');
    }

    // Check for dangerous patterns
    if (containsXSSPatterns(trimmed)) {
      return ValidationResult.invalid('$fieldName geçersiz karakterler içeriyor');
    }

    if (containsSQLInjectionPatterns(trimmed)) {
      return ValidationResult.invalid('$fieldName güvenlik nedeniyle reddedildi');
    }

    if (containsPathTraversalPatterns(trimmed)) {
      return ValidationResult.invalid('$fieldName güvenlik nedeniyle reddedildi');
    }

    final sanitized = sanitizeInput(trimmed);
    return ValidationResult.valid(sanitized);
  }

  /// Validate numeric input
  static ValidationResult validateNumeric(
    String? input, {
    int? min,
    int? max,
    bool allowEmpty = false,
    String fieldName = 'Sayı',
  }) {
    if (input == null || input.trim().isEmpty) {
      if (allowEmpty) {
        return ValidationResult.valid('');
      }
      return ValidationResult.invalid('$fieldName gerekli');
    }

    final trimmed = input.trim();

    if (!_numericRegex.hasMatch(trimmed)) {
      return ValidationResult.invalid('$fieldName sadece rakam içerebilir');
    }

    try {
      final number = int.parse(trimmed);

      if (min != null && number < min) {
        return ValidationResult.invalid('$fieldName en az $min olmalı');
      }

      if (max != null && number > max) {
        return ValidationResult.invalid('$fieldName en fazla $max olabilir');
      }

      return ValidationResult.valid(trimmed);
    } catch (e) {
      return ValidationResult.invalid('Geçersiz sayı formatı');
    }
  }

  /// Hash password securely
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random salt for password hashing
  static String generateSalt([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';

    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }

  /// Check if password is commonly used
  static bool _isCommonPassword(String password) {
    const commonPasswords = [
      '12345678', 'password', '123456789', '12345', '1234567',
      'admin123', 'qwerty123', 'password123', 'admin',
      '111111', '000000', '123123', 'qwerty',
    ];

    return commonPasswords.contains(password.toLowerCase());
  }

  /// Validate file upload
  static ValidationResult validateFileUpload({
    required String fileName,
    required int fileSize,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
    List<String> allowedExtensions = const ['.jpg', '.jpeg', '.png', '.pdf'],
  }) {
    if (fileName.isEmpty) {
      return ValidationResult.invalid('Dosya adı gerekli');
    }

    // Check file size
    if (fileSize > maxSizeBytes) {
      final maxSizeMB = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return ValidationResult.invalid('Dosya boyutu ${maxSizeMB}MB\'dan büyük olamaz');
    }

    // Check file extension
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.invalid(
        'Desteklenmeyen dosya formatı. İzin verilen formatlar: ${allowedExtensions.join(', ')}',
      );
    }

    // Check for suspicious file names
    if (containsPathTraversalPatterns(fileName)) {
      return ValidationResult.invalid('Güvenlik nedeniyle dosya reddedildi');
    }

    return ValidationResult.valid(fileName);
  }

  /// Validate URL
  static ValidationResult validateURL(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.invalid('URL gerekli');
    }

    final trimmed = url.trim();

    try {
      final uri = Uri.parse(trimmed);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.invalid('Geçersiz URL formatı');
      }

      // Only allow HTTP and HTTPS
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return ValidationResult.invalid('Sadece HTTP ve HTTPS URL\'leri desteklenir');
      }

      return ValidationResult.valid(trimmed);
    } catch (e) {
      return ValidationResult.invalid('Geçersiz URL formatı');
    }
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? value;
  final String? error;

  const ValidationResult.valid(this.value)
      : isValid = true,
        error = null;

  const ValidationResult.invalid(this.error)
      : isValid = false,
        value = null;

  /// Get the validated value or throw an exception
  String get validValue {
    if (!isValid) {
      throw ValidationException(error ?? 'Validation failed');
    }
    return value ?? '';
  }

  @override
  String toString() {
    return isValid ? 'Valid: $value' : 'Invalid: $error';
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}