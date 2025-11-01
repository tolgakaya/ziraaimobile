/// Dealer Dashboard Summary Model
///
/// Represents the summary of dealer's code statistics
/// Used in sponsor dashboard to show transferred codes information
class DealerDashboardSummary {
  final int totalCodesReceived;
  final int codesSent;
  final int codesUsed;
  final int codesAvailable;
  final double usageRate;
  final int pendingInvitationsCount;

  DealerDashboardSummary({
    required this.totalCodesReceived,
    required this.codesSent,
    required this.codesUsed,
    required this.codesAvailable,
    required this.usageRate,
    required this.pendingInvitationsCount,
  });

  factory DealerDashboardSummary.fromJson(Map<String, dynamic> json) {
    return DealerDashboardSummary(
      totalCodesReceived: json['totalCodesReceived'] as int? ?? 0,
      codesSent: json['codesSent'] as int? ?? 0,
      codesUsed: json['codesUsed'] as int? ?? 0,
      codesAvailable: json['codesAvailable'] as int? ?? 0,
      usageRate: (json['usageRate'] as num?)?.toDouble() ?? 0.0,
      pendingInvitationsCount: json['pendingInvitationsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCodesReceived': totalCodesReceived,
      'codesSent': codesSent,
      'codesUsed': codesUsed,
      'codesAvailable': codesAvailable,
      'usageRate': usageRate,
      'pendingInvitationsCount': pendingInvitationsCount,
    };
  }
}
