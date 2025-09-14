import 'package:equatable/equatable.dart';

/// Value object for password validation and security.
/// Enforces strong password requirements and provides security utilities.
class Password extends Equatable {
  final String value;

  const Password._(this.value);

  /// Creates a Password instance with validation.
  /// Throws [ArgumentError] if password doesn't meet requirements.
  factory Password(String password) {
    final validationResult = _validatePassword(password);
    
    if (!validationResult.isValid) {
      throw ArgumentError('Password validation failed: ${validationResult.errors.join(', ')}');
    }

    return Password._(password);
  }

  /// Creates a Password instance without validation (use with caution).
  /// Typically used for existing passwords from secure sources.
  factory Password.unsafe(String password) {
    return Password._(password);
  }

  /// Validates password strength and returns validation result
  static PasswordValidationResult validateStrength(String password) {
    return _validatePassword(password);
  }

  /// Internal password validation logic
  static PasswordValidationResult _validatePassword(String password) {
    final errors = <String>[];
    
    if (password.isEmpty) {
      errors.add('Password cannot be empty');
      return PasswordValidationResult(isValid: false, errors: errors);
    }

    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    }

    if (password.length > 128) {
      errors.add('Password cannot exceed 128 characters');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }

    // Check for common weak patterns
    if (_hasSequentialCharacters(password)) {
      errors.add('Password cannot contain sequential characters (e.g., abc, 123)');
    }

    if (_hasRepeatingCharacters(password)) {
      errors.add('Password cannot contain more than 2 consecutive identical characters');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: _calculateStrength(password),
    );
  }

  /// Checks for sequential characters like abc, 123, etc.
  static bool _hasSequentialCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);
      
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
      
      if (char2 == char1 - 1 && char3 == char2 - 1) {
        return true;
      }
    }
    return false;
  }

  /// Checks for repeating characters like aaa, 111, etc.
  static bool _hasRepeatingCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Calculates password strength score (0-100)
  static int _calculateStrength(String password) {
    int score = 0;
    
    // Length score (0-25 points)
    score += (password.length * 2).clamp(0, 25);
    
    // Character variety (0-40 points)
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 10;
    
    // Complexity bonus (0-35 points)
    final uniqueChars = password.split('').toSet().length;
    score += (uniqueChars * 2).clamp(0, 20);
    
    if (password.length >= 12) score += 10;
    if (!_hasSequentialCharacters(password)) score += 5;
    
    return score.clamp(0, 100);
  }

  /// Returns the strength level as enum
  PasswordStrength get strength {
    final strengthScore = _calculateStrength(value);
    if (strengthScore >= 80) return PasswordStrength.strong;
    if (strengthScore >= 60) return PasswordStrength.medium;
    if (strengthScore >= 40) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  /// Returns true if the password is considered secure
  bool get isSecure => strength.index >= PasswordStrength.medium.index;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '****** (${value.length} chars)';
}

/// Password validation result containing validation status and errors
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final int strength;

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    this.strength = 0,
  });
}

/// Password strength levels
enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong;

  String get displayName {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  /// Returns the color associated with this strength level
  String get colorHex {
    switch (this) {
      case PasswordStrength.veryWeak:
        return '#FF0000'; // Red
      case PasswordStrength.weak:
        return '#FF8C00'; // Dark Orange
      case PasswordStrength.medium:
        return '#FFD700'; // Gold
      case PasswordStrength.strong:
        return '#008000'; // Green
    }
  }
}