import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/messaging_features.dart';
import '../repositories/messaging_repository.dart';

/// Use case for getting user's available messaging features based on tier
/// ⚠️ BREAKING CHANGE: Now requires plantAnalysisId to get features for specific analysis
class GetMessagingFeaturesUseCase {
  final MessagingRepository _repository;

  GetMessagingFeaturesUseCase(this._repository);

  Future<Either<Failure, MessagingFeatures>> call({required int plantAnalysisId}) async {
    return await _repository.getAvailableFeatures(plantAnalysisId: plantAnalysisId);
  }
}
