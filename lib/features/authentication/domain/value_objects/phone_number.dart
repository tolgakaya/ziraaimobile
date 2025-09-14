import 'package:equatable/equatable.dart';

/// Value object for phone number validation and formatting.
/// Handles Turkish phone number format (+90) as primary with international support.
class PhoneNumber extends Equatable {
  final String value;
  final String countryCode;

  const PhoneNumber._(
    this.value,
    this.countryCode,
  );

  /// Creates a PhoneNumber instance with validation.
  /// Defaults to Turkish format (+90) but supports international numbers.
  factory PhoneNumber(String phoneNumber, {String? countryCode}) {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);
    final detectedCountryCode = countryCode ?? _detectCountryCode(cleanNumber);
    
    if (!_isValidPhoneNumber(cleanNumber, detectedCountryCode)) {
      throw ArgumentError('Invalid phone number format: $phoneNumber');
    }

    final normalizedNumber = _normalizePhoneNumber(cleanNumber, detectedCountryCode);
    
    return PhoneNumber._(
      normalizedNumber,
      detectedCountryCode,
    );
  }

  /// Creates a PhoneNumber instance without validation (use with caution)
  factory PhoneNumber.unsafe(String phoneNumber, String countryCode) {
    return PhoneNumber._(phoneNumber, countryCode);
  }

  /// Removes all non-digit characters except + at the beginning
  static String _cleanPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.startsWith('+') ? cleaned : '+$cleaned';
  }

  /// Detects country code from phone number (defaults to +90 for Turkey)
  static String _detectCountryCode(String cleanNumber) {
    if (cleanNumber.startsWith('+90')) return '+90';
    if (cleanNumber.startsWith('+1')) return '+1';
    if (cleanNumber.startsWith('+44')) return '+44';
    if (cleanNumber.startsWith('+49')) return '+49';
    if (cleanNumber.startsWith('+33')) return '+33';
    
    // Default to Turkish format if no country code detected
    return '+90';
  }

  /// Validates phone number format based on country code
  static bool _isValidPhoneNumber(String phoneNumber, String countryCode) {
    switch (countryCode) {
      case '+90': // Turkey
        return _isValidTurkishNumber(phoneNumber);
      case '+1': // US/Canada
        return _isValidNorthAmericanNumber(phoneNumber);
      default:
        return _isValidInternationalNumber(phoneNumber);
    }
  }

  /// Validates Turkish phone number format
  static bool _isValidTurkishNumber(String phoneNumber) {
    // Turkish mobile numbers: +90 5XX XXX XXXX
    // Turkish landline: +90 2XX XXX XXXX or +90 3XX XXX XXXX
    final turkishRegex = RegExp(r'^\+90[235]\d{9}$');
    return turkishRegex.hasMatch(phoneNumber) && phoneNumber.length == 13;
  }

  /// Validates North American phone number format
  static bool _isValidNorthAmericanNumber(String phoneNumber) {
    // North American format: +1 XXX XXX XXXX
    final naRegex = RegExp(r'^\+1[2-9]\d{2}[2-9]\d{6}$');
    return naRegex.hasMatch(phoneNumber) && phoneNumber.length == 12;
  }

  /// Basic international phone number validation
  static bool _isValidInternationalNumber(String phoneNumber) {
    // International format: + followed by 7-15 digits
    final intlRegex = RegExp(r'^\+[1-9]\d{6,14}$');
    return intlRegex.hasMatch(phoneNumber);
  }

  /// Normalizes phone number to international format
  static String _normalizePhoneNumber(String phoneNumber, String countryCode) {
    if (phoneNumber.startsWith(countryCode)) {
      return phoneNumber;
    }
    
    // Handle Turkish numbers without country code
    if (countryCode == '+90') {
      if (phoneNumber.startsWith('0')) {
        return '+90${phoneNumber.substring(1)}';
      }
      if (phoneNumber.length == 10 && phoneNumber.startsWith(RegExp(r'[235]'))) {
        return '+90$phoneNumber';
      }
    }
    
    return phoneNumber;
  }

  /// Validates if a string is a valid phone number
  static bool isValid(String phoneNumber, {String? countryCode}) {
    try {
      PhoneNumber(phoneNumber, countryCode: countryCode);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the phone number formatted for display
  String get formatted {
    switch (countryCode) {
      case '+90':
        // Turkish format: +90 5XX XXX XX XX
        if (value.length == 13) {
          return '${value.substring(0, 3)} ${value.substring(3, 6)} ${value.substring(6, 9)} ${value.substring(9, 11)} ${value.substring(11)}';
        }
        break;
      case '+1':
        // North American format: +1 (XXX) XXX-XXXX
        if (value.length == 12) {
          return '${value.substring(0, 2)} (${value.substring(2, 5)}) ${value.substring(5, 8)}-${value.substring(8)}';
        }
        break;
    }
    
    // Default formatting
    return value;
  }

  /// Returns the phone number without country code
  String get nationalNumber {
    return value.replaceFirst(countryCode, '');
  }

  /// Returns whether this is a mobile number
  bool get isMobile {
    switch (countryCode) {
      case '+90':
        return value.startsWith('+905');
      case '+1':
        return true; // North American mobile/landline distinction is complex
      default:
        return false; // Cannot determine for other countries without more data
    }
  }

  /// Returns whether this is a Turkish number
  bool get isTurkish => countryCode == '+90';

  /// Returns a masked version for display (e.g., +90 5XX XXX XX 23)
  String get masked {
    if (value.length < 8) return value;
    
    final prefix = value.substring(0, value.length - 6);
    final suffix = value.substring(value.length - 2);
    return '${prefix}XXXX$suffix';
  }

  @override
  List<Object?> get props => [value, countryCode];

  @override
  String toString() => value;
}