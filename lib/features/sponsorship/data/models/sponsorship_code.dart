class SponsorshipCode {
  final int id;
  final String code;
  final int sponsorId;
  final int subscriptionTierId;
  final int sponsorshipPurchaseId;
  final bool isUsed;
  final DateTime createdDate;
  final DateTime expiryDate;
  final bool isActive;
  final int linkClickCount;
  final bool linkDelivered;

  SponsorshipCode({
    required this.id,
    required this.code,
    required this.sponsorId,
    required this.subscriptionTierId,
    required this.sponsorshipPurchaseId,
    required this.isUsed,
    required this.createdDate,
    required this.expiryDate,
    required this.isActive,
    required this.linkClickCount,
    required this.linkDelivered,
  });

  factory SponsorshipCode.fromJson(Map<String, dynamic> json) {
    return SponsorshipCode(
      id: json['id'] as int,
      code: json['code'] as String,
      sponsorId: json['sponsorId'] as int,
      subscriptionTierId: json['subscriptionTierId'] as int,
      sponsorshipPurchaseId: json['sponsorshipPurchaseId'] as int,
      isUsed: json['isUsed'] as bool,
      createdDate: DateTime.parse(json['createdDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      isActive: json['isActive'] as bool,
      linkClickCount: json['linkClickCount'] as int,
      linkDelivered: json['linkDelivered'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'sponsorId': sponsorId,
      'subscriptionTierId': subscriptionTierId,
      'sponsorshipPurchaseId': sponsorshipPurchaseId,
      'isUsed': isUsed,
      'createdDate': createdDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'linkClickCount': linkClickCount,
      'linkDelivered': linkDelivered,
    };
  }
}
