import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/referral_repository.dart';
import '../../data/models/referral_stats.dart';
import '../../data/models/credit_breakdown.dart';
import '../../data/models/referral_reward.dart';
import 'referral_event.dart';
import 'referral_state.dart';

@injectable
class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final ReferralRepository _referralRepository;

  ReferralBloc(this._referralRepository) : super(const ReferralInitial()) {
    on<GenerateReferralLinkRequested>(_onGenerateReferralLinkRequested);
    on<FetchReferralStatsRequested>(_onFetchReferralStatsRequested);
    on<FetchCreditBreakdownRequested>(_onFetchCreditBreakdownRequested);
    on<FetchReferralRewardsRequested>(_onFetchReferralRewardsRequested);
    on<FetchAllReferralDataRequested>(_onFetchAllReferralDataRequested);
  }

  Future<void> _onGenerateReferralLinkRequested(
    GenerateReferralLinkRequested event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await _referralRepository.generateReferralLink(
      phoneNumbers: event.phoneNumbers,
      deliveryMethod: event.deliveryMethod,
      customMessage: event.customMessage,
    );

    result.fold(
      (failure) {
        emit(ReferralError(
          message: failure.message ?? 'Failed to generate referral link',
        ));
      },
      (linkData) {
        emit(ReferralLinkGenerated(linkData: linkData));
      },
    );
  }

  Future<void> _onFetchReferralStatsRequested(
    FetchReferralStatsRequested event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await _referralRepository.getReferralStats();

    result.fold(
      (failure) {
        emit(ReferralError(
          message: failure.message ?? 'Failed to fetch referral statistics',
        ));
      },
      (stats) {
        // Preserve existing data if available
        final currentState = state;
        if (currentState is ReferralDataLoaded) {
          emit(currentState.copyWith(stats: stats));
        } else {
          emit(ReferralDataLoaded(stats: stats));
        }
      },
    );
  }

  Future<void> _onFetchCreditBreakdownRequested(
    FetchCreditBreakdownRequested event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await _referralRepository.getCreditBreakdown();

    result.fold(
      (failure) {
        emit(ReferralError(
          message: failure.message ?? 'Failed to fetch credit breakdown',
        ));
      },
      (credits) {
        // Preserve existing data if available
        final currentState = state;
        if (currentState is ReferralDataLoaded) {
          emit(currentState.copyWith(credits: credits));
        } else {
          emit(ReferralDataLoaded(credits: credits));
        }
      },
    );
  }

  Future<void> _onFetchReferralRewardsRequested(
    FetchReferralRewardsRequested event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await _referralRepository.getReferralRewards();

    result.fold(
      (failure) {
        emit(ReferralError(
          message: failure.message ?? 'Failed to fetch referral rewards',
        ));
      },
      (rewards) {
        // Preserve existing data if available
        final currentState = state;
        if (currentState is ReferralDataLoaded) {
          emit(currentState.copyWith(rewards: rewards));
        } else {
          emit(ReferralDataLoaded(rewards: rewards));
        }
      },
    );
  }

  Future<void> _onFetchAllReferralDataRequested(
    FetchAllReferralDataRequested event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    // Fetch all data in parallel for better performance
    final results = await Future.wait([
      _referralRepository.getReferralStats(),
      _referralRepository.getCreditBreakdown(),
      _referralRepository.getReferralRewards(),
    ]);

    final statsResult = results[0];
    final creditsResult = results[1];
    final rewardsResult = results[2];

    // Check if any request failed
    if (statsResult.isLeft() || creditsResult.isLeft() || rewardsResult.isLeft()) {
      // At least one request failed
      String errorMessage = 'Failed to fetch referral data';

      statsResult.fold(
        (failure) => errorMessage = failure.message ?? errorMessage,
        (_) {},
      );

      emit(ReferralError(message: errorMessage));
      return;
    }

    // All requests succeeded, extract data
    final stats = statsResult.getOrElse(() => throw Exception()) as ReferralStats;
    final credits = creditsResult.getOrElse(() => throw Exception()) as CreditBreakdown;
    final rewards = rewardsResult.getOrElse(() => throw Exception()) as List<ReferralReward>;

    emit(ReferralDataLoaded(
      stats: stats,
      credits: credits,
      rewards: rewards,
    ));
  }
}
