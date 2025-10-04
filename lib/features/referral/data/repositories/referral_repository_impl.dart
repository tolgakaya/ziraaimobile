import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/referral_repository.dart';
import '../models/referral_generate_request.dart';
import '../models/referral_link_response.dart';
import '../models/referral_stats.dart';
import '../models/credit_breakdown.dart';
import '../models/referral_reward.dart';
import '../services/referral_api_service.dart';

@LazySingleton(as: ReferralRepository)
class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralApiService _apiService;
  final SecureStorageService _secureStorage;

  ReferralRepositoryImpl(
    this._apiService,
    this._secureStorage,
  );

  /// Get authorization header with Bearer token
  Future<String> _getAuthHeader() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw const UnauthorizedFailure();
    }
    return 'Bearer $token';
  }

  @override
  Future<Either<Failure, ReferralLinkData>> generateReferralLink({
    required List<String> phoneNumbers,
    required int deliveryMethod,
    String? customMessage,
  }) async {
    try {
      final authHeader = await _getAuthHeader();

      final request = ReferralGenerateRequest(
        deliveryMethod: deliveryMethod,
        phoneNumbers: phoneNumbers,
        customMessage: customMessage,
      );

      final response = await _apiService.generateReferralLink(
        request,
        authHeader,
      );

      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to generate referral link',
        ));
      }
    } on UnauthorizedFailure catch (e) {
      return Left(e);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      if (e.response != null) {
        final errorMessage = e.response!.data is String
            ? e.response!.data as String
            : e.response!.data['message'] ?? 'Failed to generate referral link';
        return Left(ServerFailure(message: errorMessage));
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReferralStats>> getReferralStats() async {
    try {
      final authHeader = await _getAuthHeader();

      final response = await _apiService.getReferralStats(authHeader);

      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to get referral statistics',
        ));
      }
    } on UnauthorizedFailure catch (e) {
      return Left(e);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      if (e.response != null) {
        final errorMessage = e.response!.data is String
            ? e.response!.data as String
            : e.response!.data['message'] ?? 'Failed to get referral statistics';
        return Left(ServerFailure(message: errorMessage));
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CreditBreakdown>> getCreditBreakdown() async {
    try {
      final authHeader = await _getAuthHeader();

      final response = await _apiService.getCreditBreakdown(authHeader);

      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to get credit breakdown',
        ));
      }
    } on UnauthorizedFailure catch (e) {
      return Left(e);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      if (e.response != null) {
        final errorMessage = e.response!.data is String
            ? e.response!.data as String
            : e.response!.data['message'] ?? 'Failed to get credit breakdown';
        return Left(ServerFailure(message: errorMessage));
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReferralReward>>> getReferralRewards() async {
    try {
      final authHeader = await _getAuthHeader();

      final response = await _apiService.getReferralRewards(authHeader);

      if (response.success && response.data != null) {
        return Right(response.data!);
      } else {
        return Left(ServerFailure(
          message: response.message ?? 'Failed to get referral rewards',
        ));
      }
    } on UnauthorizedFailure catch (e) {
      return Left(e);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      if (e.response != null) {
        final errorMessage = e.response!.data is String
            ? e.response!.data as String
            : e.response!.data['message'] ?? 'Failed to get referral rewards';
        return Left(ServerFailure(message: errorMessage));
      }
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
