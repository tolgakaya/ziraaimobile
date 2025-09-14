import 'package:flutter/material.dart';

class AuthValidators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value, {bool isStrict = false}) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    if (isStrict) {
      // Strict password requirements
      if (value.length < 8) {
        return 'Şifre en az 8 karakter olmalı';
      }

      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
        return 'Şifre en az bir harf ve bir rakam içermeli';
      }

      if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
        return 'Şifre en az bir büyük harf içermeli';
      }

      if (!RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
        return 'Şifre en az bir özel karakter içermeli';
      }
    } else {
      // Basic password requirements
      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
        return 'Şifre en az bir harf ve bir rakam içermeli';
      }
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }

    if (password != confirmPassword) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  // Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ad soyad gerekli';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Ad soyad en az 2 karakter olmalı';
    }

    if (trimmedValue.length > 100) {
      return 'Ad soyad en fazla 100 karakter olabilir';
    }

    // Check if it contains at least first name and last name
    final nameParts = trimmedValue.split(' ').where((part) => part.isNotEmpty);
    if (nameParts.length < 2) {
      return 'Ad ve soyad girin';
    }

    // Check for valid characters (letters, spaces, some special chars)
    if (!RegExp(r'^[a-zA-ZçÇğĞıİöÖşŞüÜ\s-]+$').hasMatch(trimmedValue)) {
      return 'Geçersiz karakter kullanıldı';
    }

    return null;
  }

  // Turkish phone number validation
  static String? validateTurkishPhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is usually optional
    }

    // Remove all non-digit characters
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check Turkish mobile phone format
    if (cleanPhone.length != 11) {
      return 'Telefon numarası 11 haneli olmalıdır';
    }

    if (!cleanPhone.startsWith('0')) {
      return 'Telefon numarası 0 ile başlamalıdır';
    }

    // Check if it's a valid Turkish mobile number (starts with 05)
    if (!cleanPhone.startsWith('05')) {
      return 'Geçerli bir cep telefonu numarası girin (05xxxxxxxxx)';
    }

    return null;
  }

  // International phone validation (optional)
  static String? validateInternationalPhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is usually optional
    }

    // Basic international phone validation
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Geçerli bir telefon numarası girin';
    }

    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleanPhone)) {
      return 'Geçerli bir telefon numarası formatı kullanın';
    }

    return null;
  }

  // Generic text validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gerekli';
    }
    return null;
  }

  // Length validation
  static String? validateLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null) return null;

    if (minLength != null && value.length < minLength) {
      return '$fieldName en az $minLength karakter olmalı';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olabilir';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is usually optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir web sitesi adresi girin';
    }

    return null;
  }
}

// Password strength checker
class PasswordStrength {
  final int score;
  final String message;
  final Color color;

  const PasswordStrength({
    required this.score,
    required this.message,
    required this.color,
  });

  static PasswordStrength check(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    switch (score) {
      case 0:
      case 1:
        return const PasswordStrength(
          score: 1,
          message: 'Çok zayıf',
          color: Colors.red,
        );
      case 2:
      case 3:
        return const PasswordStrength(
          score: 2,
          message: 'Zayıf',
          color: Colors.orange,
        );
      case 4:
        return const PasswordStrength(
          score: 3,
          message: 'Orta',
          color: Colors.yellow,
        );
      case 5:
        return const PasswordStrength(
          score: 4,
          message: 'Güçlü',
          color: Colors.lightGreen,
        );
      case 6:
        return const PasswordStrength(
          score: 5,
          message: 'Çok güçlü',
          color: Colors.green,
        );
      default:
        return const PasswordStrength(
          score: 1,
          message: 'Çok zayıf',
          color: Colors.red,
        );
    }
  }
}