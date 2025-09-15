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

/// Unknown/Generic exceptions
class UnknownException extends PlantAnalysisException {
  const UnknownException(String message, {String? errorCode, dynamic originalError})
      : super(message, errorCode: errorCode, originalError: originalError);

  @override
  String toString() => "UnknownException: $message";
}