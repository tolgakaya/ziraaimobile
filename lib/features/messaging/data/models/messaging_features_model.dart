import '../../domain/entities/messaging_features.dart';

/// Data model for messaging features response
class MessagingFeaturesModel {
  final VoiceMessageFeatureModel voiceMessages;
  final ImageAttachmentFeatureModel imageAttachments;
  final VideoAttachmentFeatureModel videoAttachments;
  final FileAttachmentFeatureModel fileAttachments;
  final MessageEditFeatureModel messageEdit;
  final MessageDeleteFeatureModel messageDelete;
  final MessageForwardFeatureModel messageForward;
  final TypingIndicatorFeatureModel typingIndicator;
  final LinkPreviewFeatureModel linkPreview;

  MessagingFeaturesModel({
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

  factory MessagingFeaturesModel.fromJson(Map<String, dynamic> json) {
    return MessagingFeaturesModel(
      voiceMessages: VoiceMessageFeatureModel.fromJson(json['voiceMessages'] ?? {}),
      imageAttachments: ImageAttachmentFeatureModel.fromJson(json['imageAttachments'] ?? {}),
      videoAttachments: VideoAttachmentFeatureModel.fromJson(json['videoAttachments'] ?? {}),
      fileAttachments: FileAttachmentFeatureModel.fromJson(json['fileAttachments'] ?? {}),
      messageEdit: MessageEditFeatureModel.fromJson(json['messageEdit'] ?? {}),
      messageDelete: MessageDeleteFeatureModel.fromJson(json['messageDelete'] ?? {}),
      messageForward: MessageForwardFeatureModel.fromJson(json['messageForward'] ?? {}),
      typingIndicator: TypingIndicatorFeatureModel.fromJson(json['typingIndicator'] ?? {}),
      linkPreview: LinkPreviewFeatureModel.fromJson(json['linkPreview'] ?? {}),
    );
  }

  MessagingFeatures toEntity() {
    return MessagingFeatures(
      voiceMessages: voiceMessages.toEntity(),
      imageAttachments: imageAttachments.toEntity(),
      videoAttachments: videoAttachments.toEntity(),
      fileAttachments: fileAttachments.toEntity(),
      messageEdit: messageEdit.toEntity(),
      messageDelete: messageDelete.toEntity(),
      messageForward: messageForward.toEntity(),
      typingIndicator: typingIndicator.toEntity(),
      linkPreview: linkPreview.toEntity(),
    );
  }
}

class VoiceMessageFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int maxFileSize;
  final int maxDuration;
  final List<String> allowedTypes;
  final String? unavailableReason;

  VoiceMessageFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.maxFileSize,
    required this.maxDuration,
    required this.allowedTypes,
    this.unavailableReason,
  });

  factory VoiceMessageFeatureModel.fromJson(Map<String, dynamic> json) {
    return VoiceMessageFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      maxFileSize: json['maxFileSize'] as int? ?? 0,
      maxDuration: json['maxDuration'] as int? ?? 0,
      allowedTypes: (json['allowedTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  VoiceMessageFeature toEntity() {
    return VoiceMessageFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      maxFileSize: maxFileSize,
      maxDuration: maxDuration,
      allowedTypes: allowedTypes,
      unavailableReason: unavailableReason,
    );
  }
}

class ImageAttachmentFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int maxFileSize;
  final List<String> allowedTypes;
  final String? unavailableReason;

  ImageAttachmentFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.maxFileSize,
    required this.allowedTypes,
    this.unavailableReason,
  });

  factory ImageAttachmentFeatureModel.fromJson(Map<String, dynamic> json) {
    return ImageAttachmentFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      maxFileSize: json['maxFileSize'] as int? ?? 0,
      allowedTypes: (json['allowedTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  ImageAttachmentFeature toEntity() {
    return ImageAttachmentFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      maxFileSize: maxFileSize,
      allowedTypes: allowedTypes,
      unavailableReason: unavailableReason,
    );
  }
}

class VideoAttachmentFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int maxFileSize;
  final int maxDuration;
  final List<String> allowedTypes;
  final String? unavailableReason;

  VideoAttachmentFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.maxFileSize,
    required this.maxDuration,
    required this.allowedTypes,
    this.unavailableReason,
  });

  factory VideoAttachmentFeatureModel.fromJson(Map<String, dynamic> json) {
    return VideoAttachmentFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      maxFileSize: json['maxFileSize'] as int? ?? 0,
      maxDuration: json['maxDuration'] as int? ?? 0,
      allowedTypes: (json['allowedTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  VideoAttachmentFeature toEntity() {
    return VideoAttachmentFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      maxFileSize: maxFileSize,
      maxDuration: maxDuration,
      allowedTypes: allowedTypes,
      unavailableReason: unavailableReason,
    );
  }
}

class FileAttachmentFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int maxFileSize;
  final List<String> allowedTypes;
  final String? unavailableReason;

  FileAttachmentFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.maxFileSize,
    required this.allowedTypes,
    this.unavailableReason,
  });

  factory FileAttachmentFeatureModel.fromJson(Map<String, dynamic> json) {
    return FileAttachmentFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      maxFileSize: json['maxFileSize'] as int? ?? 0,
      allowedTypes: (json['allowedTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  FileAttachmentFeature toEntity() {
    return FileAttachmentFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      maxFileSize: maxFileSize,
      allowedTypes: allowedTypes,
      unavailableReason: unavailableReason,
    );
  }
}

class MessageEditFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int timeLimit;
  final String? unavailableReason;

  MessageEditFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.timeLimit,
    this.unavailableReason,
  });

  factory MessageEditFeatureModel.fromJson(Map<String, dynamic> json) {
    return MessageEditFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      timeLimit: json['timeLimit'] as int? ?? 0,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  MessageEditFeature toEntity() {
    return MessageEditFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      timeLimit: timeLimit,
      unavailableReason: unavailableReason,
    );
  }
}

class MessageDeleteFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final int timeLimit;
  final String? unavailableReason;

  MessageDeleteFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    required this.timeLimit,
    this.unavailableReason,
  });

  factory MessageDeleteFeatureModel.fromJson(Map<String, dynamic> json) {
    return MessageDeleteFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      timeLimit: json['timeLimit'] as int? ?? 0,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  MessageDeleteFeature toEntity() {
    return MessageDeleteFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      timeLimit: timeLimit,
      unavailableReason: unavailableReason,
    );
  }
}

class MessageForwardFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final String? unavailableReason;

  MessageForwardFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    this.unavailableReason,
  });

  factory MessageForwardFeatureModel.fromJson(Map<String, dynamic> json) {
    return MessageForwardFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  MessageForwardFeature toEntity() {
    return MessageForwardFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      unavailableReason: unavailableReason,
    );
  }
}

class TypingIndicatorFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final String? unavailableReason;

  TypingIndicatorFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    this.unavailableReason,
  });

  factory TypingIndicatorFeatureModel.fromJson(Map<String, dynamic> json) {
    return TypingIndicatorFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  TypingIndicatorFeature toEntity() {
    return TypingIndicatorFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      unavailableReason: unavailableReason,
    );
  }
}

class LinkPreviewFeatureModel {
  final bool enabled;
  final bool available;
  final String requiredTier;
  final String? unavailableReason;

  LinkPreviewFeatureModel({
    required this.enabled,
    required this.available,
    required this.requiredTier,
    this.unavailableReason,
  });

  factory LinkPreviewFeatureModel.fromJson(Map<String, dynamic> json) {
    return LinkPreviewFeatureModel(
      enabled: json['enabled'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'None',
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  LinkPreviewFeature toEntity() {
    return LinkPreviewFeature(
      enabled: enabled,
      available: available,
      requiredTier: requiredTier,
      unavailableReason: unavailableReason,
    );
  }
}
