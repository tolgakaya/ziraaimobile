/// Base exception class for Plant Analysis features
abstract class PlantAnalysisException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic originalError;

  const PlantAnalysisException(this.message, {this.errorCode, this.originalError});

  /// Whether this exception represents a recoverable error
  bool get isRecoverable => true;

  @override
  String toString() => "PlantAnalysisException: $message";
}

/// Image processing related exceptions
class ImageProcessingException extends PlantAnalysisException {
  final String? processingStage;
  final String? validationType;

  const ImageProcessingException(
    String message, {
    String? errorCode,
    this.processingStage,
    this.validationType,
    dynamic originalError,
  }) : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "ImageProcessingException: $message";
}

/// Image validation specific exceptions
class ImageValidationException extends ImageProcessingException {
  const ImageValidationException(
    String message, {
    String? errorCode,
    String? validationType,
    dynamic originalError,
  }) : super(
          message,
          errorCode: errorCode,
          processingStage: "validation",
          validationType: validationType,
          originalError: originalError,
        );
}

/// Network related exceptions
class NetworkException extends PlantAnalysisException {
  const NetworkException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "NetworkException: $message";
}

/// Authentication related exceptions
class AuthenticationException extends PlantAnalysisException {
  const AuthenticationException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  bool get isRecoverable => false;

  @override
  String toString() => "AuthenticationException: $message";
}

/// Analysis submission exceptions
class AnalysisSubmissionException extends PlantAnalysisException {
  const AnalysisSubmissionException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "AnalysisSubmissionException: $message";
}

/// Analysis processing exceptions
class AnalysisProcessingException extends PlantAnalysisException {
  const AnalysisProcessingException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "AnalysisProcessingException: $message";
}

/// Analysis timeout exceptions
class AnalysisTimeoutException extends PlantAnalysisException {
  const AnalysisTimeoutException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  bool get isRecoverable => true;

  @override
  String toString() => "AnalysisTimeoutException: $message";
}

/// Analysis parsing exceptions
class AnalysisParsingException extends PlantAnalysisException {
  const AnalysisParsingException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "AnalysisParsingException: $message";
}

/// Quota exceeded exceptions (403 Forbidden)
class QuotaExceededException extends PlantAnalysisException {
  final String quotaType; // 'daily' or 'monthly'
  final int? usedCount;
  final int? limitCount;
  final String? resetTime;
  final String? subscriptionTier;

  const QuotaExceededException(
    String message, {
    String? errorCode,
    required this.quotaType,
    this.usedCount,
    this.limitCount,
    this.resetTime,
    this.subscriptionTier,
    dynamic originalError,
  }) : super(message, errorCode: errorCode, originalError: originalError);

  @override
  bool get isRecoverable => true;

  @override
  String toString() => "QuotaExceededException: $message";
}

/// Unknown/Generic exceptions
class UnknownException extends PlantAnalysisException {
  const UnknownException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "UnknownException: $message";
}