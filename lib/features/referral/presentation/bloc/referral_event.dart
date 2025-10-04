import 'package:equatable/equatable.dart';

abstract class ReferralEvent extends Equatable {
  const ReferralEvent();

  @override
  List<Object?> get props => [];
}

/// Generate referral link and send via specified delivery method
class GenerateReferralLinkRequested extends ReferralEvent {
  final List<String> phoneNumbers;
  final int deliveryMethod; // 1=SMS, 2=WhatsApp, 3=Both
  final String? customMessage;

  const GenerateReferralLinkRequested({
    required this.phoneNumbers,
    required this.deliveryMethod,
    this.customMessage,
  });

  @override
  List<Object?> get props => [phoneNumbers, deliveryMethod, customMessage];
}

/// Fetch referral statistics for current user
class FetchReferralStatsRequested extends ReferralEvent {
  const FetchReferralStatsRequested();
}

/// Fetch credit breakdown for current user
class FetchCreditBreakdownRequested extends ReferralEvent {
  const FetchCreditBreakdownRequested();
}

/// Fetch referral rewards history
class FetchReferralRewardsRequested extends ReferralEvent {
  const FetchReferralRewardsRequested();
}

/// Fetch all referral data at once (stats + credits + rewards)
class FetchAllReferralDataRequested extends ReferralEvent {
  const FetchAllReferralDataRequested();
}
