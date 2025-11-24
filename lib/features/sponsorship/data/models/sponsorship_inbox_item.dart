/// Sponsorship Inbox Item Model
/// Represents a sponsorship code sent to farmer's phone number
/// Used in farmer inbox screen to display available codes

class SponsorshipInboxItem {
  final String code;
  final String sponsorName;
  final String tierName;
  final DateTime sentDate;
  final String sentVia; // "SMS" or "WhatsApp"
  final bool isUsed;
  final DateTime? usedDate;
  final DateTime expiryDate;
  final String redemptionLink;
  final String recipientName;
  final bool isExpired;
  final int daysUntilExpiry;
  final String status; // "Aktif", "Kullanıldı", "Süresi Doldu"

  SponsorshipInboxItem({
    required this.code,
    required this.sponsorName,
    required this.tierName,
    required this.sentDate,
    required this.sentVia,
    required this.isUsed,
    this.usedDate,
    required this.expiryDate,
    required this.redemptionLink,
    required this.recipientName,
    required this.isExpired,
    required this.daysUntilExpiry,
    required this.status,
  });

  /// Create from JSON response
  factory SponsorshipInboxItem.fromJson(Map<String, dynamic> json) {
    return SponsorshipInboxItem(
      code: json['code'] as String,
      sponsorName: json['sponsorName'] as String,
      tierName: json['tierName'] as String,
      sentDate: DateTime.parse(json['sentDate'] as String),
      sentVia: json['sentVia'] as String,
      isUsed: json['isUsed'] as bool,
      usedDate: json['usedDate'] != null
          ? DateTime.parse(json['usedDate'] as String)
          : null,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      redemptionLink: json['redemptionLink'] as String,
      recipientName: json['recipientName'] as String,
      isExpired: json['isExpired'] as bool,
      daysUntilExpiry: json['daysUntilExpiry'] as int,
      status: json['status'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'sponsorName': sponsorName,
      'tierName': tierName,
      'sentDate': sentDate.toIso8601String(),
      'sentVia': sentVia,
      'isUsed': isUsed,
      'usedDate': usedDate?.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'redemptionLink': redemptionLink,
      'recipientName': recipientName,
      'isExpired': isExpired,
      'daysUntilExpiry': daysUntilExpiry,
      'status': status,
    };
  }

  /// Check if code is active (not used and not expired)
  bool get isActive => !isUsed && !isExpired;

  /// Check if code is urgent (expires in 3 days or less)
  bool get isUrgent => isActive && daysUntilExpiry <= 3;

  /// Get status color for UI
  String get statusColor {
    if (isUsed) return 'gray';
    if (isExpired) return 'red';
    if (isUrgent) return 'orange';
    return 'green';
  }

  /// Get status icon for UI
  String get statusIcon {
    if (isUsed) return 'check-circle';
    if (isExpired) return 'x-circle';
    if (isUrgent) return 'alert';
    return 'check';
  }

  @override
  String toString() {
    return 'SponsorshipInboxItem(code: $code, sponsor: $sponsorName, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SponsorshipInboxItem &&
        other.code == code &&
        other.sponsorName == sponsorName &&
        other.status == status;
  }

  @override
  int get hashCode => code.hashCode ^ sponsorName.hashCode ^ status.hashCode;
}
