/// Sponsorship-specific features container
class SponsorshipFeatures {
  final int dataAccessPercentage; // 30, 60, 100
  final FarmerDataAccess dataAccess;
  final LogoVisibility logoVisibility;
  final CommunicationFeatures communication;
  final SmartLinksFeatures smartLinks;
  final SupportFeatures support;

  SponsorshipFeatures({
    required this.dataAccessPercentage,
    required this.dataAccess,
    required this.logoVisibility,
    required this.communication,
    required this.smartLinks,
    required this.support,
  });

  factory SponsorshipFeatures.fromJson(Map<String, dynamic> json) {
    return SponsorshipFeatures(
      dataAccessPercentage: json['dataAccessPercentage'] as int,
      dataAccess: FarmerDataAccess.fromJson(
        json['dataAccess'] as Map<String, dynamic>,
      ),
      logoVisibility: LogoVisibility.fromJson(
        json['logoVisibility'] as Map<String, dynamic>,
      ),
      communication: CommunicationFeatures.fromJson(
        json['communication'] as Map<String, dynamic>,
      ),
      smartLinks: SmartLinksFeatures.fromJson(
        json['smartLinks'] as Map<String, dynamic>,
      ),
      support: SupportFeatures.fromJson(
        json['support'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataAccessPercentage': dataAccessPercentage,
      'dataAccess': dataAccess.toJson(),
      'logoVisibility': logoVisibility.toJson(),
      'communication': communication.toJson(),
      'smartLinks': smartLinks.toJson(),
      'support': support.toJson(),
    };
  }
}

/// What farmer data the sponsor can access
class FarmerDataAccess {
  final bool farmerNameContact;
  final bool locationCity;
  final bool locationDistrict;
  final bool locationCoordinates;
  final bool cropTypes;
  final bool diseaseCategories;
  final bool fullAnalysisDetails;
  final bool analysisImages;
  final bool aiRecommendations;

  FarmerDataAccess({
    required this.farmerNameContact,
    required this.locationCity,
    required this.locationDistrict,
    required this.locationCoordinates,
    required this.cropTypes,
    required this.diseaseCategories,
    required this.fullAnalysisDetails,
    required this.analysisImages,
    required this.aiRecommendations,
  });

  factory FarmerDataAccess.fromJson(Map<String, dynamic> json) {
    return FarmerDataAccess(
      farmerNameContact: json['farmerNameContact'] as bool,
      locationCity: json['locationCity'] as bool,
      locationDistrict: json['locationDistrict'] as bool,
      locationCoordinates: json['locationCoordinates'] as bool,
      cropTypes: json['cropTypes'] as bool,
      diseaseCategories: json['diseaseCategories'] as bool,
      fullAnalysisDetails: json['fullAnalysisDetails'] as bool,
      analysisImages: json['analysisImages'] as bool,
      aiRecommendations: json['aiRecommendations'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmerNameContact': farmerNameContact,
      'locationCity': locationCity,
      'locationDistrict': locationDistrict,
      'locationCoordinates': locationCoordinates,
      'cropTypes': cropTypes,
      'diseaseCategories': diseaseCategories,
      'fullAnalysisDetails': fullAnalysisDetails,
      'analysisImages': analysisImages,
      'aiRecommendations': aiRecommendations,
    };
  }
}

/// Where sponsor logo appears in farmer's app
class LogoVisibility {
  final bool startScreen;
  final bool resultScreen;
  final bool analysisDetailsScreen;
  final bool farmerProfileScreen;
  final List<String> visibleScreens;

  LogoVisibility({
    required this.startScreen,
    required this.resultScreen,
    required this.analysisDetailsScreen,
    required this.farmerProfileScreen,
    required this.visibleScreens,
  });

  factory LogoVisibility.fromJson(Map<String, dynamic> json) {
    return LogoVisibility(
      startScreen: json['startScreen'] as bool,
      resultScreen: json['resultScreen'] as bool,
      analysisDetailsScreen: json['analysisDetailsScreen'] as bool,
      farmerProfileScreen: json['farmerProfileScreen'] as bool,
      visibleScreens: List<String>.from(json['visibleScreens'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startScreen': startScreen,
      'resultScreen': resultScreen,
      'analysisDetailsScreen': analysisDetailsScreen,
      'farmerProfileScreen': farmerProfileScreen,
      'visibleScreens': visibleScreens,
    };
  }
}

/// Communication capabilities with farmers
class CommunicationFeatures {
  final bool messagingEnabled;
  final bool viewConversations;
  final int? messageRateLimitPerDay; // null if disabled, 10 if enabled

  CommunicationFeatures({
    required this.messagingEnabled,
    required this.viewConversations,
    this.messageRateLimitPerDay,
  });

  factory CommunicationFeatures.fromJson(Map<String, dynamic> json) {
    return CommunicationFeatures(
      messagingEnabled: json['messagingEnabled'] as bool,
      viewConversations: json['viewConversations'] as bool,
      messageRateLimitPerDay: json['messageRateLimitPerDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messagingEnabled': messagingEnabled,
      'viewConversations': viewConversations,
      'messageRateLimitPerDay': messageRateLimitPerDay,
    };
  }
}

/// Smart Links capabilities (XL tier exclusive)
class SmartLinksFeatures {
  final bool enabled;
  final int quota; // 0 for non-XL, 50 for XL
  final bool analyticsAccess;

  SmartLinksFeatures({
    required this.enabled,
    required this.quota,
    required this.analyticsAccess,
  });

  factory SmartLinksFeatures.fromJson(Map<String, dynamic> json) {
    return SmartLinksFeatures(
      enabled: json['enabled'] as bool,
      quota: json['quota'] as int,
      analyticsAccess: json['analyticsAccess'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'quota': quota,
      'analyticsAccess': analyticsAccess,
    };
  }
}

/// Support tier features
class SupportFeatures {
  final bool prioritySupport;
  final int responseTimeHours; // 48, 24, 12

  SupportFeatures({
    required this.prioritySupport,
    required this.responseTimeHours,
  });

  factory SupportFeatures.fromJson(Map<String, dynamic> json) {
    return SupportFeatures(
      prioritySupport: json['prioritySupport'] as bool,
      responseTimeHours: json['responseTimeHours'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prioritySupport': prioritySupport,
      'responseTimeHours': responseTimeHours,
    };
  }
}
