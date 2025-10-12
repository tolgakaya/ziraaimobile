class CodeRecipient {
  final String name;
  final String phone;
  String? assignedCode; // Will be auto-assigned by backend

  CodeRecipient({
    required this.name,
    required this.phone,
    this.assignedCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (assignedCode != null) 'code': assignedCode,
    };
  }

  /// Normalize Turkish phone number format
  /// Converts: 5551234567 -> +905551234567
  static String normalizePhone(String phone) {
    // Remove all non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add Turkey country code if not present
    String normalized = cleaned;
    if (cleaned.length == 10 && !cleaned.startsWith('90')) {
      normalized = '90$cleaned';
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      normalized = '9${cleaned.substring(1)}';
    }

    // Add + prefix
    if (!normalized.startsWith('+')) {
      normalized = '+$normalized';
    }

    return normalized;
  }

  /// Format phone for display: +905551234567 -> +90 555 123 45 67
  static String formatPhoneDisplay(String phone) {
    final normalized = normalizePhone(phone);

    // Turkish format: +90 5XX XXX XX XX
    if (normalized.startsWith('+90') && normalized.length == 13) {
      return '${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6, 9)} ${normalized.substring(9, 11)} ${normalized.substring(11)}';
    }

    return normalized;
  }

  CodeRecipient copyWith({
    String? name,
    String? phone,
    String? assignedCode,
  }) {
    return CodeRecipient(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      assignedCode: assignedCode ?? this.assignedCode,
    );
  }
}
