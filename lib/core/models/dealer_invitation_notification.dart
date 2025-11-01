/// Dealer Invitation SignalR Notification Model
///
/// Used for real-time dealer invitation notifications via SignalR.
/// Triggered by backend event: NewDealerInvitation
///
/// This model represents the notification payload sent when a sponsor
/// creates a new dealer invitation for the authenticated user.
class DealerInvitationNotification {
  final int invitationId;
  final String token;
  final String sponsorCompanyName;
  final int codeCount;
  final String? packageTier; // S, M, L, XL - can be null
  final DateTime expiresAt;
  final int remainingDays;
  final String status; // "Pending", "Accepted", "Expired", "Cancelled"
  final String? invitationMessage; // Custom message from sponsor (optional)
  final String dealerEmail;
  final String dealerPhone;
  final DateTime createdAt;

  DealerInvitationNotification({
    required this.invitationId,
    required this.token,
    required this.sponsorCompanyName,
    required this.codeCount,
    this.packageTier,
    required this.expiresAt,
    required this.remainingDays,
    required this.status,
    this.invitationMessage,
    required this.dealerEmail,
    required this.dealerPhone,
    required this.createdAt,
  });

  /// Create notification from SignalR JSON payload
  factory DealerInvitationNotification.fromJson(Map<String, dynamic> json) {
    return DealerInvitationNotification(
      invitationId: json['invitationId'] as int,
      token: json['token'] as String,
      sponsorCompanyName: json['sponsorCompanyName'] as String,
      codeCount: json['codeCount'] as int,
      packageTier: json['packageTier'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      remainingDays: json['remainingDays'] as int,
      status: json['status'] as String,
      invitationMessage: json['invitationMessage'] as String?,
      dealerEmail: json['dealerEmail'] as String,
      dealerPhone: json['dealerPhone'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON (for debugging/logging)
  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'token': token,
      'sponsorCompanyName': sponsorCompanyName,
      'codeCount': codeCount,
      'packageTier': packageTier,
      'expiresAt': expiresAt.toIso8601String(),
      'remainingDays': remainingDays,
      'status': status,
      'invitationMessage': invitationMessage,
      'dealerEmail': dealerEmail,
      'dealerPhone': dealerPhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Check if invitation is still valid (not expired)
  bool get isValid => remainingDays > 0 && status == 'Pending';

  /// Get urgency level based on remaining days
  /// - High: < 2 days
  /// - Medium: 2-5 days
  /// - Low: > 5 days
  String get urgencyLevel {
    if (remainingDays < 2) return 'high';
    if (remainingDays <= 5) return 'medium';
    return 'low';
  }

  /// Human-readable expiration message
  String get expirationMessage {
    if (remainingDays < 0) return 'Süresi dolmuş';
    if (remainingDays == 0) return 'Bugün sona eriyor!';
    if (remainingDays == 1) return 'Yarın sona eriyor!';
    return '$remainingDays gün kaldı';
  }

  @override
  String toString() {
    return 'DealerInvitationNotification('
        'id: $invitationId, '
        'sponsor: $sponsorCompanyName, '
        'codes: $codeCount, '
        'tier: $packageTier, '
        'expires: $expirationMessage'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DealerInvitationNotification &&
        other.invitationId == invitationId;
  }

  @override
  int get hashCode => invitationId.hashCode;
}
