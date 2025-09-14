import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server Error']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache Error']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network Error']) : super(message);
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Authentication Failed']) : super(message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Unauthorized']) : super(message);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation Error']) : super(message);
}

// API specific failures
class TierRestrictionFailure extends Failure {
  const TierRestrictionFailure([String message = 'Tier Restriction']) : super(message);
}

class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure([String message = 'Quota Exceeded']) : super(message);
}

class SponsorshipCodeFailure extends Failure {
  const SponsorshipCodeFailure([String message = 'Invalid Sponsorship Code']) : super(message);
}

// Plant analysis failures
class PlantAnalysisFailure extends Failure {
  const PlantAnalysisFailure([String message = 'Plant Analysis Failed']) : super(message);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure([String message = 'Image Processing Failed']) : super(message);
}

// Additional failures needed for authentication domain
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'An unexpected error occurred']) : super(message);
}