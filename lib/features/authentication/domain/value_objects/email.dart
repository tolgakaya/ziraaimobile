import 'package:equatable/equatable.dart';

/// Value object for email validation and representation.
/// Ensures email format is valid and normalized.
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  /// Creates an Email instance with validation.
  /// Throws [ArgumentError] if email format is invalid.
  factory Email(String email) {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    final normalizedEmail = email.trim().toLowerCase();
    
    if (!_isValidEmail(normalizedEmail)) {
      throw ArgumentError('Invalid email format: $email');
    }

    return Email._(normalizedEmail);
  }

  /// Creates an Email instance without validation (use with caution).
  /// Typically used when email is already validated (e.g., from database).
  factory Email.unsafe(String email) {
    return Email._(email.trim().toLowerCase());
  }

  /// Validates email format using RFC 5322 compliant regex
  static bool _isValidEmail(String email) {
    // Basic email validation regex that covers most common cases
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email) && 
           email.length <= 254 && // RFC 5321 limit
           !email.contains('..') && // No consecutive dots
           !email.startsWith('.') && // No leading dot
           !email.endsWith('.'); // No trailing dot
  }

  /// Validates if a string is a valid email format
  static bool isValid(String email) {
    try {
      Email(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the domain part of the email
  String get domain {
    final atIndex = value.lastIndexOf('@');
    if (atIndex == -1) return '';
    return value.substring(atIndex + 1);
  }

  /// Returns the local part of the email (before @)
  String get localPart {
    final atIndex = value.lastIndexOf('@');
    if (atIndex == -1) return value;
    return value.substring(0, atIndex);
  }

  /// Returns a masked version of the email for display purposes
  String get masked {
    final atIndex = value.indexOf('@');
    if (atIndex <= 2) return value; // Too short to mask
    
    final localPart = value.substring(0, atIndex);
    final domain = value.substring(atIndex);
    
    if (localPart.length <= 3) {
      return '${localPart[0]}***$domain';
    }
    
    return '${localPart.substring(0, 2)}***${localPart.substring(localPart.length - 1)}$domain';
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}