import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../network/network_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import '../security/token_manager.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/plant_analysis/domain/repositories/plant_analysis_repository.dart';
import '../../features/plant_analysis/data/repositories/plant_analysis_repository_impl.dart';
import '../../features/plant_analysis/data/services/plant_analysis_api_service.dart';
import '../services/auth_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';
import '../../features/authentication/data/services/phone_auth_api_service.dart';
import '../../features/referral/data/services/referral_api_service.dart';
import '../../features/referral/domain/repositories/referral_repository.dart';
import '../../features/referral/data/repositories/referral_repository_impl.dart';
import '../../features/referral/presentation/bloc/referral_bloc.dart';
import '../../features/sponsorship/data/services/sponsor_service.dart';
// import '../services/install_referrer_service.dart';  // TEMPORARILY DISABLED
import '../services/sms_referral_service.dart';
import '../../features/messaging/data/services/messaging_api_service.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/send_message_usecase.dart';
import '../../features/messaging/domain/usecases/get_messages_usecase.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupMinimalServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Core services
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<SharedPreferences>()),
  );
  
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // Deferred Deep Linking Services
  // Install Referrer TEMPORARILY DISABLED - using SMS solution instead
  // getIt.registerLazySingleton<InstallReferrerService>(
  //   () => InstallReferrerService(),
  // );

  getIt.registerLazySingleton<SmsReferralService>(
    () => SmsReferralService(),
  );

  // Token management
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
  );

  // Network
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));
    
    // Add TokenInterceptor for automatic authentication
    dio.interceptors.add(_TokenInterceptor(getIt<TokenManager>()));
    
    // Add LogInterceptor for debugging
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
    
    return dio;
  });
  
  getIt.registerLazySingleton<NetworkClient>(
    () => NetworkClient(getIt<Dio>()),
  );

  // API Services
  getIt.registerLazySingleton<PhoneAuthApiService>(
    () => PhoneAuthApiService(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ReferralApiService>(
    () => ReferralApiService(getIt<Dio>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
      getIt<PhoneAuthApiService>(),
    ),
  );

  getIt.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(
      getIt<ReferralApiService>(),
      getIt<SecureStorageService>(),
    ),
  );

  // Auth service
  getIt.registerLazySingleton<AuthService>(() => AuthServiceImpl(getIt()));

  // Plant Analysis API service
  getIt.registerLazySingleton<PlantAnalysisApiService>(() => PlantAnalysisApiService(getIt<Dio>()));

  // Plant Analysis repository - Interface to implementation
  getIt.registerLazySingleton<PlantAnalysisRepository>(
    () => PlantAnalysisRepositoryImpl(
      getIt<PlantAnalysisApiService>(),
      getIt<AuthService>(),
    ),
  );

  // Subscription service - Real API implementation
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(
      getIt<NetworkClient>(),
      getIt<SecureStorageService>(),
    ),
  );

  // Sponsor service
  getIt.registerLazySingleton<SponsorService>(
    () => SponsorService(
      dio: getIt<Dio>(),
      authService: getIt<AuthService>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  getIt.registerFactory<ReferralBloc>(
    () => ReferralBloc(getIt<ReferralRepository>()),
  );

  // Notification bloc - Singleton
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(),
  );

  // ✅ MESSAGING SERVICES - Required for sponsor-farmer messaging
  getIt.registerLazySingleton<MessagingApiService>(
    () => MessagingApiService(getIt<NetworkClient>()),
  );

  getIt.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(getIt<MessagingApiService>()),
  );

  getIt.registerLazySingleton<SendMessageUseCase>(
    () => SendMessageUseCase(getIt<MessagingRepository>()),
  );

  getIt.registerLazySingleton<GetMessagesUseCase>(
    () => GetMessagesUseCase(getIt<MessagingRepository>()),
  );

  print('✅ MESSAGING: All messaging services registered successfully!');
}

/// Token interceptor for automatic authentication
class _TokenInterceptor extends Interceptor {
  final TokenManager _tokenManager;

  _TokenInterceptor(this._tokenManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register/refresh endpoints
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Get valid access token
    final token = await _tokenManager.getValidAccessToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔑 TokenInterceptor: Added auth token to ${options.path}');
      handler.next(options);
    } else {
      print('⚠️ TokenInterceptor: No valid token, skipping auth header for ${options.path}');
      handler.next(options);
    }
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
           path.contains('/auth/register') ||
           path.contains('/auth/refresh-token') ||
           path.contains('/auth/forgot-password');
  }
}