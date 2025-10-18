import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/blocked_sponsor.dart';
import '../../domain/entities/message_quota.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/failures/messaging_failures.dart';
import '../services/messaging_api_service.dart';

@LazySingleton(as: MessagingRepository)
class MessagingRepositoryImpl implements MessagingRepository {
  final MessagingApiService _apiService;

  MessagingRepositoryImpl(this._apiService);

  @override
  Future<Either<Failure, Message>> sendMessage({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    String? messageType,
    String? subject,
  }) async {
    try {
      final model = await _apiService.sendMessage(
        plantAnalysisId: plantAnalysisId,
        toUserId: toUserId,
        message: message,
        messageType: messageType,
        subject: subject,
      );
      return Right(Message.fromModel(model));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required int plantAnalysisId,
    required int farmerId,
  }) async {
    try {
      final models = await _apiService.getMessages(
        plantAnalysisId: plantAnalysisId,
        farmerId: farmerId,
      );
      final messages = models.map((model) => Message.fromModel(model)).toList();
      return Right(messages);
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> blockSponsor({
    required int sponsorId,
    String? reason,
  }) async {
    try {
      await _apiService.blockSponsor(
        sponsorId: sponsorId,
        reason: reason,
      );
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> unblockSponsor(int sponsorId) async {
    try {
      await _apiService.unblockSponsor(sponsorId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BlockedSponsor>>> getBlockedSponsors() async {
    try {
      final models = await _apiService.getBlockedSponsors();
      final blockedSponsors = models.map((model) => BlockedSponsor.fromModel(model)).toList();
      return Right(blockedSponsors);
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MessageQuota>> getRemainingQuota(int farmerId) async {
    try {
      final model = await _apiService.getRemainingQuota(farmerId);
      return Right(MessageQuota.fromModel(model));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  /// Helper method to translate DioException to Failure with Turkish messages
  Failure _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(message: 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        final message = responseData is Map ? responseData['message'] as String? : null;

        switch (statusCode) {
          case 400:
            return ValidationFailure(message: message ?? 'Geçersiz istek. Lütfen bilgileri kontrol edin.');
          case 401:
            return AuthenticationFailure(message: 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.');
          case 403:
            return AuthorizationFailure(message: message ?? 'Bu işlem için yetkiniz yok.');
          case 404:
            return NotFoundFailure(message: message ?? 'İstenen kaynak bulunamadı.');
          case 429:
            return RateLimitFailure(message: message ?? 'Çok fazla istek gönderdiniz. Lütfen daha sonra tekrar deneyin.');
          case 500:
          case 502:
          case 503:
            return ServerFailure(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
          default:
            return ServerFailure(message: message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.');
        }

      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'İnternet bağlantınızı kontrol edin.');

      case DioExceptionType.cancel:
        return CancelFailure(message: 'İstek iptal edildi.');

      default:
        return ServerFailure(message: e.message ?? 'Beklenmeyen bir hata oluştu.');
    }
  }
}
