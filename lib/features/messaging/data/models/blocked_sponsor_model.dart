import 'package:json_annotation/json_annotation.dart';

part 'blocked_sponsor_model.g.dart';

@JsonSerializable()
class BlockedSponsorModel {
  final int sponsorId;
  final String? sponsorName;
  final bool isBlocked;
  final bool isMuted;
  final DateTime blockedDate;
  final String? reason;

  BlockedSponsorModel({
    required this.sponsorId,
    this.sponsorName,
    required this.isBlocked,
    required this.isMuted,
    required this.blockedDate,
    this.reason,
  });

  factory BlockedSponsorModel.fromJson(Map<String, dynamic> json) =>
      _$BlockedSponsorModelFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedSponsorModelToJson(this);
}
