import 'package:equatable/equatable.dart';

/// Complete messaging features configuration
class MessagingFeatures extends Equatable {
  final VoiceMessageFeature voiceMessages;
  final ImageAttachmentFeature imageAttachments;
  final VideoAttachmentFeature videoAttachments;
  final FileAttachmentFeature fileAttachments;
  final MessageEditFeature messageEdit;
  final MessageDeleteFeature messageDelete;
  final MessageForwardFeature messageForward;
  final TypingIndicatorFeature typingIndicator;
  final LinkPreviewFeature linkPreview;

  const MessagingFeatures({
    required this.voiceMessages,
    required this.imageAttachments,
    required this.videoAttachments,
    required this.fileAttachments,
    required this.messageEdit,
    required this.messageDelete,
    required this.messageForward,
    required this.typingIndicator,
    required this.linkPreview,
  });

  @override
  List<Object?> get props => [
        voiceMessages,
        imageAttachments,
        videoAttachments,
        fileAttachments,
        messageEdit,
        messageDelete,
        messageForward,
        typingIndicator,
        linkPreview,
      ];
}

/// Base feature class
abstract class MessageFeature extends Equatable {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final String? unavailableReason;

  const MessageFeature({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    this.unavailableReason,
  });

  bool get isUsable => enabled && available;
  bool get needsUpgrade => enabled && !available && unavailableReason != null;
}

/// Voice message feature
class VoiceMessageFeature extends MessageFeature {
  final int maxFileSize; // in bytes
  final int maxDuration; // in seconds
  final List<String> allowedTypes;

  const VoiceMessageFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.maxFileSize,
    required this.maxDuration,
    required this.allowedTypes,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        maxFileSize,
        maxDuration,
        allowedTypes,
      ];
}

/// Image attachment feature
class ImageAttachmentFeature extends MessageFeature {
  final int maxFileSize;
  final List<String> allowedTypes;

  const ImageAttachmentFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.maxFileSize,
    required this.allowedTypes,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        maxFileSize,
        allowedTypes,
      ];
}

/// Video attachment feature
class VideoAttachmentFeature extends MessageFeature {
  final int maxFileSize;
  final int maxDuration;
  final List<String> allowedTypes;

  const VideoAttachmentFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.maxFileSize,
    required this.maxDuration,
    required this.allowedTypes,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        maxFileSize,
        maxDuration,
        allowedTypes,
      ];
}

/// File attachment feature (PDF, DOC, etc.)
class FileAttachmentFeature extends MessageFeature {
  final int maxFileSize;
  final List<String> allowedTypes;

  const FileAttachmentFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.maxFileSize,
    required this.allowedTypes,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        maxFileSize,
        allowedTypes,
      ];
}

/// Message edit feature
class MessageEditFeature extends MessageFeature {
  final int timeLimit; // in seconds

  const MessageEditFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.timeLimit,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        timeLimit,
      ];
}

/// Message delete feature
class MessageDeleteFeature extends MessageFeature {
  final int timeLimit; // in seconds

  const MessageDeleteFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
    required this.timeLimit,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
        timeLimit,
      ];
}

/// Message forward feature
class MessageForwardFeature extends MessageFeature {
  const MessageForwardFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
      ];
}

/// Typing indicator feature
class TypingIndicatorFeature extends MessageFeature {
  const TypingIndicatorFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
      ];
}

/// Link preview feature
class LinkPreviewFeature extends MessageFeature {
  const LinkPreviewFeature({
    required super.enabled,
    required super.available,
    required super.requiredTier,
    super.unavailableReason,
  });

  @override
  List<Object?> get props => [
        enabled,
        available,
        requiredTier,
        unavailableReason,
      ];
}
