/// API Configuration for ZiraAI Mobile App
/// This file contains all API endpoints and configuration
/// Change environment by modifying the environment variable

class ApiConfig {
  // Environment configuration
  static const Environment environment = Environment.staging;
  
  // Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.production: 'https://ziraai-api-prod.up.railway.app',
    Environment.staging: 'https://ziraai-api-sit.up.railway.app', 
    Environment.development: 'https://api.ziraai.com',
    Environment.local: 'https://localhost:5001',
  };
  
  // Get current base URL
  static String get baseUrl => _baseUrls[environment]!;
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  // Authentication Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  
  // User Profile Endpoints
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String deleteAccount = '/users/account';
  
  // Plant Analysis Endpoints
  static const String plantAnalyze = '/plantanalyses/analyze';
  static const String plantAnalyzeAsync = '/plantanalyses/analyze-async';
  static const String plantAnalysesList = '/plantanalyses/list';
  static const String plantAnalysisDetail = '/plantanalyses';
  
  // Subscription Endpoints
  static const String subscriptionTiers = '/subscriptions/tiers';
  static const String mySubscription = '/subscriptions/my-subscription';
  static const String usageStatus = '/subscriptions/usage-status';
  static const String subscribe = '/subscriptions/subscribe';
  static const String cancelSubscription = '/subscriptions/cancel';
  static const String subscriptionHistory = '/subscriptions/history';

  // Sponsorship Endpoints
  static const String sponsorshipCreateLink = '/sponsorships/create-link';
  static const String sponsorshipValidate = '/sponsorships/validate';
  static const String sponsorshipList = '/sponsorships/list';
  static const String sponsorshipRedeem = '/sponsorship/redeem';
  static const String sponsoredAnalyses = '/sponsorship/analyses';
  static const String sponsoredAnalysisDetail = '/sponsorship/analysis'; // /{analysisId}

  // Sponsor Profile Endpoints
  static const String createSponsorProfile = '/sponsorship/create-profile';
  static const String getSponsorProfile = '/sponsorship/profile';
  static const String sponsorDashboardSummary = '/sponsorship/dashboard-summary';

  // Code Distribution Endpoints
  static const String sponsorshipCodes = '/sponsorship/codes';
  static const String sendSponsorshipLink = '/sponsorship/send-link';

  // Package Purchase Endpoints
  static const String purchasePackage = '/sponsorship/purchase-package';

  // Messaging Endpoints
  static const String messagingSend = '/sponsorship/messages';
  static const String messagingGetConversation = '/sponsorship/messages/conversation';
  static const String messagingBlock = '/sponsorship/messages/block';
  static String messagingUnblock(int sponsorId) =>
      '/sponsorship/messages/block/$sponsorId';
  static const String messagingGetBlocked = '/sponsorship/messages/blocked';
  static const String messagingGetQuota = '/sponsorship/messages/remaining';

  // SignalR Hub Endpoint
  static String get signalRHubUrl => '$baseUrl/hubs/plantanalysis';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeader(String token) => {
    'Authorization': 'Bearer $token',
    ...defaultHeaders,
  };
}

/// Environment types
enum Environment {
  production,
  staging,
  development,
  local,
}