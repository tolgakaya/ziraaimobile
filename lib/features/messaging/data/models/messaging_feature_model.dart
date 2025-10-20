import '../../domain/entities/messaging_feature.dart';

class MessagingFeatureModel {
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

  MessagingFeatureModel({
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

  /// Parse backend format: {featureName: {enabled, available, ...}}
  factory MessagingFeatureModel.fromBackendFormat(String featureName, Map<String, dynamic> json) {
    return MessagingFeatureModel(
      id: featureName.hashCode, // Generate ID from feature name
      featureName: featureName,
      isEnabled: json['enabled'] as bool? ?? false,
      requiredTier: json['requiredTier'] as String? ?? 'S',
      isAvailable: json['available'] as bool? ?? false,
      maxFileSize: json['maxFileSize'] as int?,
      maxDuration: json['maxDuration'] as int?,
      allowedMimeTypes: (json['allowedTypes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      timeLimit: json['timeLimit'] as int?,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  MessagingFeature toEntity() {
    return MessagingFeature(
      id: id,
      featureName: featureName,
      isEnabled: isEnabled,
      requiredTier: requiredTier,
      isAvailable: isAvailable,
      maxFileSize: maxFileSize,
      maxDuration: maxDuration,
      allowedMimeTypes: allowedMimeTypes,
      timeLimit: timeLimit,
      unavailableReason: unavailableReason,
    );
  }
}

class MessagingFeaturesResponse {
  final List<MessagingFeatureModel> features;

  MessagingFeaturesResponse({
    required this.features,
  });

  /// Parse backend response format
  factory MessagingFeaturesResponse.fromJson(Map<String, dynamic> json) {
    final features = <MessagingFeatureModel>[];

    // Backend format: {voiceMessages: {...}, imageAttachments: {...}, ...}
    if (json['voiceMessages'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('VoiceMessages', json['voiceMessages']));
    }
    if (json['imageAttachments'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('ImageAttachments', json['imageAttachments']));
    }
    if (json['videoAttachments'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('VideoAttachments', json['videoAttachments']));
    }
    if (json['fileAttachments'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('FileAttachments', json['fileAttachments']));
    }
    if (json['messageEdit'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('MessageEdit', json['messageEdit']));
    }
    if (json['messageDelete'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('MessageDelete', json['messageDelete']));
    }
    if (json['messageForward'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('MessageForward', json['messageForward']));
    }
    if (json['typingIndicator'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('TypingIndicator', json['typingIndicator']));
    }
    if (json['linkPreview'] != null) {
      features.add(MessagingFeatureModel.fromBackendFormat('LinkPreview', json['linkPreview']));
    }

    return MessagingFeaturesResponse(features: features);
  }

  /// Helper to get a specific feature
  MessagingFeatureModel? getFeature(String featureName) {
    try {
      return features.firstWhere((f) => f.featureName == featureName);
    } catch (_) {
      return null;
    }
  }

  /// Helper to check if a feature is available
  bool isFeatureAvailable(String featureName) {
    final feature = getFeature(featureName);
    return feature?.isEnabled == true && feature?.isAvailable == true;
  }
}
