import 'package:equatable/equatable.dart';
import '../../data/models/blocked_sponsor_model.dart';

class BlockedSponsor extends Equatable {
  final int sponsorId;
  final String? sponsorName;
  final bool isBlocked;
  final bool isMuted;
  final DateTime blockedDate;
  final String? reason;

  const BlockedSponsor({
    required this.sponsorId,
    this.sponsorName,
    required this.isBlocked,
    required this.isMuted,
    required this.blockedDate,
    this.reason,
  });

  factory BlockedSponsor.fromModel(BlockedSponsorModel model) {
    return BlockedSponsor(
      sponsorId: model.sponsorId,
      sponsorName: model.sponsorName,
      isBlocked: model.isBlocked,
      isMuted: model.isMuted,
      blockedDate: model.blockedDate,
      reason: model.reason,
    );
  }

  @override
  List<Object?> get props => [
        sponsorId,
        sponsorName,
        isBlocked,
        isMuted,
        blockedDate,
        reason,
      ];
}
