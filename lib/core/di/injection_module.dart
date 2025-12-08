import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../security/secure_network_service.dart';
import '../security/token_manager.dart';

@module
abstract class InjectionModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  /// ✅ CRITICAL FIX: Provide Dio instance with TokenInterceptor for automatic token refresh
  /// This Dio instance MUST be used by all services that need authentication
  /// SecureNetworkService has TokenInterceptor configured to:
  /// - Automatically add Bearer token to requests
  /// - Automatically refresh expired tokens
  /// - Handle 401 errors and retry with new token
  @lazySingleton
  Dio dio(TokenManager tokenManager) {
    // Create SecureNetworkService which has TokenInterceptor configured
    final secureService = SecureNetworkService(tokenManager: tokenManager);
    // Return the Dio instance from SecureNetworkService
    return secureService.dio;
  }
}