import 'package:json_annotation/json_annotation.dart';

/// Summary model for displaying invitations in a list
///
/// Lighter version of DealerInvitationDetails for list view
class DealerInvitationSummary {
  final String token;
  final String sponsorCompanyName;
  final int codeCount;
  final String? packageTier;
  final int remainingDays;
  final String status;
  final DateTime expiresAt;

  DealerInvitationSummary({
    required this.token,
    required this.sponsorCompanyName,
    required this.codeCount,
    this.packageTier,
    required this.remainingDays,
    required this.status,
    required this.expiresAt,
  });

  /// Create from backend API JSON response
  factory DealerInvitationSummary.fromJson(Map<String, dynamic> json) {
    return DealerInvitationSummary(
      token: json['token'] as String,
      sponsorCompanyName: json['sponsorCompanyName'] as String,
      codeCount: json['codeCount'] as int,
      packageTier: json['packageTier'] as String?,
      remainingDays: json['remainingDays'] as int,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Check if invitation is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if invitation is about to expire
  bool get isExpiringSoon => remainingDays <= 2;

  /// Priority score for sorting (higher = more urgent)
  int get priorityScore {
    if (!isPending) return 0;
    if (remainingDays <= 1) return 100;
    if (remainingDays <= 3) return 50;
    return 10;
  }

  /// Tier display name
  String? get tierDisplayName {
    if (packageTier == null) return null;

    switch (packageTier!) {
      case 'S':
        return 'Small';
      case 'M':
        return 'Medium';
      case 'L':
        return 'Large';
      case 'XL':
        return 'Extra Large';
      default:
        return packageTier;
    }
  }

  @override
  String toString() {
    return 'DealerInvitationSummary('
        'token: ${token.substring(0, 8)}..., '
        'sponsor: $sponsorCompanyName, '
        'codes: $codeCount, '
        'tier: $packageTier, '
        'status: $status, '
        'remainingDays: $remainingDays'
        ')';
  }
}
