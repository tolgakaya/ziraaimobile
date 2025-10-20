import 'package:equatable/equatable.dart';

/// Represents a messaging feature with tier-based access control
/// Backend API: GET /sponsorship/messaging/features
class MessagingFeature extends Equatable {
  final int id;
  final String featureName;
  final bool isEnabled;
  final String requiredTier;
  final bool isAvailable;
  final int? maxFileSize;
  final int? maxDuration;
  final List<String>? allowedMimeTypes;
  final int? timeLimit;
  final String? unavailableReason;

  const MessagingFeature({
    required this.id,
    required this.featureName,
    required this.isEnabled,
    required this.requiredTier,
    required this.isAvailable,
    this.maxFileSize,
    this.maxDuration,
    this.allowedMimeTypes,
    this.timeLimit,
    this.unavailableReason,
  });

  /// Check if the user can use this feature
  bool get canUse => isEnabled && isAvailable;

  /// Get max file size in MB (for UI display)
  double? get maxFileSizeMB => maxFileSize != null ? maxFileSize! / (1024 * 1024) : null;

  /// Get user-friendly error message for unavailable features
  String get unavailabilityMessage => unavailableReason ?? 'This feature is not available';

  @override
  List<Object?> get props => [
        id,
        featureName,
        isEnabled,
        requiredTier,
        isAvailable,
        maxFileSize,
        maxDuration,
        allowedMimeTypes,
        timeLimit,
        unavailableReason,
      ];
}

/// Feature names (matches backend enum)
class MessagingFeatureNames {
  static const String voiceMessages = 'VoiceMessages';
  static const String imageAttachments = 'ImageAttachments';
  static const String videoAttachments = 'VideoAttachments';
  static const String fileAttachments = 'FileAttachments';
  static const String messageEdit = 'MessageEdit';
  static const String messageDelete = 'MessageDelete';
  static const String messageForward = 'MessageForward';
  static const String typingIndicator = 'TypingIndicator';
  static const String linkPreview = 'LinkPreview';
}
