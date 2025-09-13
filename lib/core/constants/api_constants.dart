class ApiConstants {
  // Base URLs
  static const String baseUrlProd = 'https://api.ziraai.com/api/v1';
  static const String baseUrlStaging = 'https://api-staging.ziraai.com/api/v1';

  // Current environment
  static const String baseUrl = baseUrlStaging; // Change for production

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';

  // Plant Analysis endpoints
  static const String analyzeSync = '/plantanalyses/analyze';
  static const String analyzeAsync = '/plantanalyses/analyze-async';
  static const String getAnalysisStatus = '/plantanalyses/status';
  static const String getAnalysisList = '/plantanalyses/list';
  static const String getAnalysisById = '/plantanalyses';

  // Subscription endpoints
  static const String getTiers = '/subscriptions/tiers';
  static const String getMySubscription = '/subscriptions/my-subscription';
  static const String getUsageStatus = '/subscriptions/usage-status';
  static const String subscribe = '/subscriptions/subscribe';
  static const String redeemCode = '/subscriptions/redeem-code';

  // Sponsorship endpoints
  static const String validateCode = '/sponsorships/validate';
  static const String redeemSponsorCode = '/sponsorships/redeem';
  static const String getMySponsor = '/sponsorships/my-sponsor';
  static const String getSponsorProfile = '/sponsorships/sponsor-profile';

  // Localization endpoints
  static const String getLanguages = '/localization/languages';
  static const String getTranslations = '/localization/translations';

  // Headers
  static const String contentType = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
}