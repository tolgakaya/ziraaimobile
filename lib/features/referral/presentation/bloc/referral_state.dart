import 'package:equatable/equatable.dart';
import '../../data/models/referral_link_response.dart';
import '../../data/models/referral_stats.dart';
import '../../data/models/credit_breakdown.dart';
import '../../data/models/referral_reward.dart';

abstract class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

/// Loading state for any referral operation
class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

/// Error state
class ReferralError extends ReferralState {
  final String message;

  const ReferralError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Referral link generated successfully
class ReferralLinkGenerated extends ReferralState {
  final ReferralLinkData linkData;

  const ReferralLinkGenerated({required this.linkData});

  @override
  List<Object?> get props => [linkData];
}

/// Referral data loaded (stats, credits, rewards)
class ReferralDataLoaded extends ReferralState {
  final ReferralStats? stats;
  final CreditBreakdown? credits;
  final List<ReferralReward>? rewards;

  const ReferralDataLoaded({
    this.stats,
    this.credits,
    this.rewards,
  });

  @override
  List<Object?> get props => [stats, credits, rewards];

  /// Create a copy with updated fields
  ReferralDataLoaded copyWith({
    ReferralStats? stats,
    CreditBreakdown? credits,
    List<ReferralReward>? rewards,
  }) {
    return ReferralDataLoaded(
      stats: stats ?? this.stats,
      credits: credits ?? this.credits,
      rewards: rewards ?? this.rewards,
    );
  }

  /// Check if all data is loaded
  bool get isComplete => stats != null && credits != null && rewards != null;

  /// Check if any data is loaded
  bool get hasData => stats != null || credits != null || rewards != null;
}
